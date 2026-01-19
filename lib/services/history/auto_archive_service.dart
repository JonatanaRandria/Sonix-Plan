import 'dart:async';
import 'package:sonix_plan/services/database_service.dart';
import 'package:sonix_plan/ui/models/publications.dart';

class AutoArchiveService {
  static final AutoArchiveService _instance = AutoArchiveService._internal();
  factory AutoArchiveService() => _instance;
  AutoArchiveService._internal();

  Timer? _timer;
  final List<PendingPublication> _pendingPublications = [];

  // Stocker les publications générées en attente d'archivage
  void addPendingPublications(List<PendingPublication> publications) {
    _pendingPublications.addAll(publications);
    print('📋 ${publications.length} publication(s) ajoutée(s) en attente d\'archivage');
    print('📊 Total en attente: ${_pendingPublications.length}');
  }

  // Marquer une publication comme terminée
  void markAsCompleted(String slotTime, String title) {
    final pub = _pendingPublications.firstWhere(
      (p) => p.slotTime == slotTime && p.title == title,
      orElse: () => PendingPublication(title: '', fbLink: '', slotTime: '', isCompleted: false),
    );
    
    if (pub.title.isNotEmpty) {
      pub.isCompleted = true;
      print('✅ Publication marquée comme terminée: $title (${pub.slotTime})');
      print('📊 Publications terminées: ${_pendingPublications.where((p) => p.isCompleted).length}/${_pendingPublications.length}');
    }
  }

  // Marquer une publication comme non terminée (pour le bouton REFAIRE)
  void markAsIncomplete(String slotTime, String title) {
    final pub = _pendingPublications.firstWhere(
      (p) => p.slotTime == slotTime && p.title == title,
      orElse: () => PendingPublication(title: '', fbLink: '', slotTime: '', isCompleted: false),
    );
    
    if (pub.title.isNotEmpty) {
      pub.isCompleted = false;
      print('🔄 Publication marquée comme non terminée: $title (${pub.slotTime})');
    }
  }

  // Démarrer le timer d'archivage automatique
  void startAutoArchive() {
    // Annuler le timer précédent s'il existe
    _timer?.cancel();

    // Calculer le temps jusqu'à 23:59
    final now = DateTime.now();
    final targetTime = DateTime(now.year, now.month, now.day, 23, 59, 0);
    
    Duration delay;
    if (now.isBefore(targetTime)) {
      // Si on est avant 23:59 aujourd'hui
      delay = targetTime.difference(now);
    } else {
      // Si on est après 23:59, programmer pour demain
      final tomorrow = targetTime.add(const Duration(days: 1));
      delay = tomorrow.difference(now);
    }

    print('⏰ Archivage automatique programmé dans ${delay.inHours}h ${delay.inMinutes % 60}min');

    // Créer un timer qui se déclenche à 23:59
    _timer = Timer(delay, () async {
      await _archivePublications();
      // Re-programmer pour le lendemain
      startAutoArchive();
    });
  }

  // Archiver uniquement les publications terminées
  Future<void> _archivePublications() async {
    final completedPubs = _pendingPublications.where((p) => p.isCompleted).toList();
    
    if (completedPubs.isEmpty) {
      print('📭 Aucune publication terminée à archiver');
      return;
    }

    try {
      print('📦 Archivage de ${completedPubs.length} publication(s) terminée(s)...');
      
      for (var pending in completedPubs) {
        final publication = Publication(
          title: pending.title,
          fbLink: pending.fbLink,
          slotTime: pending.slotTime,
          datePublished: DateTime.now(),
        );
        
        await DatabaseService().savePublication(publication);
      }

      print('✅ ${completedPubs.length} publication(s) archivée(s) avec succès');
      
      // Retirer uniquement les publications archivées
      _pendingPublications.removeWhere((p) => p.isCompleted);
      
      print('📊 Publications restantes en attente: ${_pendingPublications.length}');
    } catch (e) {
      print('❌ Erreur lors de l\'archivage: $e');
    }
  }

  // Forcer l'archivage manuellement (pour les tests)
  Future<void> forceArchive() async {
    print('🔧 Archivage manuel forcé');
    await _archivePublications();
  }

  // Obtenir le nombre de publications en attente
  int get pendingCount => _pendingPublications.length;
  
  // Obtenir le nombre de publications terminées
  int get completedCount => _pendingPublications.where((p) => p.isCompleted).length;

  // Vider les publications en attente
  void clearPending() {
    _pendingPublications.clear();
    print('🗑️ Publications en attente effacées');
  }

  // Arrêter le service
  void stop() {
    _timer?.cancel();
    _timer = null;
    print('⏹️ Service d\'archivage arrêté');
  }
}

// Modèle pour une publication en attente d'archivage
class PendingPublication {
  final String title;
  final String fbLink;
  final String slotTime;
  bool isCompleted;

  PendingPublication({
    required this.title,
    required this.fbLink,
    required this.slotTime,
    this.isCompleted = false,
  });
}