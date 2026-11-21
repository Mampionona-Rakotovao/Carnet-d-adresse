import 'package:carnet_adresses_repere/core/router.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() {
    clearPasswordRecoveryFlag();
    setPendingSharedLocationForTest(null);
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

  test('pas de redirection à la restauration de session sur une page normale', () {
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
}
