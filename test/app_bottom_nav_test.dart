import 'package:carnet_adresses_repere/core/app_haptics.dart';
import 'package:carnet_adresses_repere/core/theme/app_theme.dart';
import 'package:carnet_adresses_repere/ui/app_bottom_nav.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Harnais : reconstruit [AppBottomNav] quand `courant` change, comme le
/// ferait le routeur.
class _Harnais extends StatefulWidget {
  const _Harnais({
    required this.courant,
    required this.onTap,
    this.items,
  });

  final int courant;
  final ValueChanged<int> onTap;
  final List<AppBottomNavItem>? items;

  @override
  State<_Harnais> createState() => _HarnaisState();
}

class _HarnaisState extends State<_Harnais> {
  late int courant;

  @override
  void initState() {
    super.initState();
    courant = widget.courant;
  }

  @override
  Widget build(BuildContext context) {
    return AppBottomNav(
      items: widget.items ??
          const [
            AppBottomNavItem(
              label: 'Accueil',
              icon: Icons.home_outlined,
              selectedIcon: Icons.home,
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
      currentIndex: courant,
      onTap: (i) {
        setState(() => courant = i);
        widget.onTap(i);
      },
    );
  }
}

List<AppBottomNavItem> onglets(int n) => switch (n) {
      3 => const [
          AppBottomNavItem(
              label: 'Accueil', icon: Icons.home_outlined, selectedIcon: Icons.home),
          AppBottomNavItem(
              label: 'Recherche',
              icon: Icons.search_outlined,
              selectedIcon: Icons.search),
          AppBottomNavItem(
              label: 'Favoris', icon: Icons.star_border, selectedIcon: Icons.star),
        ],
      4 => const [
          AppBottomNavItem(
              label: 'Accueil', icon: Icons.home_outlined, selectedIcon: Icons.home),
          AppBottomNavItem(
              label: 'Recherche',
              icon: Icons.search_outlined,
              selectedIcon: Icons.search),
          AppBottomNavItem(
              label: 'Favoris', icon: Icons.star_border, selectedIcon: Icons.star),
          AppBottomNavItem(
              label: 'Partages', icon: Icons.share_outlined, selectedIcon: Icons.share),
        ],
      _ => const [
          AppBottomNavItem(
              label: 'Accueil', icon: Icons.home_outlined, selectedIcon: Icons.home),
          AppBottomNavItem(
              label: 'Recherche',
              icon: Icons.search_outlined,
              selectedIcon: Icons.search),
          AppBottomNavItem(
              label: 'Favoris', icon: Icons.star_border, selectedIcon: Icons.star),
          AppBottomNavItem(
              label: 'Repères', icon: Icons.place_outlined, selectedIcon: Icons.place),
          AppBottomNavItem(
              label: 'Partages', icon: Icons.share_outlined, selectedIcon: Icons.share),
        ],
    };

Future<void> pomper(
  WidgetTester tester, {
  required int nombre,
  required ThemeMode mode,
  int courant = 0,
}) async {
  await tester.pumpWidget(MaterialApp(
    theme: AppTheme.light,
    darkTheme: AppTheme.dark,
    themeMode: mode,
    home: Scaffold(
      body: Center(
        child: SizedBox(width: 360, child: _Harnais(courant: courant, onTap: (_) {})),
      ),
    ),
  ));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => AppHaptics.enabled = false);

  group('Goldens — 3, 4 et 5 onglets, clair et sombre', () {
    for (final mode in [ThemeMode.light, ThemeMode.dark]) {
      final suffixe = mode == ThemeMode.light ? 'clair' : 'sombre';
      for (final n in [3, 4, 5]) {
        testWidgets('$n onglets, $suffixe', (tester) async {
          await tester.pumpWidget(MaterialApp(
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: mode,
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 360,
                  child: _Harnais(courant: 0, onTap: (_) {}, items: onglets(n)),
                ),
              ),
            ),
          ));
          await tester.pumpAndSettle();
          await expectLater(
            find.byType(AppBottomNav),
            matchesGoldenFile('goldens/app_bottom_nav_${n}_$suffixe.png'),
          );
        });
      }
    }

