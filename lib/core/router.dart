import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'supabase_client.dart';
import '../features/auth/auth_screen.dart';
import '../features/home/home_screen.dart';
import '../features/address_create/address_form_screen.dart';
import '../features/address_create/step_wizard_screen.dart';
import '../features/address_detail/address_detail_screen.dart';
import '../features/search/search_screen.dart';
import '../features/favorites/favorites_screen.dart';
import '../features/share/redeem_share_screen.dart';
import '../models/address.dart';
import 'app_scaffold.dart';

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
  redirect: (context, state) {
    final loggedIn = supabase.auth.currentSession != null;
    final onLoginPage = state.matchedLocation == '/login';

    if (!loggedIn && !onLoginPage) return '/login';
    if (loggedIn && onLoginPage) return '/';
    return null;
  },
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const AuthScreen(),
    ),
    ShellRoute(
      builder: (context, state, child) => AppScaffold(child: child),
      // Trois onglets racine. « Ouvrir un lien » en fait partie : c'est un
      // écran de navigation atteint depuis l'accueil, pas une tâche à part
      // entière — l'utilisateur doit pouvoir changer d'onglet sans repasser
      // par l'accueil.
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: '/search',
          builder: (context, state) => const SearchScreen(),
        ),
        GoRoute(
          path: '/favorites',
          builder: (context, state) => const FavoritesScreen(),
        ),
        GoRoute(
          path: '/share/open',
          builder: (context, state) => const RedeemShareScreen(),
        ),
      ],
    ),
    GoRoute(
      path: '/address/create',
      builder: (context, state) => const AddressFormScreen(),
    ),
    GoRoute(
      path: '/address/:id/edit',
      builder: (context, state) => AddressFormScreen(
        existingAddress: state.extra as Address?,
      ),
    ),
    GoRoute(
      path: '/address/:id/steps',
      builder: (context, state) => StepWizardScreen(
        addressId: state.pathParameters['id']!,
        addressName: state.extra as String? ?? '',
      ),
    ),
    GoRoute(
      path: '/address/:id',
      builder: (context, state) => AddressDetailScreen(
        addressId: state.pathParameters['id']!,
      ),
    ),
  ],
);
