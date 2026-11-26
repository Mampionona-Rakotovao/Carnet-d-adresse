import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_client.dart';
import '../features/auth/auth_screen.dart';
import '../features/auth/confirm_email_screen.dart';
import '../features/auth/reset_code_screen.dart';
import '../features/auth/reset_password_screen.dart';
import '../features/home/home_screen.dart';
import '../features/welcome/welcome_screen.dart';
import '../features/address_create/address_form_screen.dart';
import '../features/address_create/step_wizard_screen.dart';
import '../features/address_detail/address_detail_screen.dart';
import '../features/search/search_screen.dart';
import '../features/favorites/favorites_screen.dart';
import '../features/help/screens/help_article_screen.dart';
import '../features/help/screens/help_category_screen.dart';
import '../features/help/screens/help_center_screen.dart';
import '../features/share/redeem_share_screen.dart';
import '../features/share/shared_with_me_screen.dart';
import '../features/share/shared_link_screen.dart';
import '../models/address.dart';
import '../ui/app_page.dart';
import '../ui/not_found_page.dart';
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

/// Dernier événement d'authentification reçu de Supabase.
///
/// Sert à distinguer une vraie connexion ([AuthChangeEvent.signedIn]) de la
/// restauration d'une session existante (`initialSession`) ou du
/// rafraîchissement silencieux du jeton (`tokenRefreshed`) : ces deux derniers
/// ne doivent jamais déplacer l'utilisateur de l'écran où il se trouve.
AuthChangeEvent? _dernierEvenementAuth;

/// Drapeau à usage unique du démarrage à froid.
///
/// Consommé par la première navigation seulement. Il n'existe pas de
/// redirection permanente de `/` : l'onglet « Adresses » doit rester joignable.
class DemarrageAFroid {
  DemarrageAFroid({bool actif = true}) : _actif = actif;

  bool _actif;

  /// Consomme le drapeau et indique s'il était encore actif.
  bool consommer() {
    if (!_actif) return false;
    _actif = false;
    return true;
  }
}

final DemarrageAFroid _demarrageAFroid = DemarrageAFroid();

/// Route initiale à ouvrir quand l'application est lancée à froid par un
/// lien partagé. Doit être renseignée avant la création de [router].
String? _initialLocation;

/// Lien partagé mémorisé pendant la connexion, puis rouvert une fois la
/// session disponible.
String? _pendingSharedLocation;

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

/// Helpers de test : permettent de vérifier la logique de redirection sans
/// dépendre d'une session Supabase réelle.
void setPendingSharedLocationForTest(String? value) {
  _pendingSharedLocation = value;
}

String? get pendingSharedLocationForTest => _pendingSharedLocation;

bool get isPasswordRecoveryForTest => _isPasswordRecovery;

/// Helpers de test : simule un événement Supabase sans session réelle.
void setAuthEventForTest(AuthChangeEvent? event) =>
    _dernierEvenementAuth = event;

AuthChangeEvent? get authEventForTest => _dernierEvenementAuth;

/// Calcule la redirection du routeur. Pur vis-à-vis du routeur, mais lit les
/// drapeaux globaux de récupération de mot de passe et de lien partagé en attente.
///
/// [demarrageAFroid] est consommé par l'appelant avant chaque navigation :
/// une seule redirection vers l'Accueil est autorisée, au premier rendu.
/// [connexionUtilisateur] vaut `false` pour `initialSession` / `tokenRefreshed`
/// (restauration et refresh : aucune redirection), `true` pour `signedIn`, et
/// `null` quand l'événement n'est pas connu (par exemple sur le web, où le
/// flux OAuth peut s'être terminé avant l'abonnement au routeur).
String? computeRedirect({
  required bool loggedIn,
  required String matchedLocation,
  required String uriString,
  bool demarrageAFroid = false,
  bool? connexionUtilisateur,
}) {
  final onLoginPage = matchedLocation == '/login';
  final onResetPage = matchedLocation == '/reset-password';
  final onResetCodePage = matchedLocation == '/reset-code';
  final onConfirmPage = matchedLocation == '/confirm-email';
  final onSharedLink = matchedLocation.startsWith('/a/');

  // Une fois le mot de passe en cours de réinitialisation (code validé ou
  // lien ouvert), on force l'écran de saisie du nouveau mot de passe.
  if (_isPasswordRecovery) {
    return onResetPage ? null : '/reset-password';
  }

  // Un lien partagé exige un compte : on mémorise la destination pour
  // rouvrir le lien après la connexion.
  if (!loggedIn && onSharedLink) {
    _pendingSharedLocation = uriString;
    return '/login';
  }

  if (!loggedIn && !onLoginPage && !onConfirmPage && !onResetCodePage) {
    return '/login';
  }

  if (loggedIn) {
    final pending = _pendingSharedLocation;
    if (pending != null) {
      _pendingSharedLocation = null;
      return pending;
    }

    // Démarrage à froid avec une session valide : l'entrée par défaut est `/`,
    // on l'ouvre une seule fois sur l'Accueil. Ne pas rediriger `/` en
    // permanence, sinon l'onglet « Adresses » devient inatteignable.
    if (demarrageAFroid && matchedLocation == '/') {
      return '/bienvenue';
    }

    // Connexion réellement faite par l'utilisateur : on quitte l'écran
    // d'authentification. Une restauration de session ou un refresh de jeton
    // (connexionUtilisateur == false) ne déplace jamais l'utilisateur.
    if (connexionUtilisateur != false &&
        (onLoginPage || onConfirmPage || onResetCodePage)) {
      return '/bienvenue';
    }
  }
  return null;
}

