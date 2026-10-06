import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/router.dart';
import 'core/supabase_client.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_mode_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Chargé avant runApp : le mode de thème persistant est connu dès la
  // première frame, pas de scintillement clair → sombre au démarrage.
  final prefs = await SharedPreferences.getInstance();
  await initSupabase();
  runApp(MyApp(prefs: prefs));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key, required this.prefs});

  final SharedPreferences prefs;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final ThemeModeController _themeMode;

  @override
  void initState() {
    super.initState();
    _themeMode = ThemeModeController(widget.prefs);
  }

  @override
  void dispose() {
    _themeMode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      ThemeModeScope(notifier: _themeMode, child: const _AppView());
}

class _AppView extends StatelessWidget {
  const _AppView();

  @override
  Widget build(BuildContext context) {
    // AppTheme porte toute la charte visuelle (barre de navigation, boutons,
    // champs, dialogues). Sans lui, chaque écran tournait avec son propre
    // ThemeData et le travail de app_theme.dart n'était jamais visible.
    return MaterialApp.router(
      title: "Carnet d'adresses",
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      // Lu via la portée : ce build est dépendant du contrôleur, donc tout
      // changement de mode reconstruit MaterialApp et applique le thème.
      themeMode: ThemeModeScope.of(context),
      routerConfig: router,
    );
  }
}