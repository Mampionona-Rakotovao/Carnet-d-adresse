import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

/// Styles de fond « adresses et cartes », dessinés par le code.
enum AppBackgroundStyle {
  /// Lignes de relief et quelques pins : accueil, recherche, favoris.
  releve,

  /// Quadrillage de rues très léger : formulaires, création d'adresse.
  rues,

  /// Grande illustration en haut : connexion, inscription, mot de passe
  /// oublié, vérification e-mail.
  hero,

  /// Relief seul, très discret : aide, partage reçu.
  calme,

  /// Illustration centrée : états vides et erreurs.
  vide,

  /// Aucun motif : écrans à contenu dense (carte, guidage).
  aucun,
}

/// Fond décoratif « adresses et cartes ».
///
/// Le widget peint la couleur de fond du thème (`scaffoldBackgroundColor`),
/// puis un motif dessiné par un [CustomPainter] — courbes de relief,
/// quadrillage de rues, itinéraires pointillés, pins, cercles de précision
/// GPS, boussole — puis [child] par-dessus. Aucune image, aucune dépendance.
///
/// Lisibilité : le motif reste décoratif, mais assez contrasté pour se lire
/// en mode clair comme en sombre. Les traits suivent `ColorScheme.primary`
/// (clair) ou `ColorScheme.secondary` (sombre, plus lumineux sur fond nuit),
/// et quelques éléments `AppPalette.accent`. Les cartes et champs, opaques,
/// passent par-dessus sans mélange.
///
/// Performance : la couche du motif est isolée par un [RepaintBoundary] qui
/// l'entoure **elle seule** — le contenu défile au-dessus sans jamais
/// redéclencher la peinture du fond. La géométrie ([Path] lourds) est
/// pré-calculée une fois par couple (style, taille) et mise en cache, et le
/// dessin est déterministe (graine fixe) : le motif ne change ni d'une
/// reconstruction à l'autre, ni d'un écran à l'autre pour un même style.
///
/// Le fond est décoratif : [ExcludeSemantics] le rend invisible aux lecteurs
/// d'écran. Il ne contient volontairement ni texte, ni lettre, ni nom de
/// lieu.
class AppBackground extends StatelessWidget {
  const AppBackground({
    super.key,
    required this.child,
    this.style = AppBackgroundStyle.releve,
  });

  final Widget child;
  final AppBackgroundStyle style;

  @override
  Widget build(BuildContext context) {
    // Style neutre : le Scaffold hôte peint déjà la couleur de fond.
    if (style == AppBackgroundStyle.aucun) return child;

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final clair = theme.brightness == Brightness.light;
    // En sombre, le bleu primaire est trop proche du fond : le secondary
    // (cyan plus clair) garde le motif lisible. L'accent teal reste distinct.
    final couleurTrait = clair ? scheme.primary : scheme.secondary;
    final couleurAccent = AppPalette.of(context).accent;

    return Stack(
      // Les contraintes du parent passent telles quelles au contenu :
      // l'intégrer ne change rien à sa mise en page.
      fit: StackFit.passthrough,
      children: [
        // La couche du fond, isolée du contenu défilant : le RepaintBoundary
        // entoure le fond, jamais le contenu. Decoratif, le fond est soustrait
        // de l'arbre sémantique — mais lui seul, jamais le contenu.
        ExcludeSemantics(
          child: RepaintBoundary(
            child: CustomPaint(
              painter: _MotifPainter(
                style: style,
                fond: theme.scaffoldBackgroundColor,
                trait:
                    couleurTrait.withValues(alpha: _alphaTrait(style, clair)),
                accent:
                    couleurAccent.withValues(alpha: _alphaAccent(style, clair)),
              ),
              isComplex: true,
              willChange: false,
              // Le CustomPaint se dimensionne sur son enfant : plein cadre.
              child: const SizedBox.expand(),
            ),
          ),
        ),
        child,
      ],
    );
  }

  /// Nombre de peintures du fond. Exposé pour les tests de performance : le
  /// fond ne doit jamais être repeint pendant le défilement du contenu.
  @visibleForTesting
  static int get debugPeintures => _MotifPainter.debugPeintures;

  /// Remet à zéro le compteur de peintures et purge le cache de géométrie.
  /// Réservé aux tests (determinisme : deux constructions indépendantes).
  @visibleForTesting
  static void debugReinitialiser() {
    _MotifPainter.debugPeintures = 0;
    _Motif.viderCache();
  }

