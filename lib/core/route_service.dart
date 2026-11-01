import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class RouteStep {
  final String instruction;
  final double distanceMeters; // longueur de ce tronçon
  final LatLng location; // endroit de la manœuvre

  const RouteStep({
    required this.instruction,
    required this.distanceMeters,
    required this.location,
  });
}

class RouteResult {
  final List<LatLng> points;
  final List<RouteStep> steps;
  final double distanceMeters;
  final double durationSeconds;

  const RouteResult({
    required this.points,
    required this.steps,
    required this.distanceMeters,
    required this.durationSeconds,
  });

  String get distanceText => formatDistance(distanceMeters);

  String get durationText {
    final min = (durationSeconds / 60).round();
    if (min < 60) return '$min min';
    return '${min ~/ 60} h ${min % 60} min';
  }
}

String formatDistance(double m) =>
    m >= 1000 ? '${(m / 1000).toStringAsFixed(1)} km' : '${m.round()} m';

String _instruction(String type, String? modifier, String name) {
  final rue = name.isEmpty ? '' : ' sur $name';
  switch (type) {
    case 'depart':
      return 'Démarrez$rue';
    case 'arrive':
      return 'Vous arrivez à destination';
    case 'roundabout':
    case 'rotary':
    case 'roundabout turn':
      return 'Au rond-point, prenez la sortie$rue';
  }
  final dir = switch (modifier) {
    'left' => 'Tournez à gauche',
    'right' => 'Tournez à droite',
    'slight left' => 'Serrez légèrement à gauche',
    'slight right' => 'Serrez légèrement à droite',
    'sharp left' => 'Tournez franchement à gauche',
    'sharp right' => 'Tournez franchement à droite',
    'uturn' => 'Faites demi-tour',
    _ => 'Continuez tout droit',
  };
  return '$dir$rue';
}

class RouteService {
  /// Retourne null si aucun itinéraire n'est trouvé ou en cas d'erreur réseau.
  static Future<RouteResult?> getRoute(LatLng from, LatLng to) async {
    // OSRM attend l'ordre longitude,latitude.
    final url = Uri.parse(
      'https://router.project-osrm.org/route/v1/driving/'
      '${from.longitude},${from.latitude};${to.longitude},${to.latitude}'
      '?overview=full&geometries=geojson&steps=true',
    );

    try {
      final res = await http.get(url).timeout(const Duration(seconds: 15));
      if (res.statusCode != 200) return null;

      final data = jsonDecode(res.body) as Map<String, dynamic>;
      if (data['code'] != 'Ok') return null;

      final route = (data['routes'] as List).first as Map<String, dynamic>;
      final coords = (route['geometry']['coordinates'] as List)
          .map(
              (c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()))
          .toList();

      final steps = <RouteStep>[];
      for (final leg in route['legs'] as List) {
        for (final s in (leg['steps'] as List)) {
          final m = s['maneuver'] as Map<String, dynamic>;
          final loc = m['location'] as List;
          steps.add(RouteStep(
            instruction: _instruction(
              m['type'] as String,
              m['modifier'] as String?,
              (s['name'] as String?) ?? '',
            ),
            distanceMeters: (s['distance'] as num).toDouble(),
            location:
                LatLng((loc[1] as num).toDouble(), (loc[0] as num).toDouble()),
          ));
        }
      }

      return RouteResult(
        points: coords,
        steps: steps,
        distanceMeters: (route['distance'] as num).toDouble(),
        durationSeconds: (route['duration'] as num).toDouble(),
      );
    } catch (_) {
      return null;
    }
  }
}
