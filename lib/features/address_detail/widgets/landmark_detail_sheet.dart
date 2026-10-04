import 'package:flutter/material.dart';
import '../../../models/landmark.dart';
import '../../../models/route_step.dart';

/// Résultat renvoyé par [showLandmarkDetailSheet] quand l'utilisateur
/// demande une action plutôt que de fermer simplement le feuillet.
const landmarkDetailEdit = 'edit';
const landmarkDetailDelete = 'delete';
const landmarkDetailStepPrefix = 'step:';
String landmarkDetailStep(String stepId) => '$landmarkDetailStepPrefix$stepId';

/// Ouvre en lecture le détail d'un repère : photo, description,
/// coordonnées et les étapes du trajet qui pointent vers ce repère.
///
/// Renvoie l'action demandée (`edit`, `delete` ou `step:<id>`), ou null si
/// l'utilisateur a simplement refermé le feuillet. Les actions de
/// modification sont proposées au seul propriétaire ([isOwner]).
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
    builder: (ctx) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Repère', style: Theme.of(ctx).textTheme.labelLarge),
            const SizedBox(height: 4),
            Text(landmark.name, style: Theme.of(ctx).textTheme.titleLarge),
            const SizedBox(height: 16),
            if (landmark.photoUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  landmark.photoUrl!,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            if (landmark.description != null) ...[
              const SizedBox(height: 16),
              Text('Description', style: Theme.of(ctx).textTheme.titleSmall),
              Text(landmark.description!),
            ],
            const SizedBox(height: 16),
            Text('Coordonnées GPS', style: Theme.of(ctx).textTheme.titleSmall),
            Text(
              landmark.latitude != null && landmark.longitude != null
                  ? '${landmark.latitude!.toStringAsFixed(6)}, '
                        '${landmark.longitude!.toStringAsFixed(6)}'
                  : 'Non renseignées',
            ),
            const SizedBox(height: 16),
            Text('Ordre', style: Theme.of(ctx).textTheme.titleSmall),
            Text('Position ${landmark.positionOrder + 1} dans le trajet'),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            Text(
              'Étapes associées',
              style: Theme.of(ctx).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            if (relatedSteps.isEmpty)
              const Text(
                'Aucune étape ne renvoie vers ce repère.',
                style: TextStyle(color: Colors.grey),
              )
            else
              ...relatedSteps.map(
                (s) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(child: Text('${s.stepOrder}')),
                  title: Text(s.instruction),
                  subtitle: Text(
                    [
                      if (s.distance != null)
                        '${s.distance!.toStringAsFixed(0)} m',
                      if (s.direction != null) s.direction!,
                    ].join(' · '),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () =>
                      Navigator.of(ctx).pop(landmarkDetailStep(s.id!)),
                ),
              ),
            if (isOwner) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.tonalIcon(
                      onPressed: () =>
                          Navigator.of(ctx).pop(landmarkDetailEdit),
                      icon: const Icon(Icons.edit),
                      label: const Text('Modifier'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        foregroundColor: Colors.red,
                        backgroundColor: Colors.red.shade50,
                      ),
                      onPressed: () =>
                          Navigator.of(ctx).pop(landmarkDetailDelete),
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Supprimer'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    ),
  );
}