  /// Opacité des traits : assez haute pour que le motif se lise, assez
  /// basse pour ne pas concurrencer le texte secondaire. Le mode sombre
  /// monte un peu plus : le fond nuit avale les traits trop transparents.
  static double _alphaTrait(AppBackgroundStyle style, bool clair) {
    if (clair) {
      return switch (style) {
        AppBackgroundStyle.calme => 0.10,
        AppBackgroundStyle.rues => 0.11,
        AppBackgroundStyle.hero => 0.13,
        _ => 0.12,
      };
    }
    return switch (style) {
      AppBackgroundStyle.calme => 0.14,
      AppBackgroundStyle.rues => 0.15,
      AppBackgroundStyle.hero => 0.20,
      _ => 0.18,
    };
  }

  /// Opacité des éléments colorés (pins, aiguilles, points GPS).
  static double _alphaAccent(AppBackgroundStyle style, bool clair) {
    if (clair) {
      return switch (style) {
        AppBackgroundStyle.calme => 0.14,
        AppBackgroundStyle.hero => 0.20,
        _ => 0.18,
      };
    }
    return switch (style) {
      AppBackgroundStyle.calme => 0.18,
      AppBackgroundStyle.hero => 0.26,
      _ => 0.22,
    };
  }
}

/// Peint le fond : couleur du thème, puis le motif, puis rien (le contenu
/// est posé par-dessus par le [Stack] du widget).
///
/// Un changement de taille (rotation, redimensionnement de fenêtre) passe
/// par le relayout du [CustomPaint], que le framework repeint toujours :
/// [shouldRepaint] ne s'occupe donc que du style et du thème.
class _MotifPainter extends CustomPainter {
  _MotifPainter({
    required this.style,
    required this.fond,
    required this.trait,
    required this.accent,
  });

  final AppBackgroundStyle style;
  final Color fond;
  final Color trait;
  final Color accent;

  /// Nombre de peintures effectuées. Exposé uniquement pour les tests de
  /// performance : le fond ne doit jamais être repeint pendant le défilement.
  @visibleForTesting
  static int debugPeintures = 0;

  @override
  void paint(Canvas canvas, Size size) {
    debugPeintures++;
    // 1. La couleur de fond du thème, toujours pleine.
    canvas.drawRect(Offset.zero & size, Paint()..color = fond);
    // 2. Le motif, dont la géométrie est en cache.
    _Motif.obtenir(style, size).peindre(canvas, trait, accent, fond);
  }

  @override
  bool shouldRepaint(_MotifPainter ancien) =>
      style != ancien.style ||
      fond != ancien.fond ||
      trait != ancien.trait ||
      accent != ancien.accent;
}

/// Encre d'une marque du motif.
enum _Encre { trait, accent }

/// Une marque élémentaire du motif : un chemin pré-construit, son encre,
/// son épaisseur de trait, et sa façon de se remplir.
class _Marque {
  const _Marque(this.chemin, this.encre, this.largeur, {this.plein = false});

  final Path chemin;
  final _Encre encre;
  final double largeur;
  final bool plein;
}

/// Géométrie complète d'un motif pour un couple (style, taille).
///
/// Tout est pré-calculé au premier rendu puis mis en cache : la peinture
/// elle-même ne fait que rejouer des chemins déjà construits. Le cache garde
/// le motif courant (un seul slot) : les trois onglets du shell, qui partagent
/// style et taille, touchent le cache au changement d'écran.
class _Motif {
  const _Motif(this.marques, this.fondu);

  /// Marques du motif, dessinées dans l'ordre.
  final List<_Marque> marques;

  /// Zone du fondu du style [AppBackgroundStyle.hero] (transparent vers la
  /// couleur de fond), null pour les autres styles.
  final Rect? fondu;

  static _Motif? _cache;
  static (AppBackgroundStyle, Size)? _cle;

  static _Motif obtenir(AppBackgroundStyle style, Size taille) {
    final cle = (style, taille);
    final motif = _cache;
    if (motif != null && _cle == cle) return motif;
    final construit = _construire(style, taille);
    _cache = construit;
    _cle = cle;
    return construit;
  }

  /// Purge le cache (tests uniquement).
  static void viderCache() {
    _cache = null;
    _cle = null;
  }

