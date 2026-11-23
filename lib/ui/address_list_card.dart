import 'package:flutter/material.dart';

import '../core/theme/app_spacing.dart';
import '../models/address.dart';
import 'status_chip.dart';

/// Carte compacte d'adresse, réutilisée dans les listes (accueil, bienvenue).
class AddressListCard extends StatelessWidget {
  const AddressListCard({
    super.key,
    required this.address,
    required this.onTap,
    this.actions,
  });

  final Address address;
  final VoidCallback onTap;

  /// Menu d'actions (« ⋮ ») facultatif. Quand il est fourni, il remplace la
  /// flèche de fin de carte ; l'appui sur la carte continue d'ouvrir la fiche.
  final Widget? actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final subtitleParts = <String>[];
    if (address.locality != null && address.locality!.isNotEmpty) {
      subtitleParts.add(address.locality!);
    }
    subtitleParts.add(address.gpsType.label);

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.cardRadius,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: scheme.primaryContainer,
                foregroundColor: scheme.onPrimaryContainer,
                backgroundImage: address.photoUrl != null
                    ? NetworkImage(address.photoUrl!)
                    : null,
                child: address.photoUrl == null
                    ? Icon(
                        address.visibility == AddressVisibility.public
                            ? Icons.public
                            : Icons.lock_outline,
                      )
                    : null,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      address.name,
                      style: theme.textTheme.titleMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subtitleParts.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        subtitleParts.join(' · '),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xxs,
                      children: [
                        AppStatusChip.gpsType(address.gpsType, dense: true),
                        AppStatusChip.visibility(
                          address.visibility,
                          dense: true,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              if (actions != null)
                actions!
              else
                Icon(
                  Icons.chevron_right,
                  color: scheme.onSurfaceVariant,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
