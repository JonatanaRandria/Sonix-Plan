import 'package:flutter/material.dart';
import 'dart:math';
import 'package:url_launcher/url_launcher.dart';

class GeneratorPage extends StatelessWidget {
  const GeneratorPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Liste des créneaux horaires fixes
    final List<String> hours = ["06:00", "09:00", "12:00", "15:00", "18:00", "21:00"];
    final Random random = Random();

    return Scaffold(
      appBar: AppBar(title: const Text("GÉNÉRATEUR")),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: hours.length,
        itemBuilder: (context, index) {
          // Nombre de thèmes variable entre 5 et 6 par publication
          int themeCount = 5 + random.nextInt(2); 
          String currentSlot = hours[index];

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ExpansionTile(
              title: Text("Publication ${index + 1} ($currentSlot)"),
              subtitle: Text("$themeCount sujets à programmer"),
              children: List.generate(themeCount, (i) => 
                PublicationItem(
                  title: "VST THEME ${index * 6 + i}", 
                  url: "https://facebook.com",
                  slotTime: currentSlot, // On passe l'heure ici
                )
              ),
            ),
          );
        },
      ),
    );
  }
}

class PublicationItem extends StatefulWidget {
  final String title;
  final String url;
  final String slotTime; 

  const PublicationItem({
    super.key, 
    required this.title, 
    required this.url, 
    required this.slotTime
  });

  @override
  State<PublicationItem> createState() => _PublicationItemState(); // Correction ici
}

class _PublicationItemState extends State<PublicationItem> { // Correction ici
  bool _isFinished = false;

  bool _isWithinTimeWindow() {
    final now = DateTime.now();
    final parts = widget.slotTime.split(':');
    final startHour = int.parse(parts[0]);
    
    final startTime = DateTime(now.year, now.month, now.day, startHour, 0);
    // Fenêtre de 2h30 (ex: 06:00 à 08:30)
    final endTime = startTime.add(const Duration(hours: 2, minutes: 30));

    return now.isAfter(startTime) && now.isBefore(endTime);
  }

  Future<void> _handlePublish() async {
    if (!_isWithinTimeWindow()) {
      _showError("⚠️ Hors créneau ! Publication de ${widget.slotTime} autorisée jusqu'à ${widget.slotTime.split(':')[0]}:30");
      return;
    }

    final Uri uri = Uri.parse(widget.url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      
      // --- LOGIQUE ISAR (Sauvegarde Historique) ---
      // final isar = await IsarService().db;
      // final newPub = Publication()
      //   ..title = widget.title
      //   ..fbLink = widget.url
      //   ..slotTime = widget.slotTime
      //   ..datePublished = DateTime.now();
      // await isar.writeTxn(() => isar.publications.put(newPub));
      
      setState(() => _isFinished = true);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(widget.title, 
        style: TextStyle(decoration: _isFinished ? TextDecoration.lineThrough : null)),
      trailing: ElevatedButton(
        onPressed: _isFinished ? null : _handlePublish,
        style: ElevatedButton.styleFrom(
          backgroundColor: _isFinished ? Colors.green : Theme.of(context).primaryColor,
        ),
        child: Text(_isFinished ? "TERMINÉ" : "PUBLIER"),
      ),
    );
  }
}