void _listenForPasswordRecovery() {
  supabase.auth.onAuthStateChange.listen((data) {
    // Enregistré avant la création du routeur, donc avant l'abonnement de
    // `refreshListenable` : la redirection lit toujours le dernier événement.
    _dernierEvenementAuth = data.event;
    if (data.event == AuthChangeEvent.passwordRecovery) {
      _isPasswordRecovery = true;
    }
  });
}

/// Traduit un événement Supabase en information exploitable par [computeRedirect].
bool? _estConnexionUtilisateur(AuthChangeEvent? evenement) =>
    switch (evenement) {
      AuthChangeEvent.initialSession || AuthChangeEvent.tokenRefreshed => false,
      AuthChangeEvent.signedIn => true,
      _ => null,
    };

final GoRouter router = _buildRouter();

GoRouter _buildRouter() {
  _listenForPasswordRecovery();
  return GoRouter(
    initialLocation: _initialLocation ?? '/',
    refreshListenable: GoRouterRefreshStream(supabase.auth.onAuthStateChange),
    redirect: (context, state) {
      final loggedIn = supabase.auth.currentSession != null;
      // Le drapeau est consommé à la toute première évaluation de la
      // navigation, quelle que soit la route d'entrée. Ensuite, changer
      // d'onglet ne déclenche plus aucune redirection.
      final premiereNavigation = _demarrageAFroid.consommer();
      return computeRedirect(
        loggedIn: loggedIn,
        matchedLocation: state.matchedLocation,
        uriString: state.uri.toString(),
        demarrageAFroid: premiereNavigation,
        connexionUtilisateur: _estConnexionUtilisateur(_dernierEvenementAuth),
      );
    },
    errorBuilder: (context, state) => const NotFoundPage(),
    routes: [
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) => appPage(
          key: state.pageKey,
          child: const AuthScreen(),
        ),
      ),
      GoRoute(
        path: '/reset-code',
        pageBuilder: (context, state) => appPage(
          key: state.pageKey,
          child: ResetCodeScreen(
            email: state.extra as String? ?? '',
          ),
        ),
      ),
      GoRoute(
        path: '/reset-password',
        pageBuilder: (context, state) => appPage(
          key: state.pageKey,
          child: const ResetPasswordScreen(),
        ),
      ),
      GoRoute(
        path: '/confirm-email',
        pageBuilder: (context, state) => appPage(
          key: state.pageKey,
          child: ConfirmEmailScreen(
            email: state.extra as String? ?? '',
          ),
        ),
      ),
      ShellRoute(
        builder: (context, state, child) => AppScaffold(child: child),
        // Onglets racine. « Ouvrir un lien » en fait partie : l'utilisateur
        // doit pouvoir changer d'onglet sans repasser par l'accueil.
        routes: [
          GoRoute(
            path: '/bienvenue',
            pageBuilder: (context, state) => appPage(
              key: state.pageKey,
              child: const WelcomeScreen(),
            ),
          ),
          GoRoute(
            path: '/',
            pageBuilder: (context, state) => appPage(
              key: state.pageKey,
              child: const HomeScreen(),
            ),
          ),
          GoRoute(
            path: '/search',
            pageBuilder: (context, state) => appPage(
              key: state.pageKey,
              child: const SearchScreen(),
            ),
          ),
          GoRoute(
            path: '/favorites',
            pageBuilder: (context, state) => appPage(
              key: state.pageKey,
              child: const FavoritesScreen(),
            ),
          ),
          GoRoute(
            path: '/share/open',
            pageBuilder: (context, state) => appPage(
              key: state.pageKey,
              child: const RedeemShareScreen(),
            ),
          ),
        ],
      ),
      // Lien partagé : https://mampionona-rakotovao.github.io/a/<token>
      GoRoute(
        path: '/a/:token',
        pageBuilder: (context, state) => appPage(
          key: state.pageKey,
          child: SharedLinkScreen(
            token: state.pathParameters['token']!,
          ),
        ),
      ),
      // Adresses reçues par lien, encore valides.
      GoRoute(
        path: '/shared',
        pageBuilder: (context, state) => appPage(
          key: state.pageKey,
          child: const SharedWithMeScreen(),
        ),
      ),
      GoRoute(
        path: '/aide',
        pageBuilder: (context, state) => appPage(
          key: state.pageKey,
          child: const HelpCenterScreen(),
        ),
      ),
      GoRoute(
        path: '/aide/categorie/:categorie',
        pageBuilder: (context, state) => appPage(
          key: state.pageKey,
          child: HelpCategoryScreen(
            categoryName: state.pathParameters['categorie']!,
          ),
        ),
      ),
      GoRoute(
        path: '/aide/:id',
        pageBuilder: (context, state) => appPage(
          key: state.pageKey,
          child: HelpArticleScreen(
            articleId: state.pathParameters['id']!,
          ),
        ),
      ),
      GoRoute(
        path: '/address/create',
        pageBuilder: (context, state) => appPage(
          key: state.pageKey,
          child: const AddressFormScreen(),
        ),
      ),
      GoRoute(
        path: '/address/:id/edit',
        pageBuilder: (context, state) => appPage(
          key: state.pageKey,
          child: AddressFormScreen(
            existingAddress: state.extra as Address?,
          ),
        ),
      ),
      GoRoute(
        path: '/address/:id/steps',
        pageBuilder: (context, state) => appPage(
          key: state.pageKey,
          child: StepWizardScreen(
            addressId: state.pathParameters['id']!,
            addressName: state.extra as String? ?? '',
          ),
        ),
      ),
      GoRoute(
        path: '/address/:id',
        pageBuilder: (context, state) => appPage(
          key: state.pageKey,
          child: AddressDetailScreen(
            addressId: state.pathParameters['id']!,
          ),
        ),
      ),
    ],
  );
}
