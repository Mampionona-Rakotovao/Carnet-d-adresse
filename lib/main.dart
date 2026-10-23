import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/router.dart';
import 'core/supabase_client.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_mode_controller.dart';

/// Schéma d'URL déclaré côté Android (voir AndroidManifest.xml) et utilisé
/// comme `redirectTo` pour la réinitialisation de mot de passe.
const _mobileScheme = 'carnetadresses';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Le lien de réinitialisation reçu par email ouvre l'app sur
  // /reset-password. Sur le web, Supabase consomme le code pendant
  // initialize() et émet l'événement passwordRecovery avant que le routeur
  // ne s'y abonne : on mémorise donc l'intention dès maintenant.
  if (kIsWeb && Uri.base.path == '/reset-password') {
    markPasswordRecovery();
  }

  // Chargé avant runApp : le mode de thème persistant est connu dès la
  // première frame, pas de scintillement clair → sombre au démarrage.
  final prefs = await SharedPreferences.getInstance();
  await initSupabase();

  // Session enregistrée sur le téléphone mais expirée ou invalide (par
  // exemple après la suppression du compte côté Supabase) : on tente de la
  // renouveler, sinon on déconnecte pour arriver proprement sur le login.
  final session = supabase.auth.currentSession;
  if (session != null && session.isExpired) {
    try {
      await supabase.auth.refreshSession();
    } catch (_) {
      await supabase.auth.signOut();
    }
  }

  // Sur mobile, le lien arrive sous forme de deep link. On le lit nous-mêmes,
  // car l'événement passwordRecovery de Supabase est émis pendant
  // initialize(), donc avant que le routeur ne s'y abonne.
  if (!kIsWeb) {
    final appLinks = AppLinks();
    final initialLink = await appLinks.getInitialLink();
    if (_isPasswordResetLink(initialLink)) markPasswordRecovery();

    // App déjà lancée : le lien est reçu à chaud.
    appLinks.uriLinkStream.listen((uri) {
      if (_isPasswordResetLink(uri)) {
        markPasswordRecovery();
        router.refresh();
      }
    });
  }

  runApp(MyApp(prefs: prefs));
}

/// Vrai si le lien correspond à la réinitialisation de mot de passe.
bool _isPasswordResetLink(Uri? uri) {
  if (uri == null) return false;
  return uri.scheme == _mobileScheme &&
      (uri.host == 'reset-password' || uri.path.contains('reset-password'));
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