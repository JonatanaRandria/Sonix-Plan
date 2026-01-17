import 'package:flutter/material.dart';
import 'package:sonix_plan/ui/home_page.dart';
import 'package:sonix_plan/services/database_service.dart';

void main() async {
  print('🚀 Démarrage de l\'application...');
  
  // IMPORTANT : Nécessaire pour l'initialisation asynchrone
  WidgetsFlutterBinding.ensureInitialized();
  print('✅ Flutter binding initialisé');
  
  try {
    // Initialiser Hive AVANT de lancer l'app
    await DatabaseService.initialize();
    print('✅ Base de données initialisée');
    print('✅ ThemeBox: ${DatabaseService().themeBox.isOpen}');
    print('✅ PublicationBox: ${DatabaseService().publicationBox.isOpen}');
  } catch (e, stackTrace) {
    print('❌ ERREUR FATALE lors de l\'initialisation: $e');
    print('Stack trace: $stackTrace');
    // Afficher l'erreur à l'utilisateur
    runApp(MaterialApp(
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text('Erreur d\'initialisation de la base de données'),
              const SizedBox(height: 8),
              Text('$e', textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    ));
    return; // Ne pas lancer l'app si l'init échoue
  }
  
  print('🎯 Lancement de l\'app...');
  runApp(const SonixPlanApp());
}

class SonixPlanApp extends StatefulWidget {
  const SonixPlanApp({super.key});

  @override
  State<SonixPlanApp> createState() => _SonixPlanAppState();
}

class _SonixPlanAppState extends State<SonixPlanApp> {
  ThemeMode _themeMode = ThemeMode.dark; // Par défaut

  void toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    });
  }

  @override
  Widget build(BuildContext context) {
    print('📱 Building MaterialApp...');
    
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      // Thème Clair
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.red,
        scaffoldBackgroundColor: Colors.white,
        cardTheme: CardThemeData(color: Colors.grey[100]),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: Colors.red,
          unselectedItemColor: Colors.grey[600],
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
          type: BottomNavigationBarType.fixed,
        ),
      ),
      // Thème Sombre
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.redAccent[700],
        scaffoldBackgroundColor: const Color(0xFF0F0F0F),
        cardTheme: const CardThemeData(color: Color(0xFF1E1E1E)),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: const Color(0xFF1E1E1E),
          selectedItemColor: Colors.redAccent,
          unselectedItemColor: Colors.grey[400],
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
          type: BottomNavigationBarType.fixed,
        ),
      ),
      home: HomePage(onThemeToggle: toggleTheme),
    );
  }
}