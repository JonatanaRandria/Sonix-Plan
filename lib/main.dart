import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:sonix_plan/services/history/auto_archive_service.dart';
import 'package:sonix_plan/ui/home_page.dart';
import 'package:sonix_plan/services/database_service.dart';
import 'package:sonix_plan/firebase_options.dart';

void main() async {
  print('🚀 [MAIN] Démarrage de l\'application...');
  
  WidgetsFlutterBinding.ensureInitialized();
  print('✅ [MAIN] Flutter binding initialisé');
  
  try {
    print('🔥 [MAIN] Initialisation Firebase...');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ [MAIN] Firebase initialisé avec succès');
    
    print('💾 [MAIN] Initialisation Hive...');
    await DatabaseService.initialize();
    print('✅ [MAIN] Hive initialisé avec succès');
    
    print('📦 [MAIN] Démarrage service d\'archivage...');
    AutoArchiveService().startAutoArchive();
    print('✅ [MAIN] Service d\'archivage démarré');
    
  } catch (e, stackTrace) {
    print('❌ [MAIN] ERREUR FATALE: $e');
    print('📍 [MAIN] Stack trace: $stackTrace');
    runApp(MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 80, color: Colors.red),
                const SizedBox(height: 20),
                const Text(
                  'Erreur d\'initialisation',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$e',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => main(),
                  child: const Text('RÉESSAYER'),
                )
              ],
            ),
          ),
        ),
      ),
    ));
    return;
  }
  
  print('🎯 [MAIN] Lancement de SonixPlanApp...');
  runApp(const SonixPlanApp());
  print('✅ [MAIN] runApp() appelé');
}

class SonixPlanApp extends StatefulWidget {
  const SonixPlanApp({super.key});

  @override
  State<SonixPlanApp> createState() {
    print('🏗️ [APP] Création de _SonixPlanAppState');
    return _SonixPlanAppState();
  }
}

class _SonixPlanAppState extends State<SonixPlanApp> {
  ThemeMode _themeMode = ThemeMode.dark;

  @override
  void initState() {
    super.initState();
    print('🎨 [APP] initState appelé');
  }

  void toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    });
  }

  @override
  Widget build(BuildContext context) {
    print('🔨 [APP] build() appelé');
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.red,
        scaffoldBackgroundColor: Colors.white,
        cardTheme: CardThemeData(color: Colors.grey[100]),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: Colors.red,
          unselectedItemColor: Colors.grey,
          type: BottomNavigationBarType.fixed,
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.redAccent[700],
        scaffoldBackgroundColor: const Color(0xFF0F0F0F),
        cardTheme: const CardThemeData(color: Color(0xFF1E1E1E)),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: const Color(0xFF1E1E1E),
          selectedItemColor: Colors.redAccent,
          unselectedItemColor: Colors.grey[400],
          type: BottomNavigationBarType.fixed,
        ),
      ),
      home: Builder(
        builder: (context) {
          print('🏠 [APP] Construction de HomePage...');
          return HomePage(onThemeToggle: toggleTheme);
        },
      ),
    );
  }
}