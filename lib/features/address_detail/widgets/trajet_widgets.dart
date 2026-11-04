import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/navigation_launcher.dart';
import '../../../core/route_service.dart' hide RouteStep;
import '../../../core/theme/app_spacing.dart';
import '../../../models/landmark.dart';
import '../../../ui/app_feedback.dart';
import '../../../widgets/carte_widget.dart';
import '../../../widgets/map_type_buttons.dart';
import '../../navigation/navigation_screen.dart';

/// Boutons de trajet communs au détail d'une adresse et au lien partagé.
///
/// Au repos, les boutons sont transparents. Un bouton ne se colore que
/// lorsque son action est active.
/// La position GPS n'est demandée qu'au clic sur « Itinéraire ».
class TrajetBoutons extends StatefulWidget {
  const TrajetBoutons({
    super.key,
    required this.destination,
    required this.nom,
    this.afficherNaviguer = true,
    this.onRouteChanged,
  });

  final LatLng destination;
  final String nom;
  final bool afficherNaviguer;
  final ValueChanged<RouteResult?>? onRouteChanged;

  @override
  State<TrajetBoutons> createState() => _TrajetBoutonsState();
}

class _TrajetBoutonsState extends State<TrajetBoutons> {
  bool _routeLoading = false;
  bool _guidageOuvert = false;
  bool _externeEnCours = false;
  RouteResult? _route;

