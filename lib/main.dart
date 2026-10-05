import 'package:flutter/material.dart';
import 'core/router.dart';
import 'core/supabase_client.dart';
import 'core/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initSupabase();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: "Carnet d'adresses",
      debugShowCheckedModeBanner: false,
      // AppTheme porte toute la charte visuelle (barre de navigation, boutons,
      // champs, dialogues). Sans lui, chaque écran tournait avec son propre
      // ThemeData et le travail de app_theme.dart n'était jamais visible.
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}
