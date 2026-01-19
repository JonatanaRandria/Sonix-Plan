import 'package:flutter/material.dart';
import 'package:sonix_plan/ui/screens/generator_page.dart';
import 'package:sonix_plan/ui/screens/history_page.dart';
import 'package:sonix_plan/ui/screens/statistics_dart.dart';
import 'package:sonix_plan/ui/screens/themes_manager_page.dart';
import 'package:sonix_plan/ui/screens/settings_page.dart';

class HomePage extends StatefulWidget {
  final VoidCallback onThemeToggle;

  const HomePage({super.key, required this.onThemeToggle});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 1; // Démarre sur "Générer"

  final List<Widget> _pages = [
    const HistoryPage(),
    const GeneratorPage(),
    const StatsPage(),
    const ThemesManagerPage(),
    const SettingsPage(), // NOUVELLE PAGE
  ];

  @override
  void initState() {
    super.initState();
    print('🏠 [HOME] initState appelé');
  }

  @override
  Widget build(BuildContext context) {
    print('🔨 [HOME] build() appelé, currentIndex=$_currentIndex');
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text("SONIX PLAN"),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: widget.onThemeToggle,
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
            tooltip: isDark ? 'Mode clair' : 'Mode sombre',
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          print('👆 [HOME] Navigation vers index $index');
          setState(() => _currentIndex = index);
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        selectedItemColor: isDark ? Colors.redAccent : Colors.red,
        unselectedItemColor: isDark ? Colors.grey[400] : Colors.grey[600],
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 11),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Historique',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.auto_awesome),
            label: 'Générer',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Stats',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.folder),
            label: 'Thèmes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Paramètres',
          ),
        ],
      ),
    );
  }
}