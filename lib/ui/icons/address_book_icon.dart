import 'package:flutter/material.dart';

/// Carnet à spirale avec une épingle de localisation, dessiné en code.
///
/// Vectoriel, proportionnel à [size], sans image ni dépendance. En contour
/// (repos) seuls les traits sont peints ; en version pleine ([filled]), la page
/// est remplie et l'épingle est découpée en négatif avec [Path.combine], pour
/// rester lisible dans la bulle bleue de l'onglet actif.
class AddressBookIcon extends StatelessWidget {
  const AddressBookIcon({
    super.key,
    required this.size,
    required this.color,
    this.filled = false,
  });

  /// Fabriques adaptées aux `iconBuilder` de `AppBottomNavItem`.
  static Widget outline(Color color, double size) =>
      AddressBookIcon(size: size, color: color);

  static Widget solid(Color color, double size) =>
      AddressBookIcon(size: size, color: color, filled: true);

  final double size;
  final Color color;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          isComplex: false,
          painter: _AddressBookPainter(
            color: color,
            filled: filled,
            compact: size <= 24,
          ),
        ),
      ),
    );
  }
}

class _AddressBookPainter extends CustomPainter {
  const _AddressBookPainter({
    required this.color,
    required this.filled,
    required this.compact,
  });

  final Color color;
  final bool filled;
  final bool compact;

  /// Coordonnées de référence : tous les chemins sont tracés dans 24 × 24.
  static const double _ref = 24;

  /// Cache des chemins : un seul calcul par variante (compacte ou non).
  static final Map<bool, _Chemins> _cache = {};

  @override
  void paint(Canvas canvas, Size size) {
    final c = _cache.putIfAbsent(compact, () => _Chemins(compact));
    canvas.save();
    canvas.scale(size.width / _ref, size.height / _ref);

    if (filled) {
      // Une seule forme remplie : page moins épingle (découpe positive),
      // puis traits de contour et anneaux. Aucun BlendMode global, donc le
      // fond reste intact et l'épingle est vraiment « en négatif ».
      final plein = Paint()
        ..color = color
        ..style = PaintingStyle.fill;
      canvas.drawPath(c.pageEtEpingleDecoupee, plein);
      canvas.drawPath(c.anneauxPleins, plein);
    } else {
      final trait = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      canvas.drawPath(c.contour, trait);
      canvas.drawPath(c.anneaux, trait);
      canvas.drawPath(c.epingle, trait);
      trait.style = PaintingStyle.fill;
      canvas.drawCircle(c.centrePoint, 1.0, trait);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_AddressBookPainter old) =>
      old.color != color || old.filled != filled || old.compact != compact;
}

/// Chemins dans la boîte de référence 24 × 24, calculés une seule fois.
class _Chemins {
  _Chemins(this.compact) {
    // Carnet vertical aux coins arrondis ; la page est assez large pour que
    // l'épingle découpée reste visible même à 22 dp.
    final carnet = RRect.fromRectAndRadius(
      const Rect.fromLTWH(4.8, 2.8, 14.4, 18.4),
      const Radius.circular(2.4),
    );
    contour = Path()..addRRect(carnet);

    // Épingle : goutte large, centrée sur la page, sans cercle autour.
    epingle = Path()
      ..moveTo(12.0, 16.0)
      ..cubicTo(9.2, 13.4, 9.2, 10.0, 11.2, 8.6)
      ..cubicTo(13.3, 7.0, 16.6, 8.4, 16.6, 11.0)
      ..cubicTo(16.6, 13.2, 15.0, 14.6, 13.4, 16.0)
      ..lineTo(12.0, 16.0)
      ..close();
    centrePoint = const Offset(13.0, 11.2);

    // Page pleine moins l'épingle, en une seule opération Path.combine.
    // Le défaut de 0.9 dp garde un liseré de contour tout autour.
    pageEtEpingleDecoupee = Path.combine(
      PathOperation.difference,
      Path()..addRRect(carnet.deflate(0.9)),
      epingle,
    );

    // 5 anneaux de reliure sur le bord gauche (demi-cercles débordants).
    anneaux = Path();
    anneauxPleins = Path();
    for (var i = 0; i < 5; i++) {
      final y = 6.0 + i * 3.0;
      anneaux
        ..moveTo(2.2, y + 1.0)
        ..quadraticBezierTo(0.7, y, 2.2, y - 1.0);
      anneauxPleins.addOval(
          Rect.fromCircle(center: Offset(2.5, y), radius: 1.15));
    }
  }

  final bool compact;
  late final Path contour;
  late final Path epingle;
  late final Offset centrePoint;
  late final Path pageEtEpingleDecoupee;
  late final Path anneaux;
  late final Path anneauxPleins;
}
