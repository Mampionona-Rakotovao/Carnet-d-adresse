import 'package:flutter/material.dart';
import '../core/theme/app_spacing.dart';
import '../models/address.dart';

/// Vocabulaire visuel partagé pour les deux notions clés du carnet :
/// la visibilité d'une adresse et son type de localisation.
///
/// Les libellés sont définis une seule fois : c'est ce qui évite que le détail,
/// la liste, la recherche et le partage n'affichent la même information
/// différemment.
extension GpsTypeUi on GpsType {
  String get label => this == GpsType.exact ? 'Position exacte' : "Point d'accès";

  String get shortLabel => this == GpsType.exact ? 'GPS' : 'Repère';

  IconData get icon => this == GpsType.exact ? Icons.gps_fixed : Icons.route;

  /// Phrase courte expliquant la différence, réutilisée partout.
  String get explanation => this == GpsType.exact
      ? "L'adresse correspond directement aux coordonnées GPS : on peut s'y rendre sans repère supplémentaire."
      : "Les coordonnées désignent le dernier point atteignable. Les repères et les étapes expliquent ensuite comment rejoindre le lieu.";
}

extension AddressVisibilityUi on AddressVisibility {
  String get label =>
      this == AddressVisibility.public ? 'Publique' : 'Privée';

  IconData get icon =>
      this == AddressVisibility.public ? Icons.public : Icons.lock_outline;

  String get explanation => this == AddressVisibility.public
      ? "Visible par les autres utilisateurs de l'application, et partageable."
      : "Visible uniquement par vous. Vous pouvez la partager via un lien.";
}

/// Pastille de statut (visibilité ou type de position).
///
/// L'information n'est jamais portée par la couleur seule : une icône ET un
/// texte l'accompagnent systématiquement.
class AppStatusChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final bool dense;

  const AppStatusChip({
    super.key,
    required this.icon,
    required this.label,
    this.color,
    this.dense = false,
  });

  factory AppStatusChip.visibility(AddressVisibility visibility, {bool dense = false}) {
    return AppStatusChip(
      icon: visibility.icon,
      label: visibility.label,
      dense: dense,
    );
  }

  factory AppStatusChip.gpsType(GpsType gpsType, {bool dense = false}) {
    return AppStatusChip(
      icon: gpsType.icon,
      label: gpsType.label,
      dense: dense,
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final foreground = color ?? scheme.onSurfaceVariant;
    final background = (color ?? scheme.onSurfaceVariant).withValues(alpha: 0.09);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? AppSpacing.xs : AppSpacing.sm,
        vertical: dense ? 3 : AppSpacing.xxs + 1,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: AppRadius.fieldRadius,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: dense ? 13 : 15, color: foreground),
          const SizedBox(width: AppSpacing.xxs + 1),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: (dense
                      ? Theme.of(context).textTheme.labelSmall
                      : Theme.of(context).textTheme.labelMedium)
                  ?.copyWith(color: foreground, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
