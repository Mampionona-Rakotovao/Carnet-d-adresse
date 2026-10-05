import 'package:flutter/material.dart';
import '../../../models/landmark.dart';
import '../../../models/route_step.dart';
import 'detail_widgets.dart';

/// Résultat renvoyé par [showRouteStepDetailSheet] quand l'utilisateur
/// demande une action plutôt que de fermer simplement le feuillet.
const routeStepDetailEdit = 'edit';
const routeStepDetailDelete = 'delete';
const routeStepDetailLandmark = 'landmark';

/// Ouvre le détail d'une étape : instruction, distance, direction et le
/// repère associé (cliquable pour ouvrir son propre détail).
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
    builder: (ctx) => DetailSheetBody(
      footer: isOwner
          ? DetailActionBar(
              editLabel: 'Modifier l\'étape',
              onEdit: () => Navigator.of(ctx).pop(routeStepDetailEdit),
              onDelete: () => Navigator.of(ctx).pop(routeStepDetailDelete),
            )
          : null,
      children: [
        StepCard(step: step),
        const SizedBox(height: 24),
        const SectionLabel(icon: Icons.place, text: 'Repère associé'),
        const SizedBox(height: 12),
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
                    landmark.photoUrl == null ? const Icon(Icons.place) : null,
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
      ],
    ),
  );
}