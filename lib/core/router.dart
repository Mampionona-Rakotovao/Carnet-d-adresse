import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_client.dart';
import '../features/auth/auth_screen.dart';
import '../features/auth/confirm_email_screen.dart';
import '../features/auth/reset_code_screen.dart';
import '../features/auth/reset_password_screen.dart';
import '../features/home/home_screen.dart';
import '../features/address_create/address_form_screen.dart';
import '../features/address_create/step_wizard_screen.dart';
import '../features/address_detail/address_detail_screen.dart';
import '../features/search/search_screen.dart';
import '../features/favorites/favorites_screen.dart';
import '../features/share/redeem_share_screen.dart';
import '../features/share/shared_with_me_screen.dart';
import '../features/share/shared_link_screen.dart';
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

/// Devient true quand Supabase détecte que l'utilisateur vient de cliquer
/// le lien de récupération de mot de passe reçu par email. Force alors
/// le passage par /reset-password avant toute autre navigation.
bool _isPasswordRecovery = false;

/// Lien partagé (/a/<token>) reçu alors que l'utilisateur n'était pas
/// connecté. Il est rouvert automatiquement après la connexion.
String? _pendingLocation;

/// Route initiale à ouvrir quand l'application est lancée à froid par un
/// lien partagé. Doit être renseignée avant la création de [router].
String? _initialLocation;

/// Traduit un lien entrant en route interne, ou null si le lien n'est pas
/// un lien de partage reconnu.
///
/// Formats acceptés :
/// - https://mampionona-rakotovao.github.io/a/<id>
/// - carnetadresses://a/<id>
String? _routeDepuisLien(Uri? uri) {
  if (uri == null) return null;

  String? token;
  if (uri.scheme == 'https' &&
      uri.host == 'mampionona-rakotovao.github.io' &&
      uri.pathSegments.length >= 2 &&
      uri.pathSegments.first == 'a') {
    token = uri.pathSegments[1];
  } else if (uri.scheme == 'carnetadresses') {
    if (uri.host == 'a' && uri.pathSegments.isNotEmpty) {
      token = uri.pathSegments.first;
    } else if (uri.pathSegments.length >= 2 && uri.pathSegments.first == 'a') {
      token = uri.pathSegments[1];
    }
  }

  if (token == null || token.isEmpty) return null;
  return '/a/$token';
}

/// Mémorise le lien partagé d'un lancement à froid. À appeler avant
/// [runApp] pour que l'application démarre directement sur l'adresse.
void definirLienInitial(Uri? uri) {
  final route = _routeDepuisLien(uri);
  if (route != null) _initialLocation ??= route;
}

/// Ouvre un lien partagé reçu alors que l'application est déjà lancée.
/// Retourne true si le lien a été reconnu et traité.
bool ouvrirLienEntrant(Uri? uri) {
  final route = _routeDepuisLien(uri);
  if (route == null) return false;
  router.go(route);
  return true;
}

/// À appeler une fois le mot de passe mis à jour avec succès.
void clearPasswordRecoveryFlag() => _isPasswordRecovery = false;

/// À appeler au démarrage quand l'application est ouverte sur le lien de
/// réinitialisation (`/reset-password`), avant même que Supabase n'ait
/// consommé le code. Couvre le cas web où l'événement [passwordRecovery] est
/// émis pendant `Supabase.initialize()`, donc avant que le routeur n'écoute.
void markPasswordRecovery() => _isPasswordRecovery = true;

void _listenForPasswordRecovery() {
  supabase.auth.onAuthStateChange.listen((data) {
    if (data.event == AuthChangeEvent.passwordRecovery) {
      _isPasswordRecovery = true;
    }
  });
}

final GoRouter router = _buildRouter();

GoRouter _buildRouter() {
  _listenForPasswordRecovery();
  return GoRouter(
    initialLocation: _initialLocation ?? '/',
    refreshListenable: GoRouterRefreshStream(supabase.auth.onAuthStateChange),
    redirect: (context, state) {
      final loggedIn = supabase.auth.currentSession != null;
      final onLoginPage = state.matchedLocation == '/login';
      final onResetPage = state.matchedLocation == '/reset-password';
      final onResetCodePage = state.matchedLocation == '/reset-code';
      final onConfirmPage = state.matchedLocation == '/confirm-email';

      // Une fois le mot de passe en cours de réinitialisation (code validé ou
      // lien ouvert), on force l'écran de saisie du nouveau mot de passe.
      if (_isPasswordRecovery) {
        return onResetPage ? null : '/reset-password';
      }

      if (!loggedIn && !onLoginPage && !onConfirmPage && !onResetCodePage) {
        // On retient le lien partagé pour le rouvrir après la connexion.
        if (state.matchedLocation.startsWith('/a/')) {
          _pendingLocation = state.uri.path;
        }
        return '/login';
      }

      if (loggedIn && (onLoginPage || onConfirmPage || onResetCodePage)) {
        final pending = _pendingLocation;
        _pendingLocation = null;
        return pending ?? '/';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const AuthScreen(),
      ),
      GoRoute(
        path: '/reset-code',
        builder: (context, state) => ResetCodeScreen(
          email: state.extra as String? ?? '',
        ),
      ),
      GoRoute(
        path: '/reset-password',
        builder: (context, state) => const ResetPasswordScreen(),
      ),
      GoRoute(
        path: '/confirm-email',
        builder: (context, state) => ConfirmEmailScreen(
          email: state.extra as String? ?? '',
        ),
      ),
      ShellRoute(
        builder: (context, state, child) => AppScaffold(child: child),
        // Onglets racine. « Ouvrir un lien » en fait partie : l'utilisateur
        // doit pouvoir changer d'onglet sans repasser par l'accueil.
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
      // Lien partagé : https://mampionona-rakotovao.github.io/a/<token>
      GoRoute(
        path: '/a/:token',
        builder: (context, state) => SharedLinkScreen(
          token: state.pathParameters['token']!,
        ),
      ),
      // Adresses reçues par lien, encore valides.
      GoRoute(
        path: '/shared',
        builder: (context, state) => const SharedWithMeScreen(),
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
}