  Future<LatLng?> _positionActuelle() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      if (mounted) {
        AppSnack.warning(
            context, 'Activez le GPS pour calculer un itinéraire.');
      }
      return null;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      if (mounted) {
        AppSnack.warning(
          context,
          'Autorisez la localisation pour calculer un itinéraire.',
        );
      }
      return null;
    }

    try {
      final p = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
          timeLimit: Duration(seconds: 20),
        ),
      );
      return LatLng(p.latitude, p.longitude);
    } catch (_) {
      if (mounted) {
        AppSnack.warning(context, 'Impossible de récupérer votre position.');
      }
      return null;
    }
  }

  Future<void> _calculerItineraire() async {
    if (_routeLoading) return;

    // 2e appui : on masque l'itinéraire.
    if (_route != null) {
      setState(() => _route = null);
      widget.onRouteChanged?.call(null);
      return;
    }

    setState(() => _routeLoading = true);
    try {
      final from = await _positionActuelle();
      if (from == null) return;

      final route = await RouteService.getRoute(from, widget.destination);
      if (!mounted) return;

      if (route == null) {
        AppSnack.warning(
          context,
          'Aucun itinéraire trouvé. Utilisez le bouton Naviguer.',
        );
        return;
      }
      setState(() => _route = route);
      widget.onRouteChanged?.call(route);
    } catch (e) {
      if (mounted) AppSnack.error(context, e);
    } finally {
      if (mounted) setState(() => _routeLoading = false);
    }
  }

  Future<void> _ouvrirGuidage() async {
    setState(() => _guidageOuvert = true);
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NavigationScreen(
          destination: widget.destination,
          nom: widget.nom,
        ),
      ),
    );
    // Retour dans l'écran d'adresse : le bouton redevient transparent.
    if (mounted) setState(() => _guidageOuvert = false);
  }

  Future<void> _naviguerExterne() async {
    setState(() => _externeEnCours = true);
    final ok = await ouvrirNavigation(widget.destination);
    if (!mounted) return;
    setState(() => _externeEnCours = false);
    if (!ok) {
      AppSnack.warning(context, "Impossible d'ouvrir Google Maps.");
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _TrajetBouton(
                label: 'Itinéraire',
                icon: Icons.alt_route,
                active: _route != null || _routeLoading,
                loading: _routeLoading,
                onPressed: _calculerItineraire,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _TrajetBouton(
                label: 'Guidage',
                icon: Icons.navigation,
                active: _guidageOuvert,
                onPressed: _ouvrirGuidage,
              ),
            ),
            if (widget.afficherNaviguer) ...[
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _TrajetBouton(
                  label: 'Naviguer',
                  icon: Icons.map_outlined,
                  active: _externeEnCours,
                  onPressed: _naviguerExterne,
                ),
              ),
            ],
          ],
        ),
        if (_route != null)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Row(
              children: [
                Icon(Icons.route, size: 18, color: scheme.primary),
                const SizedBox(width: 6),
                Text(
                  '${_route!.distanceText} • ${_route!.durationText}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Bouton de trajet : transparent avec contour au repos, coloré quand actif.
class _TrajetBouton extends StatelessWidget {
  const _TrajetBouton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.active = false,
    this.loading = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool active;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final Color fond = active ? scheme.primaryContainer : Colors.transparent;
    final Color texte = active ? scheme.onPrimaryContainer : scheme.onSurface;
    final Color bordure = active ? scheme.primary : scheme.outlineVariant;

    final radius = BorderRadius.circular(AppRadius.sm);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: fond,
        borderRadius: radius,
        border: Border.all(color: bordure, width: active ? 1.5 : 1),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: radius,
          onTap: loading ? null : onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Hauteur fixe : le bouton ne change pas de taille au chargement.
                SizedBox(
                  height: 24,
                  width: 24,
                  child: loading
                      ? Padding(
                          padding: const EdgeInsets.all(2),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: texte,
                          ),
                        )
                      : Icon(icon, size: 22, color: texte),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: texte,
                        fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Carte de l'adresse avec ses repères, la bascule plan/satellite et les
/// boutons de trajet. Utilisée par le détail d'adresse et par le lien partagé.
class TrajetSection extends StatefulWidget {
  const TrajetSection({
    super.key,
    required this.destination,
    required this.nom,
    this.landmarks = const [],
    this.onLandmarkTap,
    this.markerIcon = Icons.location_on,
    this.markerColor = Colors.red,
    this.hauteurCarte = 220,
  });

  final LatLng destination;
  final String nom;
  final List<Landmark> landmarks;
  final ValueChanged<Landmark>? onLandmarkTap;
  final IconData markerIcon;
  final Color markerColor;
  final double hauteurCarte;

  @override
  State<TrajetSection> createState() => _TrajetSectionState();
}

class _TrajetSectionState extends State<TrajetSection> {
  bool _satellite = true;
  RouteResult? _route;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          child: SizedBox(
            height: widget.hauteurCarte,
            child: Stack(
              children: [
                CarteWidget(
                  centre: widget.destination,
                  zoom: 16,
                  satellite: _satellite,
                  onSatelliteChanged: (value) =>
                      setState(() => _satellite = value),
                  afficherBoutonBascule: false,
                  polylines: _route == null
                      ? const []
                      : [
                          Polyline(
                            points: _route!.points,
                            strokeWidth: 6,
                            color: Colors.blue,
                          ),
                        ],
                  marqueurs: [
                    Marker(
                      point: widget.destination,
                      width: 44,
                      height: 44,
                      child: Icon(
                        widget.markerIcon,
                        color: widget.markerColor,
                        size: 38,
                      ),
                    ),
                    ...widget.landmarks
                        .where((l) => l.latitude != null && l.longitude != null)
                        .map(
                          (l) => Marker(
                            point: LatLng(l.latitude!, l.longitude!),
                            width: 36,
                            height: 36,
                            child: GestureDetector(
                              onTap: widget.onLandmarkTap == null
                                  ? null
                                  : () => widget.onLandmarkTap!(l),
                              child: const Icon(
                                Icons.place,
                                color: Colors.blue,
                                size: 30,
                              ),
                            ),
                          ),
                        ),
                  ],
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: MapTypeButtons(
                    satellite: _satellite,
                    onChanged: (value) => setState(() => _satellite = value),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        TrajetBoutons(
          destination: widget.destination,
          nom: widget.nom,
          onRouteChanged: (route) {
            if (mounted) setState(() => _route = route);
          },
        ),
      ],
    );
  }
}