import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

/// Marqueur lisible sur plan comme sur satellite : pastille blanche, icône
/// colorée et ombre très légère.
class AppMapMarker extends StatelessWidget {
  const AppMapMarker({
    super.key,
    required this.icon,
    required this.color,
    this.size = 30,
  });

  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.darkNavy.withValues(alpha: 0.18),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Icon(icon, color: color, size: size),
    );
  }
}
