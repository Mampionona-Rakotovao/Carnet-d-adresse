import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import '../../core/shared_with_me.dart';
import '../../core/supabase_client.dart';
import '../../core/theme/app_spacing.dart';
import '../../models/address.dart';
import '../../models/landmark.dart';
import '../../models/route_step.dart';
import '../../widgets/carte_widget.dart';

/// Écran ouvert par un lien partagé :
/// https://mampionona-rakotovao.github.io/a/<token>
/// La vérification (existence, expiration, révocation) reste côté serveur
/// via la fonction SQL get_shared_address_full.
class SharedLinkScreen extends StatefulWidget {
  const SharedLinkScreen({super.key, required this.token});

  final String token;

  @override
  State<SharedLinkScreen> createState() => _SharedLinkScreenState();
}

class _SharedLinkScreenState extends State<SharedLinkScreen> {
  bool _loading = true;
  String? _error;
  Address? _address;
  List<Landmark> _landmarks = [];
  List<RouteStep> _steps = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final result = await supabase.rpc(
        'get_shared_address_full',
        params: {'p_token': widget.token},
      );

      if (result == null) {
        if (mounted) {
          setState(() => _error =
              'Lien invalide, expiré ou révoqué. Demande un nouveau lien au propriétaire.');
        }
        return;
      }

      // Enregistre l'ouverture : l'adresse apparaîtra dans « Partagées avec
      // moi » tant que le lien est valide. Une erreur ici ne doit pas
      // empêcher l'affichage de l'adresse.
      await recordShareOpen(widget.token);

      final data = result as Map<String, dynamic>;
      final address = Address.fromJson(data['address'] as Map<String, dynamic>);
      final landmarks = (data['landmarks'] as List)
          .map((r) => Landmark.fromJson(r as Map<String, dynamic>))
          .toList();
      final steps = (data['steps'] as List)
          .map((r) => RouteStep.fromJson(r as Map<String, dynamic>))
          .toList();

      if (mounted) {
        setState(() {
          _address = address;
          _landmarks = landmarks;
          _steps = steps;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = 'Erreur : $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _goHome() => context.go('/');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Adresse partagée'),
        leading: IconButton(
          icon: const Icon(Icons.home_outlined),
          tooltip: 'Accueil',
          onPressed: _goHome,
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : ListView(
                  padding: AppSpacing.form,
                  children: _buildAddressView(_address!),
                ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: AppSpacing.form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: AppSpacing.sm),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.md),
            FilledButton(onPressed: _load, child: const Text('Réessayer')),
            TextButton(
                onPressed: _goHome, child: const Text("Retour à l'accueil")),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildAddressView(Address address) {
    final theme = Theme.of(context);
    return [
      Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 20),
          const SizedBox(width: 8),
          Expanded(
              child: Text(address.name, style: theme.textTheme.titleLarge)),
        ],
      ),
      const SizedBox(height: AppSpacing.xs),
      if (address.description != null) ...[
        Text(address.description!),
        const SizedBox(height: AppSpacing.sm),
      ],
      if (address.locality != null) ...[
        Text('Localité', style: theme.textTheme.titleSmall),
        Text(address.locality!),
        const SizedBox(height: AppSpacing.sm),
      ],
      Row(
        children: [
          Icon(address.gpsType == GpsType.exact ? Icons.gps_fixed : Icons.route,
              size: 18),
          const SizedBox(width: 6),
          Text(address.gpsType == GpsType.exact
              ? 'Position exacte'
              : "Point d'accès"),
        ],
      ),
      const SizedBox(height: AppSpacing.sm),
      ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          height: 220,
          child: CarteWidget(
            centre: LatLng(address.latitude, address.longitude),
            zoom: 16,
            marqueurs: [
              Marker(
                point: LatLng(address.latitude, address.longitude),
                width: 40,
                height: 40,
                child: Icon(
                  address.gpsType == GpsType.exact
                      ? Icons.location_on
                      : Icons.flag,
                  color: Colors.red,
                  size: 34,
                ),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: AppSpacing.lg),
      if (_landmarks.isNotEmpty) ...[
        const Divider(),
        Text('Repères', style: theme.textTheme.titleMedium),
        const SizedBox(height: AppSpacing.xs),
        ..._landmarks.map((l) => Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundImage:
                      l.photoUrl != null ? NetworkImage(l.photoUrl!) : null,
                  child: l.photoUrl == null ? const Icon(Icons.place) : null,
                ),
                title: Text(l.name),
                subtitle: l.description != null ? Text(l.description!) : null,
              ),
            )),
        const SizedBox(height: AppSpacing.xs),
      ],
      if (_steps.isNotEmpty) ...[
        const Divider(),
        Text('Étapes du trajet', style: theme.textTheme.titleMedium),
        const SizedBox(height: AppSpacing.xs),
        ..._steps.map((s) => Card(
              child: ListTile(
                leading: CircleAvatar(child: Text('${s.stepOrder}')),
                title: Text(s.instruction),
                subtitle: Text([
                  if (s.distance != null) '${s.distance!.toStringAsFixed(0)} m',
                  if (s.direction != null) s.direction!,
                ].join(' · ')),
              ),
            )),
      ],
    ];
  }
}
