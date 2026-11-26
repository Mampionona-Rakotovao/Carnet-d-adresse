import 'package:carnet_adresses_repere/core/router.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Reproduit exactement le chemin du routeur : le drapeau de démarrage est
/// consommé à chaque évaluation, puis l'événement auth est traduit.
String? rediriger({
  required bool loggedIn,
  required String location,
  required DemarrageAFroid demarrage,
  AuthChangeEvent? evenement,
}) {
  final connexionUtilisateur = switch (evenement) {
    AuthChangeEvent.initialSession || AuthChangeEvent.tokenRefreshed => false,
    AuthChangeEvent.signedIn => true,
    _ => null,
  };
  return computeRedirect(
    loggedIn: loggedIn,
    matchedLocation: location,
    uriString: location,
    demarrageAFroid: demarrage.consommer(),
    connexionUtilisateur: connexionUtilisateur,
  );
}

void main() {
  setUp(() {
    clearPasswordRecoveryFlag();
    setPendingSharedLocationForTest(null);
    setAuthEventForTest(null);
  });

  test('redirige vers /bienvenue après connexion sur /login', () {
    final result = computeRedirect(
      loggedIn: true,
      matchedLocation: '/login',
      uriString: '/login',
    );
    expect(result, '/bienvenue');
  });

  test('redirige vers /bienvenue après confirmation email', () {
    final result = computeRedirect(
      loggedIn: true,
      matchedLocation: '/confirm-email',
      uriString: '/confirm-email',
    );
    expect(result, '/bienvenue');
  });

  test('redirige vers /bienvenue après code de réinitialisation', () {
    final result = computeRedirect(
      loggedIn: true,
      matchedLocation: '/reset-code',
      uriString: '/reset-code',
    );
    expect(result, '/bienvenue');
  });

  test('pas de redirection à la restauration de session sur une page normale',
      () {
    final result = computeRedirect(
      loggedIn: true,
      matchedLocation: '/',
      uriString: '/',
    );
    expect(result, isNull);
  });

  test('pas de redirection au refresh token sur un onglet', () {
    final result = computeRedirect(
      loggedIn: true,
      matchedLocation: '/favorites',
      uriString: '/favorites',
    );
    expect(result, isNull);
  });

  test('lien partagé en attente prioritaire après connexion', () {
    setPendingSharedLocationForTest('/a/token123');
    final result = computeRedirect(
      loggedIn: true,
      matchedLocation: '/login',
      uriString: '/login',
    );
    expect(result, '/a/token123');
    expect(pendingSharedLocationForTest, isNull);
  });

  test('utilisateur non connecté sur lien partagé est renvoyé au login', () {
    final result = computeRedirect(
      loggedIn: false,
      matchedLocation: '/a/token123',
      uriString: '/a/token123',
    );
    expect(result, '/login');
    expect(pendingSharedLocationForTest, '/a/token123');
  });

  test('recovery de mot de passe reste prioritaire', () {
    markPasswordRecovery();
    final result = computeRedirect(
      loggedIn: true,
      matchedLocation: '/',
      uriString: '/',
    );
    expect(result, '/reset-password');
  });

  group('démarrage à froid', () {
    test('session valide : ouvre Accueil une seule fois', () {
      final demarrage = DemarrageAFroid();
      expect(
        rediriger(loggedIn: true, location: '/', demarrage: demarrage),
        '/bienvenue',
      );
      // Le drapeau est consommé : l'onglet Adresses redevient accessible.
      expect(
        rediriger(loggedIn: true, location: '/', demarrage: demarrage),
        isNull,
      );
      expect(
        rediriger(loggedIn: true, location: '/bienvenue', demarrage: demarrage),
        isNull,
      );
    });

    test('sans session : écran de connexion', () {
      expect(
        rediriger(
          loggedIn: false,
          location: '/',
          demarrage: DemarrageAFroid(),
        ),
        '/login',
      );
    });

    test('lien partagé au démarrage : le lien garde la priorité', () {
      expect(
        rediriger(
          loggedIn: true,
          location: '/a/token123',
          demarrage: DemarrageAFroid(),
        ),
        isNull,
      );
      expect(pendingSharedLocationForTest, isNull);
    });

    test('reset de mot de passe au démarrage : écran du mot de passe', () {
      markPasswordRecovery();
      expect(
        rediriger(
          loggedIn: true,
          location: '/',
          demarrage: DemarrageAFroid(),
        ),
        '/reset-password',
      );
    });

    test('lien partagé en attente repris avant Accueil', () {
      setPendingSharedLocationForTest('/a/token123');
      expect(
        rediriger(
          loggedIn: true,
          location: '/',
          demarrage: DemarrageAFroid(),
        ),
        '/a/token123',
      );
    });
  });

  group('événements d’authentification', () {
    test('retour au premier plan : aucune redirection', () {
      final demarrage = DemarrageAFroid()..consommer();
      expect(
        rediriger(
          loggedIn: true,
          location: '/search',
          demarrage: demarrage,
        ),
        isNull,
      );
    });

    test('restauration de session et refresh de jeton : aucune redirection',
        () {
      final demarrage = DemarrageAFroid()..consommer();
      for (final event in [
        AuthChangeEvent.initialSession,
        AuthChangeEvent.tokenRefreshed,
      ]) {
        expect(
          rediriger(
              loggedIn: true,
              location: '/',
              demarrage: demarrage,
              evenement: event),
          isNull,
        );
      }
    });

    test('connexion réelle (signedIn) : Accueil', () {
      final demarrage = DemarrageAFroid()..consommer();
      setAuthEventForTest(AuthChangeEvent.signedIn);
      expect(
        rediriger(
          loggedIn: true,
          location: '/login',
          demarrage: demarrage,
          evenement: authEventForTest,
        ),
        '/bienvenue',
      );
    });
  });
}
