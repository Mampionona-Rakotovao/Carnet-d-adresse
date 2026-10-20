import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../core/supabase_client.dart';
import '../../core/theme/app_spacing.dart';
import '../../models/address.dart';
import '../../models/landmark.dart';
import '../../models/route_step.dart';
import '../../ui/app_states.dart';

/// Affichage en lecture seule d'une adresse reçue par lien partagé.
///
/// Le widget porte tout le chargement : un [token] → fonction SQL
/// `get_shared_address_full`, qui contrôle côté serveur l'existence,
/// l'expiration et la révocation du lien (RG20-RG22). Le client n'affiche
/// que ce que le serveur renvoie.
///
/// Conçu pour occuper tout le corps d'un écran (états de chargement et
/// d'erreur pleine page) : « Partagées avec moi » et « Adresse partagée »
/// chacun le montrent dans leur propre Scaffold. Une vue imbriquée dans un
/// `ListView` doit donc être construite à part, comme le fait
/// `RedeemShareScreen`.
class SharedAddressView extends StatefulWidget {
  const SharedAddressView({
    super.key,
    required this.token,
    this.notFoundMessage =
        'Lien invalide, expiré ou révoqué. Demande un nouveau lien au propriétaire.',
  });

  final String token;

  /// Message affiché quand le serveur ne renvoie rien (lien mort).
  final String notFoundMessage;

  @override
  State<SharedAddressView> createState() => _SharedAddressViewState();
}

class _SharedAddressViewState extends State<SharedAddressView> {
  bool _loading = true;

  /// Message affichable tel quel (lien introuvable), ou `null`.
  String? _message;

  /// Exception réseau ou autre : traduite par [AppErrorState].
  Object? _exception;

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
      _message = null;
      _exception = null;
    });

    try {
      final result = await supabase.rpc(
        'get_shared_address_full',
        params: {'p_token': widget.token},
      );

      if (result == null) {
        if (mounted) setState(() => _message = widget.notFoundMessage);
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

      if (mounted) {
        setState(() {
          _address = address;
          _landmarks = landmarks;
          _steps = steps;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _exception = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const AppLoading();

    final message = _message;
    final exception = _exception;
    if (message != null || exception != null) {
      return AppErrorState(
        message: message,
        error: exception,
        onRetry: _load,
      );
    }

    return ListView(
      padding: AppSpacing.form,
      children: _buildAddressView(_address!),
    );
  }

  List<Widget> _buildAddressView(Address address) {
    final theme = Theme.of(context);
    return [
      Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(address.name, style: theme.textTheme.titleLarge)),
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
                      address.gpsType == GpsType.exact
                          ? Icons.location_on
                          : Icons.flag,
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
