import 'package:carnet_adresses_repere/core/app_haptics.dart';
import 'package:carnet_adresses_repere/core/app_scaffold.dart';
import 'package:carnet_adresses_repere/core/theme/app_theme.dart';
import 'package:carnet_adresses_repere/ui/app_bottom_nav.dart';
import 'package:carnet_adresses_repere/ui/app_menu_button.dart';
import 'package:carnet_adresses_repere/ui/icons/address_book_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// Barre de navigation réelle du shell, dans un harnais sans routeur complet :
/// on vérifie les libellés et la présence de l'icône dessinée.
Widget _barre() => AppBottomNav(
      items: const [
        AppBottomNavItem(
          label: 'Accueil',
          icon: Icons.home_outlined,
          selectedIcon: Icons.home,
        ),
        AppBottomNavItem(
          label: 'Adresses',
          iconBuilder: AddressBookIcon.outline,
          selectedIconBuilder: AddressBookIcon.solid,
        ),
        AppBottomNavItem(
          label: 'Recherche',
          icon: Icons.search_outlined,
          selectedIcon: Icons.search,
        ),
        AppBottomNavItem(
          label: 'Favoris',
          icon: Icons.star_border,
          selectedIcon: Icons.star,
        ),
      ],
      currentIndex: 0,
      onTap: (_) {},
    );

void main() {
  setUp(() => AppHaptics.enabled = false);

  testWidgets('la barre affiche les quatre libellés attendus', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light,
      home:
          Scaffold(body: Center(child: SizedBox(width: 360, child: _barre()))),
    ));
    await tester.pumpAndSettle();

    for (final label in ['Accueil', 'Adresses', 'Recherche', 'Favoris']) {
      expect(find.text(label), findsOneWidget, reason: 'libellé $label');
    }
    expect(find.text('Bienvenue'), findsNothing);
    expect(find.byIcon(Icons.home), findsOneWidget);
    expect(find.byIcon(Icons.search_outlined), findsOneWidget);
    expect(find.byIcon(Icons.star_border), findsOneWidget);
  });

  testWidgets('le menu ⋮ est sur l’accueil et plus sur la page Adresses',
      (tester) async {
    final router = GoRouter(
      initialLocation: '/bienvenue',
      routes: [
        ShellRoute(
          builder: (context, state, child) => AppScaffold(child: child),
          routes: [
            GoRoute(
              path: '/bienvenue',
              builder: (context, state) => Scaffold(
                appBar: AppBar(
                  title: const Text('Bienvenue'),
                  actions: const [AppMenuButton()],
                ),
              ),
            ),
            GoRoute(
              path: '/',
              builder: (context, state) =>
                  Scaffold(appBar: AppBar(title: const Text('Mes adresses'))),
            ),
          ],
        ),
      ],
    );
    await tester.pumpWidget(MaterialApp.router(
      theme: AppTheme.light,
      routerConfig: router,
    ));
    await tester.pumpAndSettle();

    expect(find.byType(AppMenuButton), findsOneWidget);
    expect(find.byTooltip(AppMenuButton.tooltip), findsOneWidget);
    expect(find.byIcon(Icons.more_vert), findsOneWidget);

    // La barre flottante est posée en bas : taper le libellé de l'onglet.
    await tester.tap(find.text('Adresses'));
    await tester.pumpAndSettle();

    expect(find.byType(AppMenuButton), findsNothing);
    expect(find.byIcon(Icons.more_vert), findsNothing);
  });

  testWidgets('le menu s’ouvre au bon endroit et se ferme avant navigation',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Bienvenue'),
          actions: const [AppMenuButton()],
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Ajouter une adresse'), findsNothing);
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    // Toutes les entrées d'origine sont conservées.
    for (final entree in [
      'Apparence',
      'Système',
      'Clair',
      'Sombre',
      'Ajouter une adresse',
      'Partagées avec moi',
      'Aide',
      'Se déconnecter',
    ]) {
      expect(find.text(entree), findsOneWidget, reason: 'entrée $entree');
    }
    // La sortie se fait uniquement par le retour système : pas d'entrée
    // « Quitter » dans le menu ⋮.
    expect(find.text('Quitter l’application'), findsNothing);
    // Le menu s'ouvre juste sous l'AppBar (haut de l'écran), jamais au-dessus
    // de la barre flottante en bas.
    final premiereEntree = tester.getRect(find.text('Apparence'));
    expect(premiereEntree.top, lessThan(300));

    await tester.tapAt(const Offset(10, 400));
    await tester.pumpAndSettle();
    expect(find.text('Ajouter une adresse'), findsNothing);
  });

  testWidgets('l’icône carnet se construit en contour et en plein',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: Center(
          child: Row(
            children: [
              AddressBookIcon(size: 24, color: Colors.black, filled: false),
              AddressBookIcon(size: 24, color: Colors.white, filled: true),
            ],
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.byType(AddressBookIcon), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });
}
