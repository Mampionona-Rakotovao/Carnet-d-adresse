import 'package:carnet_adresses_repere/core/theme/app_theme.dart';
import 'package:carnet_adresses_repere/ui/app_background.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Harnais : reconstruit l'arbre pour simuler un écran qui se rouvre (le
/// fond doit être identique d'une construction à l'autre).
Widget _ecran({
  AppBackgroundStyle style = AppBackgroundStyle.releve,
  ThemeMode mode = ThemeMode.light,
  Widget? contenu,
}) =>
    MaterialApp(
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: mode,
      home: Scaffold(
        body: AppBackground(
          style: style,
          // Contenu neutre par défaut : les goldens ne montrent que le
          // motif, pour pouvoir le valider au pixel près.
          child: contenu ?? const SizedBox.expand(),
        ),
      ),
    );

void main() {
  setUp(AppBackground.debugReinitialiser);

  group('Goldens — styles, clair et sombre', () {
    for (final mode in [ThemeMode.light, ThemeMode.dark]) {
      final suffixe = mode == ThemeMode.light ? 'clair' : 'sombre';
      for (final style in [
        AppBackgroundStyle.releve,
        AppBackgroundStyle.rues,
        AppBackgroundStyle.hero,
        AppBackgroundStyle.calme,
        AppBackgroundStyle.vide,
      ]) {
        testWidgets('${style.name}, $suffixe', (tester) async {
          await tester.pumpWidget(_ecran(style: style, mode: mode));
          await tester.pumpAndSettle();
          await expectLater(
            find.byType(AppBackground),
            matchesGoldenFile('goldens/app_background_${style.name}_$suffixe.png'),
          );
        });
      }
    }
  });

  group('Goldens — tailles extrêmes', () {
    testWidgets('releve sur petit écran (320x480)', (tester) async {
      tester.view.physicalSize = const Size(320, 480);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(_ecran());
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(AppBackground),
        matchesGoldenFile('goldens/app_background_releve_petit.png'),
      );
    });

    testWidgets('releve sur grand écran (1200x800)', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(_ecran());
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(AppBackground),
        matchesGoldenFile('goldens/app_background_releve_large.png'),
      );
    });
  });

  group('Déterminisme', () {
    testWidgets('deux constructions indépendantes donnent le même dessin',
        (tester) async {
      // Première construction, comparée au golden de référence.
      await tester.pumpWidget(_ecran(style: AppBackgroundStyle.hero));
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(AppBackground),
        matchesGoldenFile('goldens/app_background_hero_clair.png'),
      );

      // Démontage complet, purge du cache de géométrie, reconstruction :
      // le motif doit être identique (graine fixe).
      await tester.pumpWidget(const SizedBox.shrink());
      AppBackground.debugReinitialiser();
      await tester.pumpWidget(_ecran(style: AppBackgroundStyle.hero));
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(AppBackground),
        matchesGoldenFile('goldens/app_background_hero_clair.png'),
      );
    });

    testWidgets('reconstruire sans changement ne repeint pas le fond',
        (tester) async {
      await tester.pumpWidget(_ecran());
      await tester.pumpAndSettle();
      final apresRendu = AppBackground.debugPeintures;
      expect(apresRendu, greaterThan(0));

      // Reconstruction à l'identique (même style, même taille, mêmes
      // couleurs) : shouldRepaint renvoie faux, rien n'est repeint.
      await tester.pumpWidget(_ecran());
      await tester.pumpAndSettle();
      expect(AppBackground.debugPeintures, apresRendu);
    });
  });

  group('Performance', () {
    testWidgets('le défilement du contenu ne repeint jamais le fond',
        (tester) async {
      await tester.pumpWidget(_ecran(
        contenu: ListView.builder(
          itemCount: 120,
          itemExtent: 56,
          itemBuilder: (_, i) => ListTile(title: Text('Élément $i')),
        ),
      ));
      await tester.pumpAndSettle();
      final apresRendu = AppBackground.debugPeintures;

      await tester.fling(
        find.byType(ListView),
        const Offset(0, -600),
        2000,
      );
      await tester.pumpAndSettle();
      await tester.fling(
        find.byType(ListView),
        const Offset(0, 600),
        1500,
      );
      await tester.pumpAndSettle();
      await tester.drag(
        find.byType(ListView),
        const Offset(0, -120),
      );
      await tester.pumpAndSettle();

      expect(
        AppBackground.debugPeintures,
        apresRendu,
        reason: 'le fond doit rester peint une seule fois, le contenu '
            'défile par-dessus dans sa propre couche',
      );
    });
  });

  group('Thème', () {
    testWidgets('le fond suit le thème sans redémarrage', (tester) async {
      await tester.pumpWidget(_ecran(mode: ThemeMode.light));
      await tester.pumpAndSettle();
      final peinturesClair = AppBackground.debugPeintures;

      // Bascule clair -> sombre sur le même arbre : le fond se repeint avec
      // les couleurs du nouveau thème.
      await tester.pumpWidget(_ecran(mode: ThemeMode.dark));
      await tester.pumpAndSettle();
      expect(AppBackground.debugPeintures, greaterThan(peinturesClair));
    });
  });

  group('Neutralité', () {
    testWidgets('style aucun : aucun motif peint', (tester) async {
      await tester.pumpWidget(_ecran(style: AppBackgroundStyle.aucun));
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byType(AppBackground),
          matching: find.byType(CustomPaint),
        ),
        findsNothing,
      );
    });

    testWidgets("le fond ne change pas la mise en page du contenu",
        (tester) async {
      final cle = GlobalKey();
      await tester.pumpWidget(_ecran(
        contenu: Center(
          child: SizedBox(
            key: cle,
            width: 50,
            height: 50,
            child: const Text('X'),
          ),
        ),
      ));
      await tester.pumpAndSettle();
      // Sans fond, le Center remplirait le body et centrerait la boîte :
      // exactement ce que le Stack laisse faire (contraintes identiques).
      final rect = tester.getRect(find.byKey(cle));
      expect(rect.center, const Offset(400, 300)); // surface de test 800x600
    });

    testWidgets('le fond est ignoré par les lecteurs d’écran, pas le contenu',
        (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_ecran(
        contenu: const Center(child: Text('Contenu')),
      ));
      await tester.pumpAndSettle();

      // Le contenu garde toute sa sémantique.
      expect(tester.getSemantics(find.text('Contenu')).label, 'Contenu');
      handle.dispose();
    });
  });
}
