import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../../core/navigation_launcher.dart';
import '../../core/route_service.dart';
import '../../widgets/carte_widget.dart';

class NavigationScreen extends StatefulWidget {
  const NavigationScreen({super.key, required this.destination, this.nom});

  final LatLng destination;
  final String? nom;

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> {
  static const _dist = Distance();

  final MapController _map = MapController();
  StreamSubscription<Position>? _sub;

  RouteResult? _route;
  LatLng? _pos;
  int _next = 1; // index de la prochaine manœuvre (0 = départ)
  bool _loading = true;
  bool _arrived = false;
  bool _suivre = true;
  String? _erreur;
  DateTime _dernierRecalcul = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void initState() {
    super.initState();
    _demarrer();
  }

  @override
  void dispose() {
    _sub?.cancel();
    _map.dispose();
    super.dispose();
  }

  Future<void> _demarrer() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return _echec('Activez le GPS pour démarrer le guidage.');
    }
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied ||
        perm == LocationPermission.deniedForever) {
      return _echec('Autorisez la localisation pour démarrer le guidage.');
    }

    try {
      final p = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
          timeLimit: Duration(seconds: 20),
        ),
      );
      _pos = LatLng(p.latitude, p.longitude);
    } catch (_) {
      return _echec('Impossible de récupérer votre position actuelle.');
    }

    if (!await _calculer()) {
      return _echec('Aucun itinéraire trouvé. Essayez le bouton Naviguer.');
    }

    if (!mounted) return;
    setState(() => _loading = false);

    _sub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 5, // mise à jour tous les 5 m
      ),
    ).listen(_onPosition);
  }

  void _echec(String message) {
    if (!mounted) return;
    setState(() {
      _erreur = message;
      _loading = false;
    });
  }

  Future<bool> _calculer() async {
    final route = await RouteService.getRoute(_pos!, widget.destination);
    if (route == null || route.steps.isEmpty) return false;
    if (!mounted) return false;
    setState(() {
      _route = route;
      _next = route.steps.length > 1 ? 1 : 0;
    });
    return true;
  }

  void _onPosition(Position p) {
    if (!mounted || _route == null || _arrived) return;
    final pos = LatLng(p.latitude, p.longitude);
    final steps = _route!.steps;

    // Manœuvre franchie ?
    while (_next < steps.length - 1 &&
        _dist.as(LengthUnit.Meter, pos, steps[_next].location) < 25) {
      _next++;
    }

    // Arrivée ?
    if (_dist.as(LengthUnit.Meter, pos, widget.destination) < 30) {
      setState(() {
        _pos = pos;
        _arrived = true;
      });
      return;
    }

    setState(() => _pos = pos);

    if (_suivre) {
      try {
        _map.move(pos, 17);
      } catch (_) {}
    }

    // Hors itinéraire ? On recalcule (au plus une fois toutes les 15 s).
    if (_ecartItineraire(pos) > 60 &&
        DateTime.now().difference(_dernierRecalcul).inSeconds > 15) {
      _dernierRecalcul = DateTime.now();
      _calculer();
    }
  }

  double _ecartItineraire(LatLng pos) {
    double min = double.infinity;
    for (final pt in _route!.points) {
      final d = _dist.as(LengthUnit.Meter, pos, pt);
      if (d < min) min = d;
    }
    return min;
  }

  double get _distanceRestante {
    final steps = _route!.steps;
    double total = _dist.as(LengthUnit.Meter, _pos!, steps[_next].location);
    for (var i = _next + 1; i < steps.length; i++) {
      total += steps[i].distanceMeters;
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_erreur != null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_erreur!, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () => ouvrirNavigation(widget.destination),
                  icon: const Icon(Icons.map),
                  label: const Text('Ouvrir dans Google Maps'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final route = _route!;
    final step = route.steps[_next];
    final restante = _distanceRestante;
    final dureeRestante = route.distanceMeters == 0
        ? 0.0
        : route.durationSeconds * restante / route.distanceMeters;
    final minutes = (dureeRestante / 60).ceil();
    final versManoeuvre = _dist.as(LengthUnit.Meter, _pos!, step.location);

    return Scaffold(
      body: Stack(
        children: [
          CarteWidget(
            centre: _pos!,
            zoom: 17,
            controller: _map,
            polylines: [
              Polyline(
                  points: route.points, strokeWidth: 6, color: Colors.blue),
            ],
            marqueurs: [
              Marker(
                point: widget.destination,
                width: 40,
                height: 40,
                child:
                    const Icon(Icons.location_pin, color: Colors.red, size: 40),
              ),
              Marker(
                point: _pos!,
                width: 36,
                height: 36,
                child:
                    const Icon(Icons.navigation, color: Colors.blue, size: 32),
              ),
            ],
            onMapEvent: (event) {
              if (event.source == MapEventSource.onDrag && _suivre) {
                setState(() => _suivre = false);
              }
            },
          ),

          // Bannière : prochaine manœuvre
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: Card(
                margin: const EdgeInsets.all(12),
                color: scheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Icon(Icons.turn_right,
                          size: 32, color: scheme.onPrimaryContainer),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _arrived
                              ? 'Vous êtes arrivé'
                              : '${step.instruction}\ndans ${formatDistance(versManoeuvre)}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: scheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Barre du bas : reste à parcourir + quitter
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              child: Card(
                margin: const EdgeInsets.all(12),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _arrived
                              ? (widget.nom ?? 'Destination atteinte')
                              : '${formatDistance(restante)} • $minutes min',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ),
                      FilledButton.tonal(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(_arrived ? 'Terminer' : 'Quitter'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: _suivre
          ? null
          : Padding(
              padding: const EdgeInsets.only(bottom: 80),
              child: FloatingActionButton.small(
                heroTag: null,
                onPressed: () {
                  setState(() => _suivre = true);
                  _map.move(_pos!, 17);
                },
                child: const Icon(Icons.my_location),
              ),
            ),
    );
  }
}
