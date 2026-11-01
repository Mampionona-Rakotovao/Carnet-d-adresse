import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../models/address.dart';
import '../../../models/landmark.dart';
import '../../../models/route_step.dart';
import '../../../ui/section.dart';
import '../../../ui/status_chip.dart';
import '../../address_detail/widgets/detail_widgets.dart';
import '../../address_detail/widgets/landmark_detail_sheet.dart';
import '../../address_detail/widgets/trajet_widgets.dart';

/// Contenu complet d'une adresse reçue par lien, en lecture seule.
///
/// Affiche la photo, les informations, la carte avec les repères, les boutons
/// de trajet, la liste des repères et les étapes du trajet.
class SharedAddressContent extends StatelessWidget {
  const SharedAddressContent({
    super.key,
    required this.address,
    required this.landmarks,
    required this.steps,
  });

  final Address address;
  final List<Landmark> landmarks;
  final List<RouteStep> steps;

  Future<void> _openLandmark(BuildContext context, Landmark landmark) {
    final hasGps = landmark.latitude != null && landmark.longitude != null;
    return showLandmarkDetailSheet(
      context,
      landmark: landmark,
      steps: steps,
      isOwner: false,
      afficherTrajet: hasGps,
      destination:
          hasGps ? LatLng(landmark.latitude!, landmark.longitude!) : null,
      nom: landmark.name,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final destination = LatLng(address.latitude, address.longitude);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (address.photoUrl != null) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: Image.network(
              address.photoUrl!,
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        Text(address.name, style: theme.textTheme.headlineSmall),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xxs,
          children: [
            AppStatusChip.gpsType(address.gpsType, dense: true),
          ],
        ),
        if (address.locality != null) ...[
          const SizedBox(height: AppSpacing.md),
          Text('Localité', style: theme.textTheme.titleSmall),
          Text(address.locality!),
        ],
        if (address.description != null) ...[
          const SizedBox(height: AppSpacing.md),
          Text('Description', style: theme.textTheme.titleSmall),
          Text(address.description!),
        ],
        const SizedBox(height: AppSpacing.md),
        Text('Coordonnées GPS', style: theme.textTheme.titleSmall),
        Text(
          '${address.latitude.toStringAsFixed(6)}, '
          '${address.longitude.toStringAsFixed(6)}',
        ),
        const SizedBox(height: AppSpacing.md),
        TrajetSection(
          destination: destination,
          nom: address.name,
          landmarks: landmarks,
          markerIcon:
              address.gpsType == GpsType.exact ? Icons.location_on : Icons.flag,
          onLandmarkTap: (landmark) => _openLandmark(context, landmark),
        ),
        const SizedBox(height: AppSpacing.lg),
        const Divider(),
        const SizedBox(height: AppSpacing.sm),
        const SectionHeader(title: 'Repères', icon: Icons.place),
        const SizedBox(height: AppSpacing.sm),
        if (landmarks.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: Text('Aucun repère', style: TextStyle(color: Colors.grey)),
          )
        else
          ...landmarks.map(
            (landmark) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: LandmarkCard(
                landmark: landmark,
                onTap: () => _openLandmark(context, landmark),
              ),
            ),
          ),
        const SizedBox(height: AppSpacing.md),
        const Divider(),
        const SizedBox(height: AppSpacing.sm),
        const SectionHeader(title: 'Étapes du trajet', icon: Icons.route),
        const SizedBox(height: AppSpacing.sm),
        if (steps.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: Text('Aucune étape', style: TextStyle(color: Colors.grey)),
          )
        else
          ...steps.map(
            (step) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: StepCard(step: step),
            ),
          ),
      ],
    );
  }
}
