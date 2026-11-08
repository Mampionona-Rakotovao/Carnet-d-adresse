import 'package:carnet_adresses_repere/features/help/screens/help_article_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _page(String text) => Scaffold(body: Center(child: Text(text)));

GoRouter _router(String initialLocation) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      ShellRoute(
        builder: (context, state, child) => Scaffold(body: child),
        routes: [
          GoRoute(path: '/', builder: (context, state) => _page('accueil')),
          GoRoute(
              path: '/search', builder: (context, state) => _page('recherche')),
          GoRoute(
            path: '/favorites',
            builder: (context, state) => _page('favoris'),
          ),
          GoRoute(
            path: '/share/open',
            builder: (context, state) => _page('ouvrir un lien'),
          ),
        ],
      ),
      GoRoute(
        path: '/aide',
        builder: (context, state) => _page('centre d’aide'),
      ),
      GoRoute(
        path: '/aide/:id',
        builder: (context, state) => HelpArticleScreen(
          articleId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/shared',
        builder: (context, state) => _page('adresses partagées'),
      ),
      GoRoute(
        path: '/address/create',
        builder: (context, state) => _page('nouvelle adresse'),
      ),
    ],
  );
}

Future<void> _openArticle(WidgetTester tester, String articleId) async {
  SharedPreferences.setMockInitialValues({});
  final router = _router('/aide/$articleId');
  await tester.pumpWidget(MaterialApp.router(routerConfig: router));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('« Ouvrir l’accueil » sélectionne l’onglet Accueil sans planter',
      (tester) async {
    await _openArticle(tester, 'accueil');

    await tester.tap(find.text('Ouvrir l\'accueil'));
    await tester.pumpAndSettle();

    expect(find.text('accueil'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('les actions vers les onglets utilisent une route valide',
      (tester) async {
    const cases = {
      'accueil': ('Ouvrir l\'accueil', 'accueil'),
      'ajouter-favoris': ('Ouvrir les favoris', 'favoris'),
      'rechercher-adresse': ('Ouvrir la recherche', 'recherche'),
    };

    for (final entry in cases.entries) {
      await _openArticle(tester, entry.key);

      await tester.tap(find.text(entry.value.$1));
      await tester.pumpAndSettle();

      expect(find.text(entry.value.$2), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('les actions vers les écrans de tâche restent empilées',
      (tester) async {
    const cases = {
      'creer-adresse': ('Ouvrir le formulaire d\'adresse', 'nouvelle adresse'),
      'partagees-avec-moi': (
        'Ouvrir « Partagées avec moi »',
        'adresses partagées',
      ),
    };

    for (final entry in cases.entries) {
      await _openArticle(tester, entry.key);

      await tester.tap(find.text(entry.value.$1));
      await tester.pumpAndSettle();

      expect(find.text(entry.value.$2), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });
}
