import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:sonix_plan/services/database_service.dart';
import 'package:sonix_plan/ui/models/theme_item.dart';
import 'package:sonix_plan/ui/models/publications.dart';

class GeneratorPage extends StatefulWidget {
  const GeneratorPage({super.key});

  @override
  State<GeneratorPage> createState() => _GeneratorPageState();
}

class _GeneratorPageState extends State<GeneratorPage> {
  List<TimeSlotPublication> _timeSlots = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _generatePublications() async {
    setState(() => _isLoading = true);

    try {
      // Récupérer tous les thèmes
      final allThemes = await DatabaseService().getAllThemes();
      
      // Créneaux horaires fixes (toujours affichés)
      final List<String> hours = ["06:00", "09:00", "12:00", "15:00", "18:00", "21:00"];
      
      // Liste pour stocker les publications générées
      List<TimeSlotPublication> newSlots = [];
      
      if (allThemes.isEmpty) {
        // Créer les créneaux vides
        for (String hour in hours) {
          newSlots.add(TimeSlotPublication(hour: hour, themes: []));
        }
        
        setState(() {
          _timeSlots = newSlots;
          _isLoading = false;
        });
        
        _showError("Aucun thème disponible. Ajoutez des thèmes d'abord !");
        return;
      }
      
      // Calculer le total de publications à distribuer
      int totalPublications = allThemes.fold(0, (sum, theme) => sum + theme.numberOfParts);
      
      // Pool de thèmes avec leurs parties restantes
      List<ThemeWithParts> themePool = allThemes.map((theme) => 
        ThemeWithParts(theme: theme, partsRemaining: theme.numberOfParts)
      ).toList();
      
      // Distribution équitable : calculer combien de publications par créneau
      int publicationsPerSlot = (totalPublications / hours.length).ceil();
      int currentSlotIndex = 0;
      
      // Générer pour chaque créneau
      for (String hour in hours) {
        List<PublicationTheme> slotThemes = [];
        int publicationsInThisSlot = 0;
        
        // Remplir ce créneau jusqu'à la limite ou épuisement des thèmes
        while (publicationsInThisSlot < publicationsPerSlot && themePool.isNotEmpty) {
          // Trouver un thème qui a encore des parties
          ThemeWithParts? selectedTheme;
          for (var theme in themePool) {
            if (theme.partsRemaining > 0) {
              selectedTheme = theme;
              break;
            }
          }
          
          if (selectedTheme == null) break;
          
          // Déterminer combien de parties pour cette publication
          int partsForThisSlot;
          
          if (selectedTheme.partsRemaining >= 4) {
            // Si 4+ parties restantes, diviser intelligemment
            // Prendre au minimum 2 parties
            int remaining = selectedTheme.partsRemaining;
            int slotsLeft = hours.length - currentSlotIndex;
            int idealParts = (remaining / slotsLeft).ceil().clamp(2, 4);
            partsForThisSlot = idealParts;
          } else {
            // Sinon prendre tout ce qui reste
            partsForThisSlot = selectedTheme.partsRemaining;
          }
          
          // Ajouter à la publication
          slotThemes.add(PublicationTheme(
            theme: selectedTheme.theme,
            partsInThisPublication: partsForThisSlot,
          ));
          
          // Décrémenter les parties restantes
          selectedTheme.partsRemaining -= partsForThisSlot;
          publicationsInThisSlot += partsForThisSlot;
          
          // Si le thème est épuisé, le retirer du pool
          if (selectedTheme.partsRemaining <= 0) {
            themePool.remove(selectedTheme);
          }
        }
        
        // Créer le créneau (même s'il est vide)
        newSlots.add(TimeSlotPublication(
          hour: hour,
          themes: slotThemes,
        ));
        
        currentSlotIndex++;
      }
      
      setState(() {
        _timeSlots = newSlots;
        _isLoading = false;
      });
      
      final totalThemes = newSlots.fold(0, (sum, slot) => sum + slot.themes.length);
      _showSuccess("6 créneaux générés avec $totalThemes thème(s) au total");
      
    } catch (e) {
      _showError("Erreur lors de la génération: $e");
      setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("GÉNÉRATEUR")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _timeSlots.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.auto_awesome, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'Cliquez sur Générer pour créer les publications',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _timeSlots.length,
                  itemBuilder: (context, index) {
                    final slot = _timeSlots[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ExpansionTile(
                        title: Text("Publication ${index + 1} (${slot.hour})"),
                        subtitle: Text(
                          slot.themes.isEmpty 
                            ? "Aucun thème disponible"
                            : "${slot.themes.length} thème(s) à publier"
                        ),
                        children: slot.themes.isEmpty
                            ? [
                                Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    children: [
                                      Icon(Icons.info_outline, 
                                        size: 48, 
                                        color: Colors.grey[400]
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        "Aucun thème disponible pour ce créneau",
                                        style: TextStyle(color: Colors.grey[600]),
                                      ),
                                    ],
                                  ),
                                ),
                              ]
                            : slot.themes.map((pubTheme) => 
                                PublicationItem(
                                  theme: pubTheme,
                                  slotTime: slot.hour,
                                  onStatusChanged: () => setState(() {}),
                                )
                              ).toList(),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isLoading ? null : _generatePublications,
        backgroundColor: Colors.redAccent[700],
        icon: const Icon(Icons.auto_awesome, color: Colors.white),
        label: const Text("GÉNÉRER", style: TextStyle(color: Colors.white)),
      ),
    );
  }
}

