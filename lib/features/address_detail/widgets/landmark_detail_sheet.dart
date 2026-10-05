import 'package:flutter/material.dart';
import '../../../models/landmark.dart';
import '../../../models/route_step.dart';
import 'detail_widgets.dart';

/// Préfixe des actions portant sur le repère lui-même.
const landmarkDetailEdit = 'edit';
const landmarkDetailDelete = 'delete';

/// Préfixe des actions portant sur une des étapes associées au repère.
/// Le suffixe est l'id de l'étape concernée.
const landmarkDetailStepEditPrefix = 'step-edit:';
const landmarkDetailStepDeletePrefix = 'step-delete:';

String landmarkDetailStepEdit(String stepId) =>
    '$landmarkDetailStepEditPrefix$stepId';

String landmarkDetailStepDelete(String stepId) =>
    '$landmarkDetailStepDeletePrefix$stepId';

/// Ouvre le détail complet d'un repère : tout son contenu plus les étapes du
/// trajet qui lui correspondent, affichées en entier.
///
/// Renvoie l'action demandée (`edit`, `delete`, `step-edit:<id>` ou
/// `step-delete:<id>`), ou null si l'utilisateur a simplement refermé le
/// feuillet. Les actions ne sont proposées qu'au propriétaire ([isOwner]).
Future<String?> showLandmarkDetailSheet(
  BuildContext context, {
  required Landmark landmark,
  required List<RouteStep> steps,
  required bool isOwner,
}) {
  final relatedSteps =
      steps.where((s) => s.landmarkId == landmark.id).toList();

  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => DetailSheetBody(
      footer: isOwner
          ? DetailActionBar(
              editLabel: 'Modifier le repère',
              onEdit: () => Navigator.of(ctx).pop(landmarkDetailEdit),
              onDelete: () => Navigator.of(ctx).pop(landmarkDetailDelete),
            )
          : null,
      children: [
        _LandmarkCard(landmark),
        const SizedBox(height: 24),
        SectionLabel(
          icon: Icons.route,
          text: relatedSteps.length > 1
              ? 'Étapes associées (${relatedSteps.length})'
              : 'Étape associée',
        ),
        const SizedBox(height: 12),
        if (relatedSteps.isEmpty)
          const Text(
            'Aucune étape ne renvoie vers ce repère.',
            style: TextStyle(color: Colors.grey),
          )
        else
          ...relatedSteps.map(
            (s) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: StepCard(
                step: s,
                isOwner: isOwner,
                onEdit: () =>
                    Navigator.of(ctx).pop(landmarkDetailStepEdit(s.id!)),
                onDelete: () =>
                    Navigator.of(ctx).pop(landmarkDetailStepDelete(s.id!)),
              ),
            ),
          ),
      ],
    ),
  );
}

/// Carte du repère : photo, nom, description et informations GPS.
class _LandmarkCard extends StatelessWidget {
  final Landmark landmark;

  const _LandmarkCard(this.landmark);

  @override
  Widget build(BuildContext context) {
    final hasGps = landmark.latitude != null && landmark.longitude != null;

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (landmark.photoUrl != null)
            Image.network(
              landmark.photoUrl!,
              height: 190,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionLabel(icon: Icons.place, text: 'Repère'),
                const SizedBox(height: 8),
                Text(
                  landmark.name,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                if (landmark.description != null) ...[
                  const SizedBox(height: 8),
                  Text(landmark.description!),
                ],
                const SizedBox(height: 12),
                InfoRow(
                  icon:
                      hasGps ? Icons.my_location : Icons.location_off_outlined,
                  text: hasGps
                      ? '${landmark.latitude!.toStringAsFixed(6)}, '
                            '${landmark.longitude!.toStringAsFixed(6)}'
                      : 'Coordonnées non renseignées',
                ),
                InfoRow(
                  icon: Icons.low_priority,
                  text:
                      'Position ${landmark.positionOrder + 1} dans le trajet',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}