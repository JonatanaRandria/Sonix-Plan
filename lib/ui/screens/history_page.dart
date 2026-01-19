import 'package:flutter/material.dart';
import 'package:sonix_plan/services/database_service.dart';
import 'package:sonix_plan/ui/models/publications.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List<Publication> _publications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    try {
      final history = await DatabaseService().getHistory();
      if (!mounted) return;
      setState(() {
        _publications = history;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showError("Erreur lors du chargement: $e");
    }
  }

  Future<void> _deletePublication(Publication pub) async {
    try {
      await DatabaseService().deletePublicationByKey(pub.key);
      _loadHistory();
      _showSuccess("Publication supprimée");
    } catch (e) {
      _showError("Erreur lors de la suppression: $e");
    }
  }

  void _confirmDelete(Publication pub) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Supprimer ?"),
        content: Text("Voulez-vous supprimer '${pub.title}' ?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("ANNULER")
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _deletePublication(pub);
            },
            child: const Text("SUPPRIMER", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _openLink(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      _showError("Impossible d'ouvrir le lien");
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

  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy à HH:mm').format(date);
  }

  // Grouper par date
  Map<String, List<Publication>> _groupByDate() {
    final Map<String, List<Publication>> grouped = {};
    
    for (var pub in _publications) {
      final dateKey = DateFormat('dd/MM/yyyy').format(pub.datePublished);
      if (!grouped.containsKey(dateKey)) {
        grouped[dateKey] = [];
      }
      grouped[dateKey]!.add(pub);
    }
    
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_publications.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("HISTORIQUE"),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadHistory,
            ),
          ],
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.history, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'Aucune publication dans l\'historique',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    final groupedPubs = _groupByDate();
    final dates = groupedPubs.keys.toList();

    return Scaffold(
      appBar: AppBar(
        title: Text("HISTORIQUE (${_publications.length})"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadHistory,
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: dates.length,
        itemBuilder: (context, index) {
          final date = dates[index];
          final pubs = groupedPubs[date]!;
          
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ExpansionTile(
              title: Text(
                date,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text("${pubs.length} publication(s)"),
              children: pubs.map((pub) => ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.redAccent,
                  child: Text(
                    pub.slotTime.split(':')[0],
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
                title: Text(pub.title),
                subtitle: Text(
                  "Créneau: ${pub.slotTime} • ${_formatDate(pub.datePublished)}",
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.open_in_new, color: Colors.blue),
                      onPressed: () => _openLink(pub.fbLink),
                      tooltip: "Ouvrir le lien",
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _confirmDelete(pub),
                      tooltip: "Supprimer",
                    ),
                  ],
                ),
              )).toList(),
            ),
          );
        },
      ),
    );
  }
}