// Modèle pour un créneau horaire avec ses thèmes
class TimeSlotPublication {
  final String hour;
  final List<PublicationTheme> themes;
  
  TimeSlotPublication({required this.hour, required this.themes});
}

// Modèle pour un thème dans une publication
class PublicationTheme {
  final ThemeItem theme;
  final int partsInThisPublication;
  
  PublicationTheme({
    required this.theme,
    required this.partsInThisPublication,
  });
}

// Helper pour tracker les parties restantes
class ThemeWithParts {
  final ThemeItem theme;
  int partsRemaining;
  
  ThemeWithParts({required this.theme, required this.partsRemaining});
}

// Widget pour chaque item de publication
class PublicationItem extends StatefulWidget {
  final PublicationTheme theme;
  final String slotTime;
  final VoidCallback onStatusChanged;

  const PublicationItem({
    super.key,
    required this.theme,
    required this.slotTime,
    required this.onStatusChanged,
  });

  @override
  State<PublicationItem> createState() => _PublicationItemState();
}

class _PublicationItemState extends State<PublicationItem> {
  bool _isFinished = false;

  bool _isWithinTimeWindow() {
    final now = DateTime.now();
    final parts = widget.slotTime.split(':');
    final startHour = int.parse(parts[0]);
    
    final startTime = DateTime(now.year, now.month, now.day, startHour, 0);
    final endTime = startTime.add(const Duration(hours: 2, minutes: 30));

    return now.isAfter(startTime) && now.isBefore(endTime);
  }

  Future<void> _handlePublish() async {
    if (!_isWithinTimeWindow()) {
      final parts = widget.slotTime.split(':');
      final hour = int.parse(parts[0]);
      final endHour = (hour + 2).toString().padLeft(2, '0');
      _showError("⚠️ Hors créneau ! Publication de ${widget.slotTime} autorisée jusqu'à $endHour:30");
      return;
    }

    final Uri uri = Uri.parse(widget.theme.theme.fbLink);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      
      // Sauvegarder dans l'historique
      final newPub = Publication(
        title: "${widget.theme.theme.title} (${widget.theme.partsInThisPublication} partie${widget.theme.partsInThisPublication > 1 ? 's' : ''})",
        fbLink: widget.theme.theme.fbLink,
        slotTime: widget.slotTime,
        datePublished: DateTime.now(),
      );
      await DatabaseService().savePublication(newPub);
      
      setState(() => _isFinished = true);
      widget.onStatusChanged();
    }
  }

  void _handleReset() {
    setState(() => _isFinished = false);
    widget.onStatusChanged();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayTitle = widget.theme.partsInThisPublication > 1
        ? "${widget.theme.theme.title} (${widget.theme.partsInThisPublication} parties)"
        : widget.theme.theme.title;

    return ListTile(
      title: Text(
        displayTitle,
        style: TextStyle(
          decoration: _isFinished ? TextDecoration.lineThrough : null,
          color: _isFinished ? Colors.grey : null,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isFinished) ...[
            ElevatedButton(
              onPressed: _handleReset,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
              ),
              child: const Text("REFAIRE", style: TextStyle(color: Colors.white)),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                disabledBackgroundColor: Colors.green,
              ),
              child: const Text("TERMINÉ", style: TextStyle(color: Colors.white)),
            ),
          ] else ...[
            ElevatedButton(
              onPressed: _handlePublish,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
              ),
              child: const Text("PUBLIER", style: TextStyle(color: Colors.white)),
            ),
          ],
        ],
      ),
    );
  }
}