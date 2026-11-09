import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'app_states.dart';

/// Écran affiché par go_router quand aucune route ne correspond à l'URL.
class NotFoundPage extends StatelessWidget {
  const NotFoundPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Page introuvable')),
      body: AppEmptyState(
        icon: Icons.link_off,
        title: 'Page introuvable',
        message: 'Cette page n’existe pas ou a été déplacée.',
        actionLabel: 'Retour',
        actionIcon: Icons.arrow_back,
        onAction: () => context.canPop() ? context.pop() : context.go('/'),
      ),
    );
  }
}
