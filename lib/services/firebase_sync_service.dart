import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sonix_plan/services/database_service.dart';
import 'package:sonix_plan/ui/models/theme_item.dart';

class FirebaseSyncService {
  static final FirebaseSyncService _instance = FirebaseSyncService._internal();
  factory FirebaseSyncService() => _instance;
  FirebaseSyncService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  bool get isSignedIn => currentUser != null;
  String? get userEmail => currentUser?.email ?? currentUser?.uid;

  // CONNEXION ANONYME (pour tester sans Google)
  Future<bool> signInAnonymously() async {
    try {
      print('🔐 Connexion anonyme...');
      final userCredential = await _auth.signInAnonymously();
      print('✅ Connecté: ${userCredential.user?.uid}');
      return true;
    } catch (e) {
      print('❌ Erreur connexion anonyme: $e');
      return false;
    }
  }

  // Déconnexion
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      print('✅ Déconnecté');
    } catch (e) {
      print('❌ Erreur déconnexion: $e');
    }
  }

  // Upload vers le cloud
  Future<void> syncToCloud() async {
    if (!isSignedIn) {
      throw Exception('Non connecté');
    }

    try {
      print('☁️ Upload des thèmes vers le cloud...');
      
      final localThemes = await DatabaseService().getAllThemes();
      final batch = _firestore.batch();
      final userThemesRef = _firestore
          .collection('users')
          .doc(currentUser!.uid)
          .collection('themes');

      // Supprimer anciens thèmes cloud
      final existingDocs = await userThemesRef.get();
      for (var doc in existingDocs.docs) {
        batch.delete(doc.reference);
      }

      // Ajouter nouveaux thèmes
      for (var theme in localThemes) {
        final docRef = userThemesRef.doc();
        batch.set(docRef, {
          'title': theme.title,
          'fbLink': theme.fbLink,
          'numberOfParts': theme.numberOfParts,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
      print('✅ ${localThemes.length} thème(s) uploadé(s)');
    } catch (e) {
      print('❌ Erreur upload: $e');
      rethrow;
    }
  }

  // Download depuis le cloud
  Future<void> syncFromCloud() async {
    if (!isSignedIn) {
      throw Exception('Non connecté');
    }

    try {
      print('☁️ Téléchargement des thèmes depuis le cloud...');
      
      final userThemesRef = _firestore
          .collection('users')
          .doc(currentUser!.uid)
          .collection('themes');

      final snapshot = await userThemesRef.get();
      
      if (snapshot.docs.isEmpty) {
        print('📭 Aucun thème dans le cloud');
        return;
      }

      // Vider thèmes locaux
      await DatabaseService().clearAllThemes();

      // Ajouter thèmes du cloud
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final theme = ThemeItem(
          title: data['title'] ?? '',
          fbLink: data['fbLink'] ?? '',
          numberOfParts: data['numberOfParts'] ?? 1,
        );
        await DatabaseService().saveTheme(theme);
      }

      print('✅ ${snapshot.docs.length} thème(s) téléchargé(s)');
    } catch (e) {
      print('❌ Erreur téléchargement: $e');
      rethrow;
    }
  }

  // Synchronisation bidirectionnelle (merge)
  Future<void> syncBidirectional() async {
    if (!isSignedIn) {
      // Connexion automatique anonyme si pas connecté
      final success = await signInAnonymously();
      if (!success) {
        throw Exception('Impossible de se connecter');
      }
    }

    try {
      print('🔄 Synchronisation bidirectionnelle...');
      
      final localThemes = await DatabaseService().getAllThemes();
      final userThemesRef = _firestore
          .collection('users')
          .doc(currentUser!.uid)
          .collection('themes');

      final cloudSnapshot = await userThemesRef.get();
      
      // Map pour éviter doublons (par titre)
      Map<String, ThemeItem> mergedThemes = {};

      // Ajouter thèmes locaux
      for (var theme in localThemes) {
        mergedThemes[theme.title] = theme;
      }

      // Fusionner avec thèmes cloud
      for (var doc in cloudSnapshot.docs) {
        final data = doc.data();
        final title = data['title'] ?? '';
        if (!mergedThemes.containsKey(title)) {
          mergedThemes[title] = ThemeItem(
            title: title,
            fbLink: data['fbLink'] ?? '',
            numberOfParts: data['numberOfParts'] ?? 1,
          );
        }
      }

      // Vider local et cloud
      await DatabaseService().clearAllThemes();
      final batch = _firestore.batch();
      for (var doc in cloudSnapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      // Sauvegarder thèmes fusionnés
      for (var theme in mergedThemes.values) {
        // Local
        await DatabaseService().saveTheme(theme);
        
        // Cloud
        final docRef = userThemesRef.doc();
        await docRef.set({
          'title': theme.title,
          'fbLink': theme.fbLink,
          'numberOfParts': theme.numberOfParts,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      print('✅ ${mergedThemes.length} thème(s) synchronisé(s)');
    } catch (e) {
      print('❌ Erreur synchronisation: $e');
      rethrow;
    }
  }

  // Nombre de thèmes dans le cloud
  Future<int> getCloudThemeCount() async {
    if (!isSignedIn) return 0;

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(currentUser!.uid)
          .collection('themes')
          .get();
      
      return snapshot.docs.length;
    } catch (e) {
      print('❌ Erreur comptage cloud: $e');
      return 0;
    }
  }

  Future<bool> hasCloudThemes() async {
    return (await getCloudThemeCount()) > 0;
  }
}