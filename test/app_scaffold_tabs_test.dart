import 'package:carnet_adresses_repere/core/app_scaffold.dart';
import 'package:carnet_adresses_repere/ui/app_bottom_nav.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

Widget _page(String label) => Scaffold(body: Center(child: Text(label)));

GoRouter _router(String initialLocation) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      ShellRoute(
        builder: (context, state, child) => AppScaffold(child: child),
        routes: [
          GoRoute(
            path: '/bienvenue',
            builder: (context, state) => _page('bienvenue'),
          ),
          GoRoute(path: '/', builder: (context, state) => _page('adresses')),
          GoRoute(
            path: '/search',
            builder: (context, state) => _page('recherche'),
          ),
          GoRoute(
            path: '/favorites',
            builder: (context, state) => _page('favoris'),
          ),
          GoRoute(
            path: '/share/open',
            builder: (context, state) => _page('ouvrir-lien'),
          ),
        ],
      ),
    ],
  );
}

Future<void> _pump(WidgetTester tester, String location) async {
  final router = _router(location);
  await tester.pumpWidget(MaterialApp.router(routerConfig: router));
  await tester.pumpAndSettle();
}

int _currentIndex(WidgetTester tester) {
  final nav = tester.widget<AppBottomNav>(find.byType(AppBottomNav));
  return nav.currentIndex;
}

void main() {
  testWidgets('index d’onglet pour chaque chemin', (tester) async {
    await _pump(tester, '/bienvenue');
    expect(_currentIndex(tester), 0);

    await _pump(tester, '/');
    expect(_currentIndex(tester), AppScaffold.indexAdresses);

    await _pump(tester, '/search');
    expect(_currentIndex(tester), 2);

    await _pump(tester, '/favorites');
    expect(_currentIndex(tester), 3);
  });

  testWidgets('/share/open replie sur l’onglet Adresses', (tester) async {
    await _pump(tester, '/share/open');
    expect(_currentIndex(tester), AppScaffold.indexAdresses);
    expect(find.text('ouvrir-lien'), findsOneWidget);
  });
}