  void peindre(Canvas canvas, Color trait, Color accent, Color fond) {
    final pinceauTrait = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final pinceauAccent = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    for (final marque in marques) {
      final pinceau =
          marque.encre == _Encre.trait ? pinceauTrait : pinceauAccent;
      pinceau.color = marque.encre == _Encre.trait ? trait : accent;
      pinceau.strokeWidth = marque.largeur * 1.25;
      pinceau.style = marque.plein ? PaintingStyle.fill : PaintingStyle.stroke;
      canvas.drawPath(marque.chemin, pinceau);
    }

    // Fondu du style hero : un simple dégradé linéaire, jamais de ShaderMask.
    final zone = fondu;
    if (zone != null) {
      canvas.drawRect(
        zone,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [fond.withValues(alpha: 0), fond],
          ).createShader(zone),
      );
    }
  }

  // ---------------------------------------------------------------------
  // Construction des motifs. Graine fixe : le dessin est déterministe.
  // ---------------------------------------------------------------------

  static _Motif _construire(AppBackgroundStyle style, Size taille) {
    switch (style) {
      case AppBackgroundStyle.releve:
        return _releve(taille);
      case AppBackgroundStyle.rues:
        return _rues(taille);
      case AppBackgroundStyle.hero:
        return _hero(taille);
      case AppBackgroundStyle.calme:
        return _calme(taille);
      case AppBackgroundStyle.vide:
        return _vide(taille);
      case AppBackgroundStyle.aucun:
        return const _Motif([], null);
    }
  }

  /// Relief + pins : accueil, recherche, favoris. Dense dans les coins,
  /// presque vide au centre.
  static _Motif _releve(Size t) {
    final rnd = math.Random(42);
    final marques = <_Marque>[];

    // Deux collines de courbes de niveau, dans des coins opposés.
    _courbesNiveau(
      marques,
      rnd,
      centre: Offset(t.width * 0.08, t.height * 0.07),
      rayon: 46,
    );
    _courbesNiveau(
      marques,
      rnd,
      centre: Offset(t.width * 0.93, t.height * 0.96),
      rayon: 52,
    );

    // Quelques pins épars, près des bords.
    _pin(marques, Offset(t.width * 0.055, t.height * 0.52), 20);
    _pin(marques, Offset(t.width * 0.945, t.height * 0.30), 20);
    _pin(marques, Offset(t.width * 0.28, t.height * 0.965), 16);

    // Un cercle de précision GPS discret en haut à droite.
    _gps(marques, Offset(t.width * 0.90, t.height * 0.13), 30);

    return _Motif(marques, null);
  }

  /// Quadrillage de rues incliné, quelques diagonales et ronds-points.
  /// Le centre reste dégagé pour le formulaire.
  static _Motif _rues(Size t) {
    final marques = <_Marque>[];
    const inclinaison = -7 * math.pi / 180;
    const pas = 88.0;

    // Grille complète, puis on retire l'ellipse centrale : le motif ne passe
    // jamais sous la zone de saisie.
    final diagonale = math.max(t.width, t.height) * 1.5;
    // On incline la grille autour du centre de l'écran : les extrémités des
    // lignes sont tournées directement (pas de transformation de matrice).
    final cos = math.cos(inclinaison);
    final sin = math.sin(inclinaison);
    final pivot = Offset(t.width / 2, t.height / 2);
    Offset tourner(Offset p) {
      final dx = p.dx - pivot.dx;
      final dy = p.dy - pivot.dy;
      return Offset(
        pivot.dx + dx * cos - dy * sin,
        pivot.dy + dx * sin + dy * cos,
      );
    }

    final grille = Path();
    for (double x = -diagonale; x <= diagonale; x += pas) {
      grille.moveTo(
          tourner(Offset(x, -diagonale)).dx, tourner(Offset(x, -diagonale)).dy);
      grille.lineTo(
          tourner(Offset(x, diagonale)).dx, tourner(Offset(x, diagonale)).dy);
    }
    for (double y = -diagonale; y <= diagonale; y += pas) {
      grille.moveTo(
          tourner(Offset(-diagonale, y)).dx, tourner(Offset(-diagonale, y)).dy);
      grille.lineTo(
          tourner(Offset(diagonale, y)).dx, tourner(Offset(diagonale, y)).dy);
    }

    // Zone centrale dégagée.
    final rayons = _rayonsZoneDegagee(t);
    final centre = Path()
      ..addOval(Rect.fromCenter(
        center: Offset(t.width / 2, t.height / 2),
        width: rayons.dx * 2,
        height: rayons.dy * 2,
      ));
    final grilleDegagee = Path.combine(
      PathOperation.difference,
      grille,
      centre,
    );
    marques.add(_Marque(grilleDegagee, _Encre.trait, 0.9));

    // Deux connexions en diagonale dans les coins.
    final diagonale1 = Path()
      ..moveTo(0, t.height * 0.12)
      ..lineTo(t.width * 0.14, t.height * 0.02);
    final diagonale2 = Path()
      ..moveTo(t.width, t.height * 0.90)
      ..lineTo(t.width * 0.86, t.height * 0.99);
    marques.add(_Marque(diagonale1, _Encre.trait, 1.0));
    marques.add(_Marque(diagonale2, _Encre.trait, 1.0));

    // Ronds-points aux intersections proches des bords (double cercle +
    // point central).
    _rondPoint(marques, Offset(t.width * 0.10, t.height * 0.88), 7);
    _rondPoint(marques, Offset(t.width * 0.92, t.height * 0.14), 7);

    return _Motif(marques, null);
  }

  /// Grande illustration dans le tiers supérieur : itinéraire pointillé
  /// avec départ et pin d'arrivée, cercles GPS et boussole discrète. Un
  /// dégradé doux fond la scène dans la page.
  static _Motif _hero(Size t) {
    final rnd = math.Random(42);
    final marques = <_Marque>[];
    final zoneHaut = t.height * 0.40;

    // Itinéraire en S à travers la zone, en pointillés (PathMetrics).
    final itineraire = Path()
      ..moveTo(-12, zoneHaut * 0.58)
      ..cubicTo(
        t.width * 0.22,
        zoneHaut * 0.10,
        t.width * 0.38,
        zoneHaut * 0.85,
        t.width * 0.50,
        zoneHaut * 0.42,
      )
      ..cubicTo(
        t.width * 0.62,
        zoneHaut * 0.05,
        t.width * 0.80,
        zoneHaut * 0.72,
        t.width + 12,
        zoneHaut * 0.30,
      );
    final pointilles = _pointille(itineraire, tiret: 9, espace: 8);
    marques.add(_Marque(pointilles, _Encre.trait, 1.5));

    // Départ : point plein sur l'itinéraire. Arrivée : pin au bout.
    final metrics = itineraire.computeMetrics().toList();
    if (metrics.isNotEmpty) {
      final longueur = metrics.first.length;
      final depart =
          metrics.first.getTangentForOffset(longueur * 0.12)?.position;
      final arrivee =
          metrics.first.getTangentForOffset(longueur * 0.88)?.position;
      if (depart != null) {
        final point = Path()
          ..addOval(Rect.fromCircle(center: depart, radius: 3.2));
        marques.add(_Marque(point, _Encre.accent, 0, plein: true));
      }
      if (arrivee != null) {
        _pin(marques, arrivee, 22);
      }
    }

    // Cercles de précision GPS et boussole dans les coins hauts.
    _gps(marques, Offset(t.width * 0.88, zoneHaut * 0.24), 26);
    _boussole(marques, Offset(t.width * 0.11, zoneHaut * 0.26), 24);

    // Une ébauche de relief tout en bas de la zone, pour lier la scène.
    _courbesNiveau(
      marques,
      rnd,
      centre: Offset(t.width * 0.06, t.height * 0.05),
      rayon: 34,
      lignes: 2,
    );

    // Fondu doux vers la couleur de fond : l'illustration se fond dans la
    // page, le formulaire en dessous reste sur fond uni.
    return _Motif(
        marques, Rect.fromLTWH(0, zoneHaut * 0.55, t.width, t.height * 0.30));
  }

  /// Relief seul, très discret : aide, partage reçu.
  static _Motif _calme(Size t) {
    final rnd = math.Random(42);
    final marques = <_Marque>[];
    _courbesNiveau(
      marques,
      rnd,
      centre: Offset(t.width * 0.92, t.height * 0.06),
      rayon: 40,
      lignes: 2,
    );
    _courbesNiveau(
      marques,
      rnd,
      centre: Offset(t.width * 0.07, t.height * 0.95),
      rayon: 44,
      lignes: 2,
    );
    return _Motif(marques, null);
  }

  /// Illustration centrée pour les états vides et erreurs : carte pliée
  /// vide entourée de cercles de précision GPS. Le contenu de l'état
  /// (icône, textes, bouton) se pose par-dessus.
  static _Motif _vide(Size t) {
    final marques = <_Marque>[];
    final centre = Offset(t.width / 2, t.height / 2);

    // Carte pliée en trois volets, 150 dp de large (bande 120-160 dp).
    const largeur = 150.0, hauteur = 105.0;
    final rect = Rect.fromCenter(
      center: centre,
      width: largeur,
      height: hauteur,
    );
    final carte = Path()
      ..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(9)))
      ..moveTo(rect.left + rect.width / 3, rect.top + 3)
      ..lineTo(rect.left + rect.width / 3, rect.bottom - 3)
      ..moveTo(rect.left + rect.width * 2 / 3, rect.top + 3)
      ..lineTo(rect.left + rect.width * 2 / 3, rect.bottom - 3);
    marques.add(_Marque(carte, _Encre.trait, 1.2));

    // Un itinéraire pointillé discret à l'intérieur de la carte.
    final interieur = Path()
      ..moveTo(rect.left + 14, rect.bottom - 14)
      ..cubicTo(
        rect.left + rect.width * 0.30,
        rect.top + 12,
        rect.left + rect.width * 0.62,
        rect.bottom - 10,
        rect.right - 14,
        rect.top + 16,
      );
    marques.add(
        _Marque(_pointille(interieur, tiret: 6, espace: 6), _Encre.trait, 1.0));

    // Point de départ plein et pin d'arrivée sur la carte.
    final depart = Path()
      ..addOval(Rect.fromCircle(
        center: Offset(rect.left + 14, rect.bottom - 14),
        radius: 2.6,
      ));
    marques.add(_Marque(depart, _Encre.accent, 0, plein: true));
    _pin(marques, Offset(rect.right - 14, rect.top + 22), 18);

    // Cercles de précision GPS autour de la carte.
    _gps(marques, centre, 105);

    return _Motif(marques, null);
  }

  // ---------------------------------------------------------------------
  // Primitives de dessin.
  // ---------------------------------------------------------------------

  /// Rayons de la zone centrale à garder dégagée, bornés pour les très
  /// grands écrans (le centre reste readable sans étirer le motif).
  static Offset _rayonsZoneDegagee(Size t) => Offset(
        math.min(t.width * 0.34, 230),
        math.min(t.height * 0.30, 260),
      );

  /// Courbes de niveau concentriques autour d'un point : chemins fermés
  /// sinueux construits en courbes de Bézier.
  static void _courbesNiveau(
    List<_Marque> marques,
    math.Random rnd, {
    required Offset centre,
    required double rayon,
    int lignes = 3,
  }) {
    for (var ligne = 0; ligne < lignes; ligne++) {
      final r = rayon * (1 - ligne * 0.24);
      const points = 10;
      final rayons = List.generate(
        points,
        (_) => r * (1 + (rnd.nextDouble() - 0.5) * 0.34),
      );
      final sommets = List.generate(points, (i) {
        final angle = i * 2 * math.pi / points - math.pi / 2;
        return Offset(
          centre.dx + math.cos(angle) * rayons[i],
          centre.dy + math.sin(angle) * rayons[i],
        );
      });
      // Courbe fermée lissée : les sommets servent de points de contrôle,
      // la courbe passe par les milieux des arcs.
      Offset milieu(Offset a, Offset b) => (a + b) / 2;
      final chemin = Path()
        ..moveTo(milieu(sommets.last, sommets.first).dx,
            milieu(sommets.last, sommets.first).dy);
      for (var i = 0; i < points; i++) {
        final suivant = sommets[(i + 1) % points];
        final controle = milieu(sommets[i], suivant);
        chemin.quadraticBezierTo(
          sommets[i].dx,
          sommets[i].dy,
          controle.dx,
          controle.dy,
        );
      }
      chemin.close();
      marques.add(_Marque(chemin, _Encre.trait, 1.1));
    }
  }

  /// Pin stylisé : goutte (cercle prolongé vers une pointe) + point central.
  static void _pin(List<_Marque> marques, Offset pointe, double hauteur) {
    final r = hauteur * 0.42;
    final centre = Offset(pointe.dx, pointe.dy - hauteur + r);
    final gauche = Offset(centre.dx - r, centre.dy);
    final droit = Offset(centre.dx + r, centre.dy);
    final goutte = Path()
      ..moveTo(gauche.dx, gauche.dy)
      ..cubicTo(
        gauche.dx,
        centre.dy - r,
        droit.dx,
        centre.dy - r,
        droit.dx,
        droit.dy,
      )
      ..quadraticBezierTo(
        centre.dx + r * 0.60,
        centre.dy + r * 0.95,
        pointe.dx,
        pointe.dy,
      )
      ..quadraticBezierTo(
        centre.dx - r * 0.60,
        centre.dy + r * 0.95,
        gauche.dx,
        gauche.dy,
      )
      ..close();
    marques.add(_Marque(goutte, _Encre.accent, 1.2));

    final point = Path()
      ..addOval(Rect.fromCircle(center: centre, radius: r * 0.30));
    marques.add(_Marque(point, _Encre.accent, 0, plein: true));
  }

  /// Cercles de précision GPS concentriques + point central.
  static void _gps(List<_Marque> marques, Offset centre, double rayon) {
    final cercles = Path()
      ..addOval(Rect.fromCircle(center: centre, radius: rayon))
      ..addOval(Rect.fromCircle(center: centre, radius: rayon * 0.62));
    marques.add(_Marque(cercles, _Encre.trait, 1.0));
    final point = Path()..addOval(Rect.fromCircle(center: centre, radius: 2.2));
    marques.add(_Marque(point, _Encre.accent, 0, plein: true));
  }

  /// Boussole discrète : cercle, graduations, aiguille. Aucune lettre.
  static void _boussole(List<_Marque> marques, Offset centre, double rayon) {
    final cercle = Path()
      ..addOval(Rect.fromCircle(center: centre, radius: rayon));
    marques.add(_Marque(cercle, _Encre.trait, 1.0));

    final graduations = Path();
    for (var i = 0; i < 8; i++) {
      final angle = i * math.pi / 4;
      final sens = Offset(math.cos(angle), math.sin(angle));
      graduations.moveTo(
        centre.dx + sens.dx * rayon * 0.84,
        centre.dy + sens.dy * rayon * 0.84,
      );
      graduations.lineTo(
        centre.dx + sens.dx * rayon * 0.95,
        centre.dy + sens.dy * rayon * 0.95,
      );
    }
    marques.add(_Marque(graduations, _Encre.trait, 1.0));

    // Aiguille inclinée : losange fin, pointe accent.
    const cap = 32 * math.pi / 180;
    final direction = Offset(math.cos(cap), math.sin(cap));
    final perpendiculaire = Offset(-direction.dy, direction.dx);
    final pointe = centre + direction * rayon * 0.62;
    final arriere = centre - direction * rayon * 0.34;
    final aiguille = Path()
      ..moveTo(pointe.dx, pointe.dy)
      ..lineTo(
        centre.dx + perpendiculaire.dx * rayon * 0.10,
        centre.dy + perpendiculaire.dy * rayon * 0.10,
      )
      ..lineTo(arriere.dx, arriere.dy)
      ..lineTo(
        centre.dx - perpendiculaire.dx * rayon * 0.10,
        centre.dy - perpendiculaire.dy * rayon * 0.10,
      )
      ..close();
    marques.add(_Marque(aiguille, _Encre.accent, 1.0));
  }

  /// Rond-point : double cercle + point central.
  static void _rondPoint(List<_Marque> marques, Offset centre, double rayon) {
    final cercles = Path()
      ..addOval(Rect.fromCircle(center: centre, radius: rayon))
      ..addOval(Rect.fromCircle(center: centre, radius: rayon * 0.55));
    marques.add(_Marque(cercles, _Encre.trait, 0.9));
    final point = Path()..addOval(Rect.fromCircle(center: centre, radius: 1.6));
    marques.add(_Marque(point, _Encre.trait, 0, plein: true));
  }

  /// Transforme un chemin en pointillés via [PathMetrics].
  static Path _pointille(Path source,
      {required double tiret, required double espace}) {
    final dest = Path();
    for (final metric in source.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final fin = math.min(distance + tiret, metric.length);
        dest.addPath(metric.extractPath(distance, fin), Offset.zero);
        distance += tiret + espace;
      }
    }
    return dest;
  }
}
