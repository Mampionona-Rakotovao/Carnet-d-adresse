import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

const String maptilerKey = String.fromEnvironment('7FILHIWIDgFyqkLSLOeK ');

class CarteWidget extends StatefulWidget {
  const CarteWidget({
    super.key,
    required this.centre,
    this.zoom = 16,
    this.marqueurs = const [],
    this.onTap,
    this.controller,
  });

  final LatLng centre;
  final double zoom;
  final List<Marker> marqueurs;
  final void Function(LatLng point)? onTap;
  final MapController? controller;

  @override
  State<CarteWidget> createState() => _CarteWidgetState();
}

class _CarteWidgetState extends State<CarteWidget> {
  bool _satellite = true; // vue réelle par défaut

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
          ),
          children: [
            TileLayer(
              urlTemplate:
                  'https://api.maptiler.com/maps/$style/{z}/{x}/{y}.$ext?key=$maptilerKey',
              userAgentPackageName: 'com.example.carnet_adresses_repere',
              maxNativeZoom: 17,
              retinaMode: RetinaMode.isHighDensity(context),
            ),
            MarkerLayer(markers: widget.marqueurs),
            const RichAttributionWidget(
              attributions: [
                TextSourceAttribution('© MapTiler'),
                TextSourceAttribution('© OpenStreetMap contributors'),
              ],
            ),
          ],
        ),
        Positioned(
          top: 12,
          right: 12,
          child: FloatingActionButton.small(
            heroTag: null,
            onPressed: () => setState(() => _satellite = !_satellite),
            child: Icon(_satellite ? Icons.map : Icons.satellite_alt),
          ),
        ),
      ],
    );
  }
}