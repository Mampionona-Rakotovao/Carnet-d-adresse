import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../../ui/app_background.dart';
import '../../ui/app_bottom_nav.dart';

/// Onglet d'accueil : tableau de bord affiché en premier dans la barre.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('Bienvenue')),
      body: AppBackground(
        style: AppBackgroundStyle.releve,
        child: ListView(
          padding: AppSpacing.list.copyWith(
            bottom: AppBottomNav.hauteurTotale(context) + AppSpacing.md,
          ),
          children: [
            Text(
              'Bienvenue',
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              'Votre tableau de bord arrive ici.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
