import 'package:flutter/material.dart';
import '../core/theme/app_spacing.dart';
import 'app_feedback.dart';

/// Indicateur de chargement centré, avec une zone de taille stable pour que
/// la mise en page ne saute pas quand les données arrivent.
class AppLoading extends StatelessWidget {
  final String? message;

  const AppLoading({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            height: 32,
            width: 32,
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
          if (message != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              message!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Message d'erreur avec une action « Réessayer ».

class AppErrorState extends StatelessWidget {
  final Object? error;
  final String? title;
  final String? message;
  final VoidCallback? onRetry;

  const AppErrorState({
    super.key,
    this.error,
    this.title = 'Impossible de charger les données',
    this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final detail = error == null ? null : debugErrorDetail(error!);
    if (detail != null) debugPrint('AppErrorState → $detail');

    return AppStateLayout(
      icon: Icons.cloud_off_outlined,
      iconColor: scheme.error,
      title: title!,
      message: message ??
          (error == null
              ? 'Vérifiez votre connexion, puis réessayez.'
              : friendlyErrorMessage(error!)),
      detail: detail,
      action: onRetry == null
          ? null
          : AppStateAction(
              label: 'Réessayer',
              icon: Icons.refresh,
              onPressed: onRetry!,
            ),
    );
  }
}

/// Liste vide : toujours un message utile + une action qui débloque l'écran.
class AppEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final IconData? actionIcon;
  final VoidCallback? onAction;
  final Widget? secondaryAction;

  const AppEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.actionIcon,
    this.onAction,
    this.secondaryAction,
  });

  @override
  Widget build(BuildContext context) => AppStateLayout(
        icon: icon,
        title: title,
        message: message,
        action: (actionLabel != null && onAction != null)
            ? AppStateAction(
                label: actionLabel!,
                icon: actionIcon ?? Icons.add,
                onPressed: onAction!,
              )
            : null,
        secondaryAction: secondaryAction,
      );
}

/// Ossature commune : icône, titre, message, action. Le contenu est centré et
/// borné en largeur pour rester lisible sur un grand écran comme sur un petit.
class AppStateLayout extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String title;
  final String message;
  final String? detail;
  final Widget? action;
  final Widget? secondaryAction;

  const AppStateLayout({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.iconColor,
    this.detail,
    this.action,
    this.secondaryAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final color = iconColor ?? scheme.primary;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 40, color: color),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                message,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              if (detail != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  detail!,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelSmall,
                ),
              ],
              if (action != null) ...[
                const SizedBox(height: AppSpacing.lg),
                ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 200, maxWidth: 320),
                  child: action,
                ),
              ],
              if (secondaryAction != null) ...[
                const SizedBox(height: AppSpacing.xs),
                secondaryAction!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Bouton d'action d'un état (remplace les SizedBox(height: 100) + Center).
class AppStateAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  const AppStateAction({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) =>
      FilledButton.icon(onPressed: onPressed, icon: Icon(icon), label: Text(label));
}
