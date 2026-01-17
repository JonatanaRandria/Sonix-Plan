import 'package:hive_flutter/hive_flutter.dart';
import 'package:sonix_plan/ui/models/publications.dart';
import 'package:sonix_plan/ui/models/theme_item.dart';

class DatabaseService {
  // Instance unique (Singleton)
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static late Box<ThemeItem> _themeBox;
  static late Box<Publication> _publicationBox;

  // Accesseurs pour récupérer les boxes n'importe où
  Box<ThemeItem> get themeBox => _themeBox;
  Box<Publication> get publicationBox => _publicationBox;

  // INITIALISATION (Appelée une seule fois dans le main.dart)
  static Future<void> initialize() async {
    try {
      print('📦 Initialisation de Hive...');
      
      // Initialiser Hive (compatible Web automatiquement)
      await Hive.initFlutter();
      print('✅ Hive.initFlutter() terminé');
      
      // Enregistrer les adaptateurs AVANT d'ouvrir les boxes
      if (!Hive.isAdapterRegistered(0)) {
        print('📝 Enregistrement de ThemeItemAdapter (typeId: 0)');
        Hive.registerAdapter(ThemeItemAdapter());
      } else {
        print('⚠️ ThemeItemAdapter déjà enregistré');
      }
      
      if (!Hive.isAdapterRegistered(1)) {
        print('📝 Enregistrement de PublicationAdapter (typeId: 1)');
        Hive.registerAdapter(PublicationAdapter());
      } else {
        print('⚠️ PublicationAdapter déjà enregistré');
      }
      
      // Ouvrir les boxes
      print('📂 Ouverture de la box themeItems...');
      _themeBox = await Hive.openBox<ThemeItem>('themeItems');
      print('✅ themeItems box ouverte (${_themeBox.length} éléments)');
      
      print('📂 Ouverture de la box publications...');
      _publicationBox = await Hive.openBox<Publication>('publications');
      print('✅ publications box ouverte (${_publicationBox.length} éléments)');
      
      print('🎉 DatabaseService initialisé avec succès!');
    } catch (e, stackTrace) {
      print('❌ ERREUR dans DatabaseService.initialize(): $e');
      print('Stack trace: $stackTrace');
      rethrow; // Relancer l'erreur pour qu'elle soit capturée dans main()
    }
  }

  // --- MÉTHODES POUR LES THÈMES ---

  Future<void> saveTheme(ThemeItem theme) async {
    if (theme.isInBox) {
      // Mise à jour d'un élément existant
      await theme.save();
    } else {
      // Nouvel élément
      await _themeBox.add(theme);
    }
  }

  Future<List<ThemeItem>> getAllThemes() async {
    return _themeBox.values.toList();
  }

  Future<void> deleteTheme(int index) async {
    await _themeBox.deleteAt(index);
  }

  Future<void> deleteThemeByKey(dynamic key) async {
    await _themeBox.delete(key);
  }

  ThemeItem? getThemeAt(int index) {
    return _themeBox.getAt(index);
  }

  // --- MÉTHODES POUR L'HISTORIQUE ---

  Future<void> savePublication(Publication pub) async {
    if (pub.isInBox) {
      // Mise à jour d'un élément existant
      await pub.save();
    } else {
      // Nouvel élément
      await _publicationBox.add(pub);
    }
  }

  Future<List<Publication>> getHistory() async {
    // Récupérer toutes les publications et les trier par date décroissante
    final publications = _publicationBox.values.toList();
    publications.sort((a, b) => b.datePublished.compareTo(a.datePublished));
    return publications;
  }

  Future<void> deletePublication(int index) async {
    await _publicationBox.deleteAt(index);
  }

  Future<void> deletePublicationByKey(dynamic key) async {
    await _publicationBox.delete(key);
  }

  Publication? getPublicationAt(int index) {
    return _publicationBox.getAt(index);
  }

  // --- MÉTHODES UTILITAIRES ---

  Future<void> clearAllThemes() async {
    await _themeBox.clear();
  }

  Future<void> clearAllPublications() async {
    await _publicationBox.clear();
  }

  Future<void> close() async {
    await _themeBox.close();
    await _publicationBox.close();
  }
}