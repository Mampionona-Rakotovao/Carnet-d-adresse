import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'supabase_client.dart';
import '../features/auth/auth_screen.dart';
import '../features/home/home_screen.dart';

/// Transforme le flux d'évènements d'authentification de Supabase
/// (connexion, déconnexion...) en Listenable, ce que go_router attend
/// pour savoir quand ré-évaluer ses règles de redirection.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

final GoRouter router = GoRouter(
  initialLocation: '/',
  refreshListenable: GoRouterRefreshStream(supabase.auth.onAuthStateChange),

  // Règle centrale : si non connecté, on force l'écran /login.
  // Si connecté et qu'on est encore sur /login, on renvoie vers l'accueil.
  redirect: (context, state) {
    final loggedIn = supabase.auth.currentSession != null;
    final onLoginPage = state.matchedLocation == '/login';

    if (!loggedIn && !onLoginPage) return '/login';
    if (loggedIn && onLoginPage) return '/';
    return null; // pas de redirection nécessaire
  },

  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const AuthScreen(),
    ),
  ],
);