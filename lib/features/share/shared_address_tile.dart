import 'package:flutter/material.dart';
import '../../core/theme/app_spacing.dart';
import '../../models/shared_address.dart';
import '../../ui/status_chip.dart';

/// Ligne d'une adresse reçue par lien partagé.
///
/// Utilisée par la liste « Partagées avec moi » et par la section équivalente
/// de l'accueil : un seul rendu, donc les mêmes informations et le même
/// compte à rebours aux deux endroits. La destination d'un appui est portée
/// par [onTap] : l'écran des partages ouvre l'adresse en mode détail chez
/// lui, l'accueil y conduit par la route.
class SharedAddressTile extends StatelessWidget {
  const SharedAddressTile({
    super.key,
    required this.entry,
    required this.onTap,
  });

  final SharedAddressEntry entry;
  final VoidCallback onTap;

  /// Couleur du compte à rebours : rien tant qu'il reste du temps, puis
  /// attention quand la fin approche. L'information reste aussi portée par le
  /// texte du libellé, jamais par la couleur seule.
  Color? _expiryColor(ThemeData theme) {
    if (entry.isExpired) return theme.colorScheme.error;
    if (entry.timeLeft.inHours < 1) return Colors.orange;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final subtitle = <String>[
      if (entry.locality != null && entry.locality!.isNotEmpty)
        entry.locality!,
      if (entry.sharedByName != null && entry.sharedByName!.isNotEmpty)
        'Partagé par ${entry.sharedByName}',
    ].join(' · ');

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.cardRadius,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xs,
            vertical: AppSpacing.xxs,
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: scheme.primaryContainer,
                foregroundColor: scheme.onPrimaryContainer,
                backgroundImage: entry.photoUrl != null
                    ? NetworkImage(entry.photoUrl!)
                    : null,
                child: entry.photoUrl == null
                    ? const Icon(Icons.share_location, size: 22)
                    : null,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.name,
                      style: theme.textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              AppStatusChip(
                icon: Icons.timer_outlined,
                label: entry.expiryLabel,
                color: _expiryColor(theme),
                dense: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
