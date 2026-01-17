import 'package:flutter/material.dart';
import 'package:sonix_plan/services/database_service.dart';
import 'package:sonix_plan/ui/models/theme_item.dart';

class ThemesManagerPage extends StatefulWidget {
  const ThemesManagerPage({super.key});

  @override
  State<ThemesManagerPage> createState() => _ThemesManagerPageState();
}

class _ThemesManagerPageState extends State<ThemesManagerPage> {
  List<ThemeItem> _themes = [];
  List<ThemeItem> _filteredThemes = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadThemes();
    _searchController.addListener(_filterThemes);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadThemes() async {
    final themes = await DatabaseService().getAllThemes();
    if (!mounted) return;
    setState(() {
      _themes = themes;
      _filteredThemes = themes;
    });
  }

  void _filterThemes() {
    setState(() {
      _filteredThemes = _themes
          .where((t) => t.title.toLowerCase().contains(_searchController.text.toLowerCase()))
          .toList();
    });
  }

  void _showThemeForm({ThemeItem? theme}) {
    final titleController = TextEditingController(text: theme?.title ?? '');
    final linkController = TextEditingController(text: theme?.fbLink ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardTheme.color,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))
      ),
      builder: (modalContext) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(modalContext).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 20
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              theme == null ? "AJOUTER UN THÈME" : "MODIFIER LE THÈME",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.redAccent
              )
            ),
            const SizedBox(height: 15),
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: "Titre")
            ),
            TextField(
              controller: linkController,
              decoration: const InputDecoration(labelText: "Lien Facebook")
            ),
            const SizedBox(height: 25),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent[700],
                minimumSize: const Size(double.infinity, 50)
              ),
              onPressed: () async {
                // Validation
                if (titleController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Le titre est requis'))
                  );
                  return;
                }

                try {
                  if (theme != null) {
                    // MODIFICATION d'un thème existant
                    theme.title = titleController.text.trim();
                    theme.fbLink = linkController.text.trim();
                    await DatabaseService().saveTheme(theme);
                  } else {
                    // CRÉATION d'un nouveau thème
                    final newTheme = ThemeItem()
                      ..title = titleController.text.trim()
                      ..fbLink = linkController.text.trim();
                    await DatabaseService().saveTheme(newTheme);
                  }

                  // Recharger les thèmes
                  if (!mounted) return;
                  _loadThemes();

                  // Fermer le modal
                  if (modalContext.mounted) {
                    Navigator.of(modalContext).pop();
                  }

                  // Afficher un message de succès
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(theme == null 
                          ? 'Thème ajouté avec succès' 
                          : 'Thème modifié avec succès'
                        ),
                        backgroundColor: Colors.green,
                      )
                    );
                  }
                } catch (e) {
                  // Gestion des erreurs
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Erreur: $e'),
                        backgroundColor: Colors.red,
                      )
                    );
                  }
                }
              },
              child: const Text(
                "ENREGISTRER",
                style: TextStyle(color: Colors.white)
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(ThemeItem theme) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Supprimer ?"),
        content: Text("Voulez-vous supprimer '${theme.title}' ?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("ANNULER")
          ),
          TextButton(
            onPressed: () async {
              try {
                // Utiliser la clé Hive pour supprimer
                await DatabaseService().deleteThemeByKey(theme.key);

                if (!mounted) return;
                _loadThemes();

                // Fermeture sécurisée
                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop();
                }

                // Message de succès
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Thème supprimé avec succès'),
                      backgroundColor: Colors.green,
                    )
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erreur lors de la suppression: $e'),
                      backgroundColor: Colors.red,
                    )
                  );
                }
              }
            },
            child: const Text("SUPPRIMER", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("GESTION DES THÈMES")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Rechercher...",
                prefixIcon: const Icon(Icons.search, color: Colors.redAccent),
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none
                ),
              ),
            ),
          ),
          Expanded(
            child: _filteredThemes.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.info_outline, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          _themes.isEmpty 
                            ? 'Aucun thème enregistré' 
                            : 'Aucun résultat',
                          style: TextStyle(color: Colors.grey[600])
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _filteredThemes.length,
                    itemBuilder: (context, index) {
                      final theme = _filteredThemes[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        child: ListTile(
                          title: Text(
                            theme.title,
                            style: const TextStyle(fontWeight: FontWeight.bold)
                          ),
                          subtitle: Text(
                            theme.fbLink,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () => _showThemeForm(theme: theme)
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _confirmDelete(theme)
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.redAccent[700],
        onPressed: () => _showThemeForm(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}