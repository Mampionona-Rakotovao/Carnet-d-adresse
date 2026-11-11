import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/app_haptics.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_motion.dart';
import '../core/theme/app_spacing.dart';

/// Onglet de la barre de navigation flottante.
///
/// [icon] est la version contour (onglet inactif), [selectedIcon] la version
/// pleine affichée dans la bulle de l'onglet actif.
@immutable
class AppBottomNavItem {
  const AppBottomNavItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    this.tooltip,
    this.badgeCount,
  }) : assert(badgeCount == null || badgeCount >= 0, 'badgeCount >= 0');

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final String? tooltip;

  /// Compteur optionnel affiché sur l'icône (jamais sur le libellé).
  final int? badgeCount;
}

/// Dimensions de la bulle et de l'encoche.
///
/// Deux jeux : standard, et compact quand les onglets sont étroits (5 onglets
/// sur un petit écran) pour que l'encoche ne déborde pas des coins arrondis.
class _Geo {
  const _Geo({
    required this.bubbleRadius,
    required this.ringWidth,
    required this.lift,
    required this.notchGap,
  })  : ringOuter = bubbleRadius + ringWidth,
        notchRadius = bubbleRadius + ringWidth + notchGap;

  /// Rayon de la bulle (diamètre ≈ 56 dp en jeu standard).
  final double bubbleRadius;

  /// Épaisseur de l'anneau de surface autour de la bulle.
  final double ringWidth;

  /// Hauteur du centre de la bulle au-dessus du bord haut de la barre.
  final double lift;

  /// Jour entre l'anneau et l'encoche.
  final double notchGap;

  final double ringOuter;

  /// Rayon de l'encoche : rayon de la bulle + 6 à 8 dp.
  final double notchRadius;

  /// Zone tactile : la bulle et son anneau.
  double get hitRadius => ringOuter;

  /// Place à réserver au-dessus de la barre pour la bulle et son anneau.
  double get protrusion => lift + ringOuter + 1;

  static const _Geo standard =
      _Geo(bubbleRadius: 28, ringWidth: 3, lift: 14, notchGap: 4);
  static const _Geo compact =
      _Geo(bubbleRadius: 24, ringWidth: 2.5, lift: 12, notchGap: 3);
}

/// Barre de navigation inférieure « bulle flottante ».
///
/// Barre détachée des bords de l'écran ; l'onglet actif porte son icône dans
/// une bulle circulaire qui dépasse au-dessus de la barre, dans une encoche
/// concave tracée au [CustomPainter] (l'ombre suit la découpe). Le changement
/// d'onglet anime bulle et encoche avec un seul [AnimationController]
/// (~300 ms, `Curves.easeInOutCubic`) ; avec `disableAnimations`, le
/// changement est instantané.
///
/// Le composant est indépendant des routes : il reçoit `currentIndex` et
/// `onTap`. [previousIndex] permet à une barre fraîchement recréée (changement
/// de page dans le routeur) d'animer la bulle depuis l'onglet précédent.
///
/// La barre s'ancre toujours en bas de l'espace que son parent lui donne,
/// que cet espace soit borné (body plein écran) ou non : posée dans le
/// `body` d'un `Scaffold` via un `Stack` + `Align(bottomCenter)`, elle
/// flotte au-dessus de la zone de sécurité du système (`viewPadding`) sans
/// jamais passer dessous.
///
/// La barre se masque quand le clavier est ouvert (elle ne doit pas remonter
/// avec lui). Les écrans qui l'accueillent réservent la hauteur en bas de
/// leurs listes via [hauteurTotale] pour que le dernier élément reste
/// accessible.
class AppBottomNav extends StatefulWidget {
  const AppBottomNav({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
    this.previousIndex,
  })  : assert(items.length >= 2 && items.length <= 5, '2 à 5 onglets'),
        assert(currentIndex >= 0 && currentIndex < items.length,
            'currentIndex hors des onglets');

  final List<AppBottomNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  /// Onglet d'où la bulle doit glisser à la création de la barre.
  final int? previousIndex;

  /// Hauteur de la barre proprement dite (sans dépassement ni marge).
  static const double barHeight = 68;

  /// Marge entre la barre et le bord bas de l'écran (hors zone système).
  static const double margeBas = AppSpacing.sm; // 12

