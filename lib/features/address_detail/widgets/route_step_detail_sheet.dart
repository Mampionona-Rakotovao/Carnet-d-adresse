import 'package:flutter/material.dart';
import '../../../models/landmark.dart';
import '../../../models/route_step.dart';

/// Résultat renvoyé par [showRouteStepDetailSheet] quand l'utilisateur
/// demande une action plutôt que de fermer simplement le feuillet.
const routeStepDetailEdit = 'edit';
const routeStepDetailDelete = 'delete';
const routeStepDetailLandmark = 'landmark';

/// Ouvre en lecture le détail d'une étape : instruction, distance,
/// direction et le repère associé (cliquable pour ouvrir son propre détail).
///
/// Renvoie l'action demandée (`edit`, `delete` ou `landmark`), ou null si
/// l'utilisateur a simplement refermé le feuillet. Les actions de
/// modification sont proposées au seul propriétaire ([isOwner]).
Future<String?> showRouteStepDetailSheet(
  BuildContext context, {
  required RouteStep step,
  required Landmark? landmark,
  required bool isOwner,
}) {
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
            Text(
              'Étape ${step.stepOrder}',
              style: Theme.of(ctx).textTheme.labelLarge,
            ),
            const SizedBox(height: 4),
            Text(step.instruction, style: Theme.of(ctx).textTheme.titleLarge),
            const SizedBox(height: 16),
            if (step.distance != null || step.direction != null) ...[
              Text('Trajet', style: Theme.of(ctx).textTheme.titleSmall),
              Text(
                [
                  if (step.distance != null)
                    '${step.distance!.toStringAsFixed(0)} m',
                  if (step.direction != null) step.direction!,
                ].join(' · '),
              ),
              const SizedBox(height: 16),
            ],
            const Divider(),
            const SizedBox(height: 8),
            Text('Repère associé', style: Theme.of(ctx).textTheme.titleSmall),
            const SizedBox(height: 8),
            if (landmark == null)
              const Text(
                "Cette étape n'est liée à aucun repère.",
                style: TextStyle(color: Colors.grey),
              )
            else
              Card(
                margin: EdgeInsets.zero,
                clipBehavior: Clip.antiAlias,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage:
                        landmark.photoUrl != null
                            ? NetworkImage(landmark.photoUrl!)
                            : null,
                    child:
                        landmark.photoUrl == null
                            ? const Icon(Icons.place)
                            : null,
                  ),
                  title: Text(landmark.name),
                  subtitle: landmark.description != null
                      ? Text(
                        landmark.description!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      )
                      : null,
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(ctx).pop(routeStepDetailLandmark),
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
                          Navigator.of(ctx).pop(routeStepDetailEdit),
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
                          Navigator.of(ctx).pop(routeStepDetailDelete),
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