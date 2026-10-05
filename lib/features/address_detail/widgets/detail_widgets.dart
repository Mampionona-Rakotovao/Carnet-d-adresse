import 'package:flutter/material.dart';
import '../../../models/route_step.dart';

/// Intitulé de section : sert à séparer visuellement le bloc « repère » du
/// bloc « étape ».
class SectionLabel extends StatelessWidget {
  final IconData icon;
  final String text;

  const SectionLabel({super.key, required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Row(
      children: [
        Icon(icon, size: 16, color: primary),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context)
                .textTheme
                .labelLarge
                ?.copyWith(color: primary, letterSpacing: 0.4),
          ),
        ),
      ],
    );
  }
}

/// Ligne d'information : icône discrète + texte.
class InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const InfoRow({super.key, required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodySmall),
          ),
        ],
      ),
    );
  }
}

/// Pastille d'information (distance, direction).
class DetailChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const DetailChip({super.key, required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade400),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey.shade700),
          const SizedBox(width: 4),
          Text(text, style: Theme.of(context).textTheme.labelMedium),
        ],
      ),
    );
  }
}

/// Carte d'une étape du trajet : trait d'accent à gauche pour la distinguer
/// du repère, instruction en titre, informations de trajet en pastilles et
/// menu d'actions pour le propriétaire.
class StepCard extends StatelessWidget {
  final RouteStep step;
  final bool isOwner;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const StepCard({
    super.key,
    required this.step,
    this.isOwner = false,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final accent = colors.tertiary;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Trait d'accent : signal visuel que ce bloc est une étape.
            Container(
              width: 5,
              decoration: BoxDecoration(
                color: accent,
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(12),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 13,
                          backgroundColor: accent,
                          child: Text(
                            '${step.stepOrder}',
                            style: TextStyle(
                              fontSize: 13,
                              color: colors.onTertiary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Étape ${step.stepOrder}',
                            style: Theme.of(context)
                                .textTheme
                                .labelLarge
                                ?.copyWith(color: accent),
                          ),
                        ),
                        if (isOwner)
                          PopupMenuButton<String>(
                            padding: EdgeInsets.zero,
                            iconSize: 20,
                            tooltip: 'Actions sur l\'étape',
                            onSelected: (v) =>
                                v == 'edit' ? onEdit?.call() : onDelete?.call(),
                            itemBuilder: (ctx) => const [
                              PopupMenuItem(
                                value: 'edit',
                                child: ListTile(
                                  leading: Icon(Icons.edit),
                                  title: Text('Modifier l\'étape'),
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: ListTile(
                                  leading: Icon(
                                    Icons.delete_outline,
                                    color: Colors.red,
                                  ),
                                  title: Text(
                                    'Supprimer l\'étape',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      step.instruction,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    if (step.distance != null || step.direction != null) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
if (step.distance != null)
                            DetailChip(
                              icon: Icons.straighten,
                              text: '${step.distance!.toStringAsFixed(0)} m',
                            ),
                        if (step.direction != null)
                          DetailChip(
                            icon: Icons.navigation,
                            text: step.direction!,
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Barre d'actions fixée en bas du feuillet : elle reste visible même quand
/// le contenu au-dessus défile. Le bouton de suppression est réduit à une
/// icône pour laisser la place à l'action principale.
class DetailActionBar extends StatelessWidget {
  final String editLabel;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const DetailActionBar({
    super.key,
    required this.editLabel,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit),
                  label: Text(editLabel),
                ),
              ),
              const SizedBox(width: 12),
              IconButton.filledTonal(
                onPressed: onDelete,
                style: IconButton.styleFrom(
                  foregroundColor: Colors.red,
                  backgroundColor: Colors.red.shade50,
                ),
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Supprimer',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Corps de feuillet défilant, borné à 90 % de la hauteur de l'écran pour que
/// les contenus longs restent lisibles sur les petits écrans.
class DetailSheetBody extends StatelessWidget {
  final List<Widget> children;
  final Widget? footer;

  const DetailSheetBody({super.key, required this.children, this.footer});

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: height * 0.9),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: children,
                ),
              ),
            ),
            if (footer != null) footer!,
          ],
        ),
      ),
    );
  }
}