  /// Hauteur totale occupée par la barre : dépassement de la bulle + barre +
  /// marge basse + zone de sécurité système. À utiliser pour le padding
  /// inférieur des listes des écrans qui affichent la barre.
  static double hauteurTotale(BuildContext context) =>
      _Geo.standard.protrusion +
      barHeight +
      margeBas +
      MediaQuery.viewPaddingOf(context).bottom;

  @override
  State<AppBottomNav> createState() => _AppBottomNavState();
}

class _AppBottomNavState extends State<AppBottomNav>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final CurvedAnimation _slide;

  /// Position de départ et d'arrivée de la bulle, en « index » (fractionnaire
  /// pendant un retarget au vol).
  double _depuis = 0;
  double _vers = 0;

  bool _amorcee = false;

  @override
  void initState() {
    super.initState();
    _vers = widget.currentIndex.toDouble();
    final precedent = widget.previousIndex;
    _depuis = (precedent != null &&
            precedent >= 0 &&
            precedent < widget.items.length)
        ? precedent.toDouble()
        : _vers;
    _controller = AnimationController(
      vsync: this,
      duration: AppMotion.lent, // ajusté dans didChangeDependencies
      value: _depuis == _vers ? 1 : 0,
    );
    _slide = CurvedAnimation(parent: _controller, curve: AppMotion.etat);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Durée réelle : nulle si l'utilisateur demande moins d'animations.
    _controller.duration = AppMotion.duree(context, AppMotion.lent);
    if (!_amorcee) {
      _amorcee = true;
      if (_depuis != _vers) _controller.forward();
    }
  }

  @override
  void didUpdateWidget(AppBottomNav oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentIndex != _vers) {
      // Repartir de la position animée actuelle : la bulle ne saute jamais.
      _depuis = _indexAnime();
      _vers = widget.currentIndex.toDouble();
      if (AppMotion.reduit(context)) {
        _controller.value = 1;
      } else {
        _controller.forward(from: 0);
      }
    }
  }

  double _indexAnime() => _depuis + (_vers - _depuis) * _slide.value;

  @override
  void dispose() {
    _slide.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _tap(int index) {
    // Retour haptique au changement d'onglet uniquement.
    if (index != widget.currentIndex) AppHaptics.selectionClick();
    widget.onTap(index);
  }

  @override
  Widget build(BuildContext context) {
    // Le clavier ne doit jamais faire remonter la barre.
    if (MediaQuery.viewInsetsOf(context).bottom > 0) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final margeSysteme = MediaQuery.viewPaddingOf(context).bottom;

    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.2,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final largeurBarre =
              math.min(constraints.maxWidth - 2 * AppSpacing.md, 560.0);
          final nbOnglets = widget.items.length;
          final largeurOnglet = largeurBarre / nbOnglets;
          final geo = largeurOnglet < 70 ? _Geo.compact : _Geo.standard;
          final rtl = Directionality.of(context) == TextDirection.rtl;
          final hauteur = geo.protrusion + AppBottomNav.barHeight;

          return Padding(
            padding:
                EdgeInsets.only(bottom: AppBottomNav.margeBas + margeSysteme),
            // Ancrage en bas, jamais de centrage vertical : le parent peut
            // donner à la barre une boîte aussi haute que l'écran (body
            // d'un Stack, slot d'un Scaffold) et un `Center` la ferait
            // alors flotter au milieu. Sous hauteur non bornée, l'Align
            // se réduit à la barre : même rendu dans les deux cas.
            child: Align(
              alignment: Alignment.bottomCenter,
              child: SizedBox(
                width: largeurBarre,
                height: hauteur,
                child: RepaintBoundary(
                  child: AnimatedBuilder(
                    animation: _slide,
                    builder: (context, _) {
                      final t = _slide.value;
                      // Le fondu des icônes et libellés occupe la première
                      // moitié du glissement.
                      final fondu = (t * 2).clamp(0.0, 1.0);
                      final index = _depuis + (_vers - _depuis) * t;
                      final cx = rtl
                          ? largeurBarre - (index + 0.5) * largeurOnglet
                          : (index + 0.5) * largeurOnglet;

                      return Stack(
                        children: [
                          // Fond : barre à encoche + bulle, peintes ensemble
                          // pour que l'ombre suive exactement la découpe.
                          CustomPaint(
                            isComplex: true,
                            size: Size(largeurBarre, hauteur),
                            painter: _BarPainter(
                              cx: cx,
                              geo: geo,
                              scheme: theme.colorScheme,
                              palette: AppPalette.of(context),
                              brightness: theme.brightness,
                            ),
                          ),
                          // Zone tactile des onglets : toute la hauteur de la
                          // barre, au moins 48 dp de large.
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            height: AppBottomNav.barHeight,
                            child: Row(
                              children: [
                                for (var i = 0; i < nbOnglets; i++)
                                  Expanded(
                                    child: _onglet(i, fondu, geo, theme),
                                  ),
                              ],
                            ),
                          ),
                          // Bulle de l'onglet actif, cliquable.
                          Positioned(
                            left: cx - geo.hitRadius,
                            top: geo.protrusion - geo.lift - geo.hitRadius,
                            child: _bulle(fondu, geo, theme),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Une cellule d'onglet : icône + libellé, zone tactile de toute la
  /// hauteur de la barre.
  Widget _onglet(int i, double fondu, _Geo geo, ThemeData theme) {
    final item = widget.items[i];
    final scheme = theme.colorScheme;
    final cible = _vers.round();
    final source = _depuis.round();

    // L'icône de l'onglet visé s'efface de la rangée quand la bulle la
    // prend en charge ; celle de l'onglet quitté réapparaît.
    final double opaciteIcone;
    if (i == cible) {
      opaciteIcone = 1 - fondu;
    } else if (i == source && source != cible) {
      opaciteIcone = fondu;
    } else {
      opaciteIcone = 1;
    }

    // Le libellé passe en gras et en couleur forte sur l'onglet actif.
    final TextStyle styleInactif = TextStyle(
      fontSize: 12,
      height: 1.2,
      fontWeight: FontWeight.w500,
      color: scheme.onSurfaceVariant,
    );
    final TextStyle styleActif = TextStyle(
      fontSize: 12,
      height: 1.2,
      fontWeight: FontWeight.w700,
      color: scheme.onSurface,
    );
    final style = i == cible
        ? TextStyle.lerp(styleInactif, styleActif, fondu)!
        : i == source && source != cible
            ? TextStyle.lerp(styleActif, styleInactif, fondu)!
            : styleInactif;

    return Semantics(
      selected: i == widget.currentIndex,
      child: InkWell(
        onTap: () => _tap(i),
        customBorder: const StadiumBorder(),
        focusColor: scheme.primary.withValues(alpha: 0.10),
        child: SizedBox(
          height: AppBottomNav.barHeight,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                height: 30,
                child: Center(
  heightFactor: 1.0,
                  // Une icône d'opacité nulle n'est pas construite : elle
                  // vit dans la bulle. La hauteur fixe garde l'alignement.
                  child: opaciteIcone == 0
                      ? null
                      : Opacity(
                          opacity: opaciteIcone,
                          child: ExcludeSemantics(
                            excluding: opaciteIcone < 0.5,
                            child: _iconeAvecBadge(item, geo, scheme),
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: style,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Icône en contour avec, le cas échéant, son badge de compteur.
  Widget _iconeAvecBadge(
      AppBottomNavItem item, _Geo geo, ColorScheme scheme) {
    final compte = item.badgeCount;
    if (compte == null || compte <= 0) {
      return Icon(item.icon, size: geo.bubbleRadius == 28 ? 24 : 22);
    }
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        Icon(item.icon, size: geo.bubbleRadius == 28 ? 24 : 22),
        Positioned(
          top: -6,
          right: -10,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 5,
              vertical: 1,
            ),
            decoration: BoxDecoration(
              color: scheme.error,
              borderRadius: BorderRadius.circular(999),
            ),
            constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
            alignment: Alignment.center,
            child: Text(
              compte > 99 ? '99+' : '$compte',
              style: TextStyle(
                fontSize: 10,
                height: 1.4,
                fontWeight: FontWeight.w700,
                color: scheme.onError,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// La bulle de l'onglet actif : disque d'accent, anneau de surface, icône
  /// pleine. La sémantique est portée par la cellule de la rangée.
  Widget _bulle(double fondu, _Geo geo, ThemeData theme) {
    final scheme = theme.colorScheme;
    final cible = _vers.round();
    final source = _depuis.round();
    final tailleIcone = geo.bubbleRadius == 28 ? 26.0 : 22.0;

    return SizedBox(
      width: 2 * geo.hitRadius,
      height: 2 * geo.hitRadius,
      child: InkWell(
        onTap: () => _tap(cible),
        customBorder: const CircleBorder(),
        excludeFromSemantics: true,
        focusColor: scheme.onPrimary.withValues(alpha: 0.12),
        child: ExcludeSemantics(
          child: Center(
            child: SizedBox(
              width: 2 * geo.bubbleRadius,
              height: 2 * geo.bubbleRadius,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Icône de l'onglet quitté, qui s'efface (absente au repos).
                  if (fondu < 1)
                    Opacity(
                      opacity: 1 - fondu,
                      child: Icon(
                        widget.items[source].selectedIcon,
                        size: tailleIcone,
                        color: scheme.onPrimary,
                      ),
                    ),
                  // Icône de l'onglet visé, qui apparaît.
                  Opacity(
                    opacity: fondu,
                    child: Icon(
                      widget.items[cible].selectedIcon,
                      size: tailleIcone,
                      color: scheme.onPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Peint la barre à encoche (avec son ombre) et la bulle de l'onglet actif.
///
/// Tout est tracé dans un seul painter pour que l'ombre du [Canvas] suive
/// exactement la découpe de l'encoche, et non un rectangle.
class _BarPainter extends CustomPainter {
  const _BarPainter({
    required this.cx,
    required this.geo,
    required this.scheme,
    required this.palette,
    required this.brightness,
  });

  /// Position horizontale du centre de la bulle (et de l'encoche).
  final double cx;
  final _Geo geo;
  final ColorScheme scheme;
  final AppPalette palette;
  final Brightness brightness;

  /// Constante de Bézier pour un quart d'ellipse (≈ 0,5523).
  static const double _kappa = 0.5523;

  @override
  void paint(Canvas canvas, Size size) {
    final barTop = size.height - AppBottomNav.barHeight;
    final barre = Rect.fromLTWH(0, barTop, size.width, AppBottomNav.barHeight);
    final clair = brightness == Brightness.light;

    // --- Barre à encoche ----------------------------------------------
    final chemin = _cheminBarre(barre, barTop);

    // Ombre douce qui suit la découpe (discrète en mode sombre).
    final ombre = Paint()
      ..color = clair
          ? palette.shadow
          : scheme.shadow.withValues(alpha: 0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    canvas.drawPath(chemin.shift(Offset(0, clair ? 5 : 3)), ombre);

    canvas.drawPath(chemin, Paint()..color = scheme.surface);
    canvas.drawPath(
      chemin,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = scheme.outlineVariant,
    );

    // --- Bulle -----------------------------------------------------------
    final centre = Offset(cx, barTop - geo.lift);
    final pinceau = Paint();

    // Anneau de surface : sépare la bulle du fond visible dans l'encoche.
    pinceau.color = scheme.surface;
    canvas.drawCircle(centre, geo.ringOuter, pinceau);

    // Fin liseré turquoise sous la bulle (détail décoratif de la marque).
    canvas.drawArc(
      Rect.fromCircle(center: centre, radius: geo.bubbleRadius + geo.ringWidth / 2),
      55 * math.pi / 180,
      70 * math.pi / 180,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = geo.ringWidth - 0.5
        ..strokeCap = StrokeCap.round
        ..color = palette.accent,
    );

    // Disque d'accent puis icône pleine (widget au-dessus du painter).
    pinceau.color = scheme.primary;
    canvas.drawCircle(centre, geo.bubbleRadius, pinceau);
  }

  /// Rectangle arrondi (rayon 24) moins une encoche elliptique centrée sur
  /// la bulle : deux courbes cubiques tangentes au bord haut — pas d'angle
  /// vif où l'encoche rejoint la barre.
  Path _cheminBarre(Rect barre, double barTop) {
    final fond = Path()
      ..addRRect(RRect.fromRectAndRadius(
        barre,
        const Radius.circular(AppRadius.xl),
      ));

    final nr = geo.notchRadius;
    final dx = math.sqrt(nr * nr - geo.lift * geo.lift);
    final profondeur = nr - geo.lift;
    final encoche = Path()
      ..moveTo(cx - dx, barTop)
      ..cubicTo(
        cx - dx,
        barTop + _kappa * profondeur,
        cx - _kappa * dx,
        barTop + profondeur,
        cx,
        barTop + profondeur,
      )
      ..cubicTo(
        cx + _kappa * dx,
        barTop + profondeur,
        cx + dx,
        barTop + _kappa * profondeur,
        cx + dx,
        barTop,
      )
      ..close();

    return Path.combine(PathOperation.difference, fond, encoche);
  }

  @override
  bool shouldRepaint(_BarPainter old) =>
      cx != old.cx ||
      geo != old.geo ||
      scheme != old.scheme ||
      palette != old.palette ||
      brightness != old.brightness;
}
