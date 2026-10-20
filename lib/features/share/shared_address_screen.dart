import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import '../../core/supabase_client.dart';
import '../../core/theme/app_spacing.dart';
import '../../models/address.dart';
import '../../models/landmark.dart';
import '../../models/route_step.dart';

/// Page d'une adresse reçue par lien : lecture seule, aucun bouton de
/// modification. Elle se recharge depuis le serveur à chaque ouverture : si
/// le lien a été révoqué ou a expiré, la page n'est plus disponible.
class SharedAddressScreen extends StatefulWidget {
  final String linkId;

  const SharedAddressScreen({super.key, required this.linkId});

  @override
  State<SharedAddressScreen> createState() => _SharedAddressScreenState();
}

class _SharedAddressScreenState extends State<SharedAddressScreen> {
  Address? _address;
  List<Landmark> _landmarks = [];
  List<RouteStep> _steps = [];
  DateTime? _expiresAt;
  String? _sharedBy;

  bool _loading = true;
  bool _unavailable = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _unavailable = false;
      _error = null;
    });

    try {
      final result = await supabase.rpc(
        'get_shared_address_by_link',
        params: {'p_share_link_id': widget.linkId},
      );

      // null = lien révoqué, expiré, ou jamais ouvert par cet utilisateur.
      if (result == null) {
        setState(() => _unavailable = true);
        return;
      }

      final data = result as Map<String, dynamic>;
      setState(() {
        _address = Address.fromJson(data['address'] as Map<String, dynamic>);
        _landmarks = (data['landmarks'] as List)
            .map((r) => Landmark.fromJson(r as Map<String, dynamic>))
            .toList();
        _steps = (data['steps'] as List)
            .map((r) => RouteStep.fromJson(r as Map<String, dynamic>))
            .toList();
        _expiresAt = data['expires_at'] != null
            ? DateTime.parse(data['expires_at'] as String)
            : null;
        _sharedBy = data['shared_by'] as String?;
      });
    } catch (e) {
      setState(() => _error = 'Impossible de charger cette adresse.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _goBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/');
    }
  }

  String _expiryText(DateTime expiresAt) {
    final local = expiresAt.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return 'jusqu\'au ${two(local.day)}/${two(local.month)} '
        'à ${two(local.hour)}:${two(local.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_address?.name ?? 'Adresse partagée')),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_unavailable) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.link_off, size: 56, color: scheme.outline),
              const SizedBox(height: AppSpacing.md),
              Text(
                "Ce partage n'est plus disponible",
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Le lien a expiré ou a été révoqué par son propriétaire.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              FilledButton(onPressed: _goBack, child: const Text('Retour')),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.md),
              OutlinedButton(onPressed: _load, child: const Text('Réessayer')),
            ],
          ),
        ),
      );
    }

    final address = _address!;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        // ---- Bandeau « accès temporaire » ----
        Card(
          color: scheme.secondaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Icon(Icons.timer_outlined, color: scheme.onSecondaryContainer),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    [
                      'Accès temporaire',
                      if (_sharedBy != null) 'partagé par $_sharedBy',
                      if (_expiresAt != null) _expiryText(_expiresAt!),
                    ].join(' · '),
                    style: TextStyle(color: scheme.onSecondaryContainer),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        if (address.photoUrl != null) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              address.photoUrl!,
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],

        Row(
          children: [
            Icon(
              address.gpsType == GpsType.exact ? Icons.gps_fixed : Icons.route,
              size: 18,
            ),
            const SizedBox(width: 6),
            Text(address.gpsType == GpsType.exact
                ? 'Position exacte'
                : "Point d'accès"),
          ],
        ),
        const SizedBox(height: AppSpacing.md),

        if (address.locality != null) ...[
          Text('Localité', style: theme.textTheme.titleSmall),
          Text(address.locality!),
          const SizedBox(height: AppSpacing.md),
        ],
        if (address.description != null) ...[
          Text('Description', style: theme.textTheme.titleSmall),
          Text(address.description!),
          const SizedBox(height: AppSpacing.md),
        ],

        // ---- Carte ----
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
                      width: 44,
                      height: 44,
                      child: Icon(
                        address.gpsType == GpsType.exact
                            ? Icons.location_on
                            : Icons.flag,
                        color: Colors.red,
                        size: 38,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // ---- Repères ----
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
          const SizedBox(height: AppSpacing.sm),
        ],

        // ---- Étapes ----
        if (_steps.isNotEmpty) ...[
          const Divider(),
          Text('Étapes du trajet', style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          ..._steps.map((s) => Card(
                child: ListTile(
                  leading: CircleAvatar(child: Text('${s.stepOrder}')),
                  title: Text(s.instruction),
                  subtitle: Text([
                    if (s.distance != null)
                      '${s.distance!.toStringAsFixed(0)} m',
                    if (s.direction != null) s.direction!,
                  ].join(' · ')),
                ),
              )),
        ],
      ],
    );
  }
}