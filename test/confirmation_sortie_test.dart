import 'package:carnet_adresses_repere/core/app_scaffold.dart';
import 'package:carnet_adresses_repere/ui/app_page.dart';
import 'package:carnet_adresses_repere/ui/confirmation_sortie.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// Enregistre les appels au système sans fermer le processus de test.
final class _SortieEspion {
  _SortieEspion() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
      methodes.add(call.method);
      return null;
    });
  }

  final List<String> methodes = <String>[];

  void dispose() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  }
}

Future<void> _racine(WidgetTester tester, GlobalKey<NavigatorState> key) =>
    tester.pumpWidget(MaterialApp(
      navigatorKey: key,
      home: const ConfirmationSortie(
        child: Scaffold(body: Center(child: Text('racine'))),
      ),
    ));

void main() {
  late _SortieEspion espion;

  setUp(() => espion = _SortieEspion());
  tearDown(() => espion.dispose());

  testWidgets('le retour à la racine ouvre la confirmation sans quitter',
      (tester) async {
    final key = GlobalKey<NavigatorState>();
    await _racine(tester, key);
    await tester.pumpAndSettle();

    // Équivalent de ce que fait le routeur quand le téléphone demande un pop.
    await key.currentState!.maybePop();
    await tester.pumpAndSettle();

    expect(find.text('Quitter l’application ?'), findsOneWidget);
    expect(find.text('racine'), findsOneWidget);
    expect(espion.methodes, isNot(contains('SystemNavigator.pop')));
  });

  testWidgets('un second retour ferme le dialogue sans quitter',
      (tester) async {
    final key = GlobalKey<NavigatorState>();
    await _racine(tester, key);
    await tester.pumpAndSettle();

    await key.currentState!.maybePop();
    await tester.pumpAndSettle();
    expect(find.text('Quitter l’application ?'), findsOneWidget);

    await key.currentState!.maybePop();
    await tester.pumpAndSettle();

    expect(find.text('Quitter l’application ?'), findsNothing);
    expect(find.text('racine'), findsOneWidget);
    expect(espion.methodes, isNot(contains('SystemNavigator.pop')));
  });

  testWidgets('Annuler referme le dialogue et garde l’application ouverte',
      (tester) async {
    final key = GlobalKey<NavigatorState>();
    await _racine(tester, key);
    await tester.pumpAndSettle();

    await key.currentState!.maybePop();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();

    expect(find.text('Quitter l’application ?'), findsNothing);
    expect(find.text('racine'), findsOneWidget);
    expect(espion.methodes, isNot(contains('SystemNavigator.pop')));
  });

  testWidgets('Quitter demande au système de fermer l’application',
      (tester) async {
    final key = GlobalKey<NavigatorState>();
    await _racine(tester, key);
    await tester.pumpAndSettle();

    await key.currentState!.maybePop();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Quitter'));
    await tester.pumpAndSettle();

    expect(find.text('Quitter l’application ?'), findsNothing);
    expect(espion.methodes, contains('SystemNavigator.pop'));
  });

  testWidgets('appPage protège la racine d’un shell go_router', (tester) async {
    final shellKey = GlobalKey<NavigatorState>();
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        ShellRoute(
          navigatorKey: shellKey,
          builder: (context, state, child) => AppScaffold(child: child),
          routes: [
            GoRoute(
              path: '/',
              pageBuilder: (context, state) => appPage(
                key: state.pageKey,
                child: const Center(child: Text('racine shell')),
              ),
            ),
          ],
        ),
      ],
    );
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    await shellKey.currentState!.maybePop();
    await tester.pumpAndSettle();

    expect(find.text('Quitter l’application ?'), findsOneWidget);
    expect(espion.methodes, isNot(contains('SystemNavigator.pop')));
  });

  testWidgets('le retour système sur un onglet du shell ouvre la confirmation',
      (tester) async {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        ShellRoute(
          builder: (context, state, child) => AppScaffold(child: child),
          routes: [
            GoRoute(
              path: '/',
              pageBuilder: (context, state) => appPage(
                key: state.pageKey,
                child: const Center(child: Text('racine shell')),
              ),
            ),
          ],
        ),
      ],
    );
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    // Vrai bouton retour : WidgetsApp interroge le routeur, puis demande au
    // système de fermer l'application si personne ne gère le pop.
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('Quitter l’application ?'), findsOneWidget);
    expect(find.text('racine shell'), findsOneWidget);
    expect(espion.methodes, isNot(contains('SystemNavigator.pop')));
  });

  testWidgets('une page empilée dans le shell revient sans confirmation',
      (tester) async {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        ShellRoute(
          builder: (context, state, child) => AppScaffold(child: child),
          routes: [
            GoRoute(
              path: '/',
              pageBuilder: (context, state) => appPage(
                key: state.pageKey,
                child: Center(
                  child: Builder(
                    builder: (context) => TextButton(
                      onPressed: () => context.push('/share/open'),
                      child: const Text('ouvrir'),
                    ),
                  ),
                ),
              ),
            ),
            GoRoute(
              path: '/share/open',
              pageBuilder: (context, state) => appPage(
                key: state.pageKey,
                child: const Center(child: Text('détail shell')),
              ),
            ),
          ],
        ),
      ],
    );
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    await tester.tap(find.text('ouvrir'));
    await tester.pumpAndSettle();
    expect(find.text('détail shell'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('détail shell'), findsNothing);
    expect(find.text('ouvrir'), findsOneWidget);
    expect(find.text('Quitter l’application ?'), findsNothing);
    expect(espion.methodes, isNot(contains('SystemNavigator.pop')));
  });

  testWidgets('une page empilée revient en arrière sans confirmation',
      (tester) async {
    final key = GlobalKey<NavigatorState>();
    await tester.pumpWidget(MaterialApp(
      navigatorKey: key,
      home: ConfirmationSortie(
        child: Scaffold(
          body: Center(
            child: Builder(
              builder: (context) => TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const ConfirmationSortie(
                      child: Scaffold(body: Center(child: Text('détail'))),
                    ),
                  ),
                ),
                child: const Text('ouvrir'),
              ),
            ),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('ouvrir'));
    await tester.pumpAndSettle();
    expect(find.text('détail'), findsOneWidget);

    await key.currentState!.maybePop();
    await tester.pumpAndSettle();

    expect(find.text('détail'), findsNothing);
    expect(find.text('ouvrir'), findsOneWidget);
    expect(find.text('Quitter l’application ?'), findsNothing);
    expect(espion.methodes, isNot(contains('SystemNavigator.pop')));
  });
}
