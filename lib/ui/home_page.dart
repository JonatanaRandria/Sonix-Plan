import 'package:flutter/material.dart';
import 'package:sonix_plan/ui/screens/generator_page.dart';
import 'package:sonix_plan/ui/screens/history_page.dart';
import 'package:sonix_plan/ui/screens/statistics_dart.dart';
import 'package:sonix_plan/ui/screens/themes_manager_page.dart';


class HomePage extends StatefulWidget {
  final VoidCallback onThemeToggle; // On reçoit la fonction ici

  const HomePage({super.key, required this.onThemeToggle});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 1;

  final List<Widget> _pages = [
    const HistoryPage(),
    const GeneratorPage(),
    const StatsPage(),
    const ThemesManagerPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("SONIX PLAN"),
        actions: [
          // Bouton pour changer le thème
          IconButton(
            onPressed: widget.onThemeToggle, 
            icon: Icon(
              Theme.of(context).brightness == Brightness.dark 
                ? Icons.dark_mode 
                : Icons.light_mode
            ),
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Historique'),
          BottomNavigationBarItem(icon: Icon(Icons.auto_awesome), label: 'Générer'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Stats'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Thèmes'),
        ],
      ),
    );
  }
}