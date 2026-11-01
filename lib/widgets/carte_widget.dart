import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Clé fournie à la compilation :
/// flutter run --dart-define=MAPTILER_KEY=votre_cle
/// Ne jamais écrire la clé en dur dans le code ni la commiter.
const String maptilerKey = String.fromEnvironment('MAPTILER_KEY');

class CarteWidget extends StatefulWidget {
  const CarteWidget({
    super.key,
    required this.centre,
    this.zoom = 16,
    this.marqueurs = const [],
    this.polylines = const [],
    this.onTap,
    this.onMapEvent,
    this.controller,
    this.satellite,
    this.onSatelliteChanged,
    this.afficherBoutonBascule = true,
  });

  final LatLng centre;
  final double zoom;
  final List<Marker> marqueurs;
  final List<Polyline> polylines;
  final void Function(LatLng point)? onTap;
  final void Function(MapEvent event)? onMapEvent;
  final MapController? controller;

  /// Vue contrôlée par l'écran appelant. Si `null`, le widget gère lui-même
  /// la bascule satellite/plan.
  final bool? satellite;
  final ValueChanged<bool>? onSatelliteChanged;

  /// Permet à un écran qui possède déjà ses propres boutons « Map simple » /
  /// « Map satellite » de masquer le bouton interne.
  final bool afficherBoutonBascule;

  @override
  State<CarteWidget> createState() => _CarteWidgetState();
}

class _CarteWidgetState extends State<CarteWidget> {
  bool _satelliteInterne = true;

  bool get _satellite => widget.satellite ?? _satelliteInterne;

  void _basculer() {
    final valeur = !_satellite;
    if (widget.onSatelliteChanged != null) {
      widget.onSatelliteChanged!(valeur);
    } else {
      setState(() => _satelliteInterne = valeur);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (maptilerKey.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Clé MapTiler manquante.\n'
            'Lancez avec : --dart-define=MAPTILER_KEY=votre_cle',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final style = _satellite ? 'hybrid' : 'streets-v2';
    final ext = _satellite ? 'jpg' : 'png';

    return Stack(
      children: [
        FlutterMap(
          mapController: widget.controller,
          options: MapOptions(
            initialCenter: widget.centre,
            initialZoom: widget.zoom,
            minZoom: 3,
            maxZoom: 19,
            onTap: (tapPosition, point) => widget.onTap?.call(point),
            onMapEvent: widget.onMapEvent,
          ),
          children: [
            TileLayer(
              urlTemplate:
                  'https://api.maptiler.com/maps/$style/{z}/{x}/{y}.$ext?key=$maptilerKey',
              userAgentPackageName: 'com.example.carnet_adresses_repere',
              maxNativeZoom: 17,
              retinaMode: RetinaMode.isHighDensity(context),
            ),
            PolylineLayer(polylines: widget.polylines),
            MarkerLayer(markers: widget.marqueurs),
            const RichAttributionWidget(
              attributions: [
                TextSourceAttribution('© MapTiler'),
                TextSourceAttribution('© OpenStreetMap contributors'),
              ],
            ),
          ],
        ),
        if (widget.afficherBoutonBascule)
          Positioned(
            top: 12,
            right: 12,
            child: FloatingActionButton.small(
              heroTag: null,
              onPressed: _basculer,
              child: Icon(_satellite ? Icons.map : Icons.satellite_alt),
            ),
          ),
      ],
    );
  }
}
