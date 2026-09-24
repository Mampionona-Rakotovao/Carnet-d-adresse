import 'package:flutter/material.dart';
import 'core/supabase_client.dart';
import 'features/auth/auth_test_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initSupabase();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Carnet d'adresses",
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.teal,
        useMaterial3: true,
      ),
      // Temporaire : écran de test pour valider la connexion Supabase.
      // Sera remplacé par le routeur (go_router) une fois l'auth validée.
      home: const AuthTestScreen(),
    );
  }
}