    testWidgets('badge de compteur sur l’icône', (tester) async {
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 360,
              child: _Harnais(
                courant: 0,
                onTap: (_) {},
                items: const [
                  AppBottomNavItem(
                      label: 'Accueil',
                      icon: Icons.home_outlined,
                      selectedIcon: Icons.home,
                      badgeCount: 3),
                  AppBottomNavItem(
                      label: 'Recherche',
                      icon: Icons.search_outlined,
                      selectedIcon: Icons.search),
                  AppBottomNavItem(
                      label: 'Favoris',
                      icon: Icons.star_border,
                      selectedIcon: Icons.star),
                ],
              ),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(AppBottomNav),
        matchesGoldenFile('goldens/app_bottom_nav_badge.png'),
      );
    });
  });

  testWidgets('tap sur une cellule appelle onTap', (tester) async {
    final touches = <int>[];
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 360,
            child: _Harnais(courant: 0, onTap: touches.add),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Recherche'));
    await tester.pumpAndSettle();
    expect(touches, [1]);
  });

  testWidgets('tap sur la bulle appelle onTap', (tester) async {
    final touches = <int>[];
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 360,
            child: _Harnais(courant: 0, onTap: touches.add),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    // La bulle porte l'icône pleine de l'onglet actif.
    await tester.tap(find.byIcon(Icons.home));
    await tester.pumpAndSettle();
    expect(touches, [0]);
  });

  testWidgets('le changement d’onglet glisse puis s’arrête sur la cible',
      (tester) async {
    final handle = tester.ensureSemantics();
    await pomper(tester, nombre: 3, mode: ThemeMode.light, courant: 0);

    expect(find.byIcon(Icons.home), findsOneWidget);
    expect(find.byIcon(Icons.search), findsNothing);

    await tester.tap(find.text('Recherche'));
    // Pendant l'animation : les deux icônes pleines coexistent.
    await tester.pump(const Duration(milliseconds: 120));
    expect(find.byIcon(Icons.search), findsOneWidget);
    expect(find.byIcon(Icons.home), findsOneWidget);
    await tester.pumpAndSettle();

    // Arrivé : seule l'icône pleine de la cible reste, la cellule est
    // marquée sélectionnée pour les lecteurs d'écran.
    expect(find.byIcon(Icons.search), findsOneWidget);
    expect(find.byIcon(Icons.home), findsNothing);
    expect(
      find.bySemanticsLabel('Recherche'),
      findsOneWidget,
    );
    handle.dispose();
  });

  testWidgets('previousIndex anime l’arrivée d’une barre fraîche',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 360,
            child: AppBottomNav(
              items: onglets(3),
              currentIndex: 2,
              previousIndex: 0,
              onTap: (_) {},
            ),
          ),
        ),
      ),
    ));

    // Au premier rendu la bulle part de l'onglet 0…
    await tester.pump();
    expect(find.byIcon(Icons.home), findsOneWidget);
    // …puis glisse jusqu'à l'onglet 2.
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.star), findsOneWidget);
    expect(find.byIcon(Icons.home), findsNothing);
  });

  testWidgets('animations réduites : changement instantané', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light,
      home: MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: Scaffold(
          body: Center(
            child: SizedBox(
              width: 360,
              child: _Harnais(courant: 0, onTap: (_) {}),
            ),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Favoris'));
    // Un seul rendu suffit : pas de glissement.
    await tester.pump();
    expect(find.byIcon(Icons.star), findsOneWidget);
    expect(find.byIcon(Icons.home), findsNothing);
    await tester.pumpAndSettle();
  });

  testWidgets('clavier ouvert : la barre se masque', (tester) async {
    // Architecture du shell : la barre vit dans le `body` d'un Scaffold
    // `resizeToAvoidBottomInset: false` — sans cela le Scaffold retirerait
    // les viewInsets du body et la barre ne saurait jamais que le clavier
    // est ouvert (et les écrans ne verraient plus le clavier non plus).
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light,
      home: MediaQuery(
        data: const MediaQueryData(viewInsets: EdgeInsets.only(bottom: 300)),
        child: Scaffold(
          resizeToAvoidBottomInset: false,
          body: Stack(
            children: [
              const SizedBox.expand(),
              Align(
                alignment: Alignment.bottomCenter,
                child: _Harnais(courant: 0, onTap: (_) {}),
              ),
            ],
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byType(AppBottomNav),
        matching: find.byType(CustomPaint),
      ),
      findsNothing,
    );
    expect(find.byIcon(Icons.home_outlined), findsNothing);
  });

  testWidgets('la barre s\'ancre en bas de l\'écran du shell', (tester) async {
    // Régression : un `Center` interne faisait flotter la barre au milieu
    // de l'écran dès que le parent lui donnait une hauteur bornée (tout
    // l'écran) au lieu d'une hauteur non bornée.
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        resizeToAvoidBottomInset: false,
        body: Stack(
          clipBehavior: Clip.none,
          children: [
            const SizedBox.expand(),
            Align(
              alignment: Alignment.bottomCenter,
              child: AppBottomNav(
                items: onglets(3),
                currentIndex: 0,
                onTap: (_) {},
              ),
            ),
          ],
        ),
      ),
    ));
    await tester.pumpAndSettle();

    final rect = tester.getRect(
      find
          .descendant(
            of: find.byType(AppBottomNav),
            matching: find.byType(CustomPaint),
          )
          .first,
    );
    // Surface de test 800x600, marge basse 12 : la barre visuelle (114 dp,
    // largeur plafonnée à 560 centrée) est posée sur le bas de l'écran.
    expect(rect.bottom, 588);
    expect(rect.top, 474);
    expect(rect.left, 120);
  });

  testWidgets('ancrée en bas même posée dans le slot bottomNavigationBar',
      (tester) async {
    // Garde-fou : c'est ce placement qui a révélé le bug. Le slot layoute
    // la barre avec une hauteur bornée (0 → écran, source Flutter
    // scaffold.dart : fullWidthConstraints), qui l'avait centrée.
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        appBar: AppBar(title: const Text('Mes adresses')),
        body: const SizedBox.expand(),
        extendBody: true,
        bottomNavigationBar: AppBottomNav(
          items: onglets(3),
          currentIndex: 0,
          onTap: (_) {},
        ),
      ),
    ));
    await tester.pumpAndSettle();

    final rect = tester.getRect(
      find
          .descendant(
            of: find.byType(AppBottomNav),
            matching: find.byType(CustomPaint),
          )
          .first,
    );
    expect(rect.bottom, 588);
    expect(rect.top, 474);
  });

  testWidgets('la bulle qui dépasse au-dessus de la barre reste cliquable',
      (tester) async {
    final touches = <int>[];
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        resizeToAvoidBottomInset: false,
        body: Stack(
          clipBehavior: Clip.none,
          children: [
            const SizedBox.expand(),
            Align(
              alignment: Alignment.bottomCenter,
              child: AppBottomNav(
                items: onglets(3),
                currentIndex: 0,
                onTap: touches.add,
              ),
            ),
          ],
        ),
      ),
    ));
    await tester.pumpAndSettle();

    // Le haut de la barre rectangulaire est à y = 520 : l'icône de la
    // bulle est plus haut, dans la zone qui dépasse — elle doit pourtant
    // réagir au tap.
    final bulle = tester.getRect(find.byIcon(Icons.home));
    expect(bulle.top, lessThan(520));
    await tester.tap(find.byIcon(Icons.home));
    await tester.pumpAndSettle();
    expect(touches, [0]);
  });

  testWidgets('hauteurTotale inclut la zone de sécurité', (tester) async {
    double? hauteur;
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light,
      home: MediaQuery(
        data: const MediaQueryData(viewPadding: EdgeInsets.only(bottom: 24)),
        child: Scaffold(
          body: Builder(
            builder: (context) {
              hauteur = AppBottomNav.hauteurTotale(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    ));
    // 46 (bulle) + 68 (barre) + 12 (marge) + 24 (système)
    expect(hauteur, 150);
  });
}
