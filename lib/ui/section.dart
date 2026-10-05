import 'package:flutter/material.dart';
import '../core/theme/app_spacing.dart';

/// En-tête de section : un titre lisible, une icône discrète et une action
/// facultative à droite. Remplace les `Text(titleMedium)` isolés qui
/// structuraient mal les écrans longs.
class SectionHeader extends StatelessWidget {
  final String title;
  final IconData? icon;
  final String? subtitle;
  final Widget? trailing;

  const SectionHeader({
    super.key,
    required this.title,
    this.icon,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: AppSpacing.xs),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: theme.textTheme.titleMedium),
              if (subtitle != null)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    subtitle!,
                    style: theme.textTheme.bodySmall,
                  ),
                ),
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

/// Bloc de formulaire : un titre de section + un texte d'explication, dans une
/// carte qui regroupe visuellement les champs concernés.
class FormSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final String? description;
  final List<Widget> children;

  const FormSection({
    super.key,
    required this.title,
    required this.icon,
    this.description,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SectionHeader(title: title, icon: icon),
            if (description != null) ...[
              const SizedBox(height: AppSpacing.xxs),
              Text(
                description!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            ..._withGaps(children),
          ],
        ),
      ),
    );
  }

  /// Intercale un espacement cohérent entre les champs sansmanage le premier
  /// et le dernier.
  static List<Widget> _withGaps(List<Widget> items) {
    final result = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      if (i > 0) result.add(const SizedBox(height: AppSpacing.md));
      result.add(items[i]);
    }
    return result;
  }
}

/// Titre de groupe de formulaire, affiché entre deux [FormSection].
class FormGroupLabel extends StatelessWidget {
  final String text;

  const FormGroupLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.xs, top: AppSpacing.xs),
        child: Text(
          text.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                letterSpacing: 1.1,
                color: Theme.of(context).colorScheme.primary,
              ),
        ),
      );
}
