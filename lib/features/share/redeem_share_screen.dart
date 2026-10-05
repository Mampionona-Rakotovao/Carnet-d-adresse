import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../core/supabase_client.dart';
import '../../models/address.dart';
import '../../models/landmark.dart';
import '../../models/route_step.dart';
import '../../core/theme/app_spacing.dart';

/// Écran où un destinataire colle un code/lien de partage reçu.
/// Toute la vérification (existence, expiration, révocation) se fait
/// côté serveur via la fonction SQL get_shared_address_full — jamais
/// fait confiance au client (RG20, RG21, RG22).
class RedeemShareScreen extends StatefulWidget {
  const RedeemShareScreen({super.key});

  @override
  State<RedeemShareScreen> createState() => _RedeemShareScreenState();
}

class _RedeemShareScreenState extends State<RedeemShareScreen> {
  final _controller = TextEditingController();
  bool _loading = false;
  String? _error;
  Address? _address;
  List<Landmark> _landmarks = [];
  List<RouteStep> _steps = [];

  String _extractToken(String input) {
    final trimmed = input.trim();
    if (trimmed.contains('/')) return trimmed.split('/').last;
    return trimmed;
  }

  Future<void> _verify() async {
    final token = _extractToken(_controller.text);
    if (token.isEmpty) return;

    setState(() {
      _loading = true;
      _error = null;
      _address = null;
      _landmarks = [];
      _steps = [];
    });

    try {
      final result = await supabase
          .rpc('get_shared_address_full', params: {'p_token': token});

      if (result == null) {
        setState(() => _error =
            'Lien invalide, expiré ou révoqué. Vérifie le code ou demande un nouveau lien au propriétaire.');
        return;
      }

      final data = result as Map<String, dynamic>;
      final address = Address.fromJson(data['address'] as Map<String, dynamic>);
      final landmarks = (data['landmarks'] as List)
          .map((r) => Landmark.fromJson(r as Map<String, dynamic>))
          .toList();
      final steps = (data['steps'] as List)
          .map((r) => RouteStep.fromJson(r as Map<String, dynamic>))
          .toList();

      setState(() {
        _address = address;
        _landmarks = landmarks;
        _steps = steps;
      });
    } catch (e) {
      setState(() => _error = 'Erreur : $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ouvrir un lien')),
      body: ListView(
        padding: AppSpacing.form,
        children: [
          TextField(
            controller: _controller,
            decoration: const InputDecoration(
              labelText: 'Code ou lien reçu',
              border: OutlineInputBorder(),
              hintText: 'Ex: 8f3c2a1b9d4e...',
            ),
            onSubmitted: (_) => _verify(),
          ),
          const SizedBox(height: AppSpacing.sm),
          FilledButton(
            onPressed: _loading ? null : _verify,
            child: _loading
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Vérifier'),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (_error != null)
            Card(
              color: Colors.red.shade50,
              child: Padding(
                padding: AppSpacing.form,
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red),
                    const SizedBox(width: 12),
                    Expanded(child: Text(_error!)),
                  ],
                ),
              ),
            ),
          if (_address != null) ..._buildAddressView(_address!),
        ],
      ),
    );
  }

  List<Widget> _buildAddressView(Address address) {
    return [
      Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(address.name, style: Theme.of(context).textTheme.titleLarge),
          ),
        ],
      ),
      const SizedBox(height: AppSpacing.xs),
      if (address.description != null) ...[
        Text(address.description!),
        const SizedBox(height: AppSpacing.sm),
      ],
      if (address.locality != null) ...[
        Text('Localité', style: Theme.of(context).textTheme.titleSmall),
        Text(address.locality!),
        const SizedBox(height: AppSpacing.sm),
      ],
      Row(
        children: [
          Icon(address.gpsType == GpsType.exact ? Icons.gps_fixed : Icons.route, size: 18),
          const SizedBox(width: 6),
          Text(address.gpsType == GpsType.exact ? 'Position exacte' : "Point d'accès"),
        ],
      ),
      const SizedBox(height: AppSpacing.sm),
      ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          height: 200,
          child: FlutterMap(
            options: MapOptions(
              initialCenter: LatLng(address.latitude, address.longitude),
              initialZoom: 16,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.carnet_adresses.repere',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: LatLng(address.latitude, address.longitude),
                    width: 40,
                    height: 40,
                    child: Icon(
                      address.gpsType == GpsType.exact ? Icons.location_on : Icons.flag,
                      color: Colors.red,
                      size: 34,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: AppSpacing.lg),

      if (_landmarks.isNotEmpty) ...[
        const Divider(),
        Text('Repères', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppSpacing.xs),
        ..._landmarks.map((l) => Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundImage: l.photoUrl != null ? NetworkImage(l.photoUrl!) : null,
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
        Text('Étapes du trajet', style: Theme.of(context).textTheme.titleMedium),
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