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
    print('🎨 [THEMES] initState appelé');
    _loadThemes();
    _searchController.addListener(_filterThemes);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadThemes() async {
    print('📂 [THEMES] Chargement des thèmes...');
    try {
      final themes = await DatabaseService().getAllThemes();
      if (!mounted) return;
      setState(() {
        _themes = themes;
        _filteredThemes = themes;
      });
      print('✅ [THEMES] ${themes.length} thèmes chargés');
    } catch (e) {
      print('❌ [THEMES] Erreur chargement: $e');
    }
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
    final partsController = TextEditingController(
      text: theme?.numberOfParts.toString() ?? '1'
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(theme == null ? 'Nouveau thème' : 'Modifier le thème'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Titre',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.title),
                ),
                autofocus: true,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: linkController,
                decoration: const InputDecoration(
                  labelText: 'Lien Facebook',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.link),
                ),
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: partsController,
                decoration: const InputDecoration(
                  labelText: 'Nombre de parties',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.numbers),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (titleController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Le titre est obligatoire'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }
              
              final parts = int.tryParse(partsController.text) ?? 1;
              
              if (theme != null) {
                // Modifier
                theme.title = titleController.text;
                theme.fbLink = linkController.text;
                theme.numberOfParts = parts;
                await theme.save();
              } else {
                // Ajouter
                final newTheme = ThemeItem(
                  title: titleController.text,
                  fbLink: linkController.text,
                  numberOfParts: parts,
                );
                await DatabaseService().saveTheme(newTheme);
              }
              
              _loadThemes();
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(ThemeItem theme) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Voulez-vous vraiment supprimer ce thème ?'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    theme.title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  if (theme.fbLink.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      theme.fbLink,
                      style: const TextStyle(fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await theme.delete();
              _loadThemes();
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Thème "${theme.title}" supprimé'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    print('🔨 [THEMES] build() appelé');
    
    return Scaffold(
      appBar: AppBar(
        title: const Text("MES THÈMES"),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Barre de recherche
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Rechercher un thème...",
                prefixIcon: const Icon(Icons.search, color: Colors.redAccent),
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none
                ),
              ),
            ),
          ),
          
          // Statistiques
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Row(
              children: [
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.folder, size: 20, color: Colors.blue),
                          const SizedBox(width: 8),
                          Text(
                            '${_themes.length} thème${_themes.length > 1 ? 's' : ''}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (_searchController.text.isNotEmpty)
                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.search, size: 20, color: Colors.orange),
                            const SizedBox(width: 8),
                            Text(
                              '${_filteredThemes.length} trouvé${_filteredThemes.length > 1 ? 's' : ''}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Liste des thèmes
          Expanded(
            child: _filteredThemes.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _themes.isEmpty ? Icons.folder_off : Icons.search_off,
                          size: 64,
                          color: Colors.grey[400]
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _themes.isEmpty 
                            ? 'Aucun thème enregistré' 
                            : 'Aucun résultat pour "${_searchController.text}"',
                          style: TextStyle(color: Colors.grey[600], fontSize: 16)
                        ),
                        const SizedBox(height: 8),
                        if (_themes.isEmpty)
                          const Text(
                            'Appuyez sur + pour créer votre premier thème',
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    itemCount: _filteredThemes.length,
                    itemBuilder: (context, index) {
                      final theme = _filteredThemes[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                        elevation: 2,
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.redAccent.withOpacity(0.2),
                            child: Text(
                              theme.title.isNotEmpty 
                                ? theme.title[0].toUpperCase() 
                                : '?',
                              style: const TextStyle(
                                color: Colors.redAccent,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            theme.title,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (theme.fbLink.isNotEmpty)
                                Text(
                                  theme.fbLink,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                ),
                              const SizedBox(height: 4),
                              Text(
                                '${theme.numberOfParts} partie${theme.numberOfParts > 1 ? 's' : ''}',
                                style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic),
                              ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                                onPressed: () => _showThemeForm(theme: theme),
                                tooltip: 'Modifier',
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                onPressed: () => _confirmDelete(theme),
                                tooltip: 'Supprimer',
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
        tooltip: 'Ajouter un thème',
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}