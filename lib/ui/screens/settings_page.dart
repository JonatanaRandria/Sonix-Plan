import 'package:flutter/material.dart';
import 'package:sonix_plan/services/firebase_sync_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _syncService = FirebaseSyncService();
  bool _isLoading = false;
  int _cloudThemeCount = 0;

  @override
  void initState() {
    super.initState();
    print('⚙️ [SETTINGS] initState appelé');
    _loadCloudCount();
  }

  Future<void> _loadCloudCount() async {
    if (_syncService.isSignedIn) {
      final count = await _syncService.getCloudThemeCount();
      if (mounted) {
        setState(() => _cloudThemeCount = count);
      }
    }
  }

  Future<void> _handleSignIn() async {
    setState(() => _isLoading = true);
    
    try {
      // Utiliser l'authentification anonyme pour tester
      final success = await _syncService.signInAnonymously();
      
      if (!mounted) return;
      
      if (success) {
        await _loadCloudCount();
        _showSuccess("✅ Connecté avec succès !");
      } else {
        _showError("❌ Connexion échouée");
      }
    } catch (e) {
      print('❌ [SETTINGS] Erreur connexion: $e');
      if (!mounted) return;
      _showError("Erreur de connexion: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleSignOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Déconnexion"),
        content: const Text("Voulez-vous vous déconnecter ?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("ANNULER"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("DÉCONNEXION", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _syncService.signOut();
      if (mounted) {
        setState(() => _cloudThemeCount = 0);
        _showSuccess("Déconnecté");
      }
    }
  }

  Future<void> _handleUpload() async {
    setState(() => _isLoading = true);
    
    try {
      print('☁️ [SETTINGS] Upload vers cloud...');
      await _syncService.syncToCloud();
      await _loadCloudCount();
      
      if (!mounted) return;
      _showSuccess("✅ Thèmes envoyés vers le cloud !");
    } catch (e) {
      print('❌ [SETTINGS] Erreur upload: $e');
      if (!mounted) return;
      _showError("Erreur upload: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleDownload() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Télécharger depuis le cloud"),
        content: const Text(
          "⚠️ Cela remplacera vos thèmes locaux par ceux du cloud. Continuer ?"
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("ANNULER"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
            child: const Text("TÉLÉCHARGER"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    
    try {
      print('☁️ [SETTINGS] Download depuis cloud...');
      await _syncService.syncFromCloud();
      
      if (!mounted) return;
      _showSuccess("✅ Thèmes téléchargés depuis le cloud !");
    } catch (e) {
      print('❌ [SETTINGS] Erreur download: $e');
      if (!mounted) return;
      _showError("Erreur téléchargement: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleBidirectionalSync() async {
    setState(() => _isLoading = true);
    
    try {
      print('🔄 [SETTINGS] Synchronisation bidirectionnelle...');
      await _syncService.syncBidirectional();
      await _loadCloudCount();
      
      if (!mounted) return;
      _showSuccess("✅ Synchronisation terminée !");
    } catch (e) {
      print('❌ [SETTINGS] Erreur sync: $e');
      if (!mounted) return;
      _showError("Erreur synchronisation: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    print('🔨 [SETTINGS] build() appelé');
    final isSignedIn = _syncService.isSignedIn;

    return Scaffold(
      appBar: AppBar(
        title: const Text("PARAMÈTRES & CLOUD"),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Chargement...', style: TextStyle(fontSize: 16)),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Section Compte
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.account_circle, color: Colors.blue),
                            SizedBox(width: 8),
                            Text(
                              "COMPTE",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        if (isSignedIn) ...[
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const CircleAvatar(
                              backgroundColor: Colors.green,
                              child: Icon(Icons.check, color: Colors.white),
                            ),
                            title: Text(_syncService.userEmail ?? 'Connecté'),
                            subtitle: const Text("Compte Cloud actif"),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: _handleSignOut,
                            icon: const Icon(Icons.logout),
                            label: const Text("DÉCONNEXION"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(double.infinity, 50),
                            ),
                          ),
                        ] else ...[
                          const ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              backgroundColor: Colors.grey,
                              child: Icon(Icons.cloud_off, color: Colors.white),
                            ),
                            title: Text("Non connecté"),
                            subtitle: Text("Connectez-vous pour synchroniser vos données"),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: _handleSignIn,
                            icon: const Icon(Icons.cloud),
                            label: const Text("SE CONNECTER AU CLOUD"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(double.infinity, 50),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            "💡 Mode test : Authentification anonyme activée",
                            style: TextStyle(fontSize: 11, color: Colors.grey, fontStyle: FontStyle.italic),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                if (isSignedIn) ...[
                  const SizedBox(height: 16),

                  // Section Statistiques
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.analytics, color: Colors.orange),
                              SizedBox(width: 8),
                              Text(
                                "STATISTIQUES",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.cloud, color: Colors.blue, size: 32),
                            title: const Text("Thèmes dans le cloud"),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                "$_cloudThemeCount",
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Section Actions
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.sync, color: Colors.green),
                              SizedBox(width: 8),
                              Text(
                                "SYNCHRONISATION",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          
                          // Sync bidirectionnelle
                          ElevatedButton.icon(
                            onPressed: _handleBidirectionalSync,
                            icon: const Icon(Icons.sync),
                            label: const Text("SYNCHRONISER (RECOMMANDÉ)"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(double.infinity, 50),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              "Fusionne intelligemment vos thèmes locaux et cloud sans perte de données",
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ),

                          const SizedBox(height: 20),
                          const Divider(),
                          const SizedBox(height: 12),
                          
                          const Text(
                            "ACTIONS AVANCÉES",
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          const SizedBox(height: 12),

                          // Upload
                          ElevatedButton.icon(
                            onPressed: _handleUpload,
                            icon: const Icon(Icons.cloud_upload),
                            label: const Text("ENVOYER VERS LE CLOUD"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(double.infinity, 48),
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              "⚠️ Remplace les thèmes cloud par vos thèmes locaux",
                              style: TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Download
                          ElevatedButton.icon(
                            onPressed: _handleDownload,
                            icon: const Icon(Icons.cloud_download),
                            label: const Text("TÉLÉCHARGER DEPUIS LE CLOUD"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purple,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(double.infinity, 48),
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              "⚠️ Remplace vos thèmes locaux par ceux du cloud",
                              style: TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Section Info
                  Card(
                    color: Colors.blue.withOpacity(0.1),
                    child: const Padding(
                      padding: EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue, size: 20),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              "💡 Astuce : Utilisez la synchronisation pour garder vos thèmes à jour sur tous vos appareils",
                              style: TextStyle(fontSize: 12, color: Colors.blue),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}