import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../core/favorites.dart';
import '../../core/supabase_client.dart';
import '../../models/address.dart';
import '../../models/landmark.dart';
import '../../models/route_step.dart';
import '../address_create/address_form_screen.dart';
import 'widgets/landmark_form_sheet.dart';
import 'widgets/route_step_form_sheet.dart';

class AddressDetailScreen extends StatefulWidget {
  final String addressId;

  const AddressDetailScreen({super.key, required this.addressId});

  @override
  State<AddressDetailScreen> createState() => _AddressDetailScreenState();
}

class _AddressDetailScreenState extends State<AddressDetailScreen> {
  Address? _address;
  List<Landmark> _landmarks = [];
  List<RouteStep> _steps = [];
  bool _isFavorite = false;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final addressRow = await supabase
          .from('addresses')
          .select()
          .eq('id', widget.addressId)
          .single();

      final landmarkRows = await supabase
          .from('landmarks')
          .select()
          .eq('address_id', widget.addressId)
          .order('position_order');

      final stepRows = await supabase
          .from('route_steps')
          .select()
          .eq('address_id', widget.addressId)
          .order('step_order');

      final favorite = await isFavorite(widget.addressId);

      setState(() {
        _address = Address.fromJson(addressRow);
        _landmarks = (landmarkRows as List).map((r) => Landmark.fromJson(r)).toList();
        _steps = (stepRows as List).map((r) => RouteStep.fromJson(r)).toList();
        _isFavorite = favorite;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<bool> _confirm(String title, String message) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton.tonal(
            style: FilledButton.styleFrom(
              foregroundColor: Colors.red,
              backgroundColor: Colors.red.shade50,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  Future<void> _deleteAddress() async {
    if (!await _confirm(
      'Supprimer cette adresse ?',
      'Cette action est irréversible : "${_address!.name}" et toutes ses '
          'données associées (repères, étapes, favoris, liens de partage) '
          'seront supprimés.',
    )) return;

    try {
      await supabase.from('addresses').delete().eq('id', _address!.id!);
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Erreur : $e')));
      }
    }
  }

  Future<void> _deleteLandmark(Landmark l) async {
    if (!await _confirm('Supprimer ce repère ?', '"${l.name}" sera supprimé.')) return;
    await supabase.from('landmarks').delete().eq('id', l.id!);
    _loadAll();
  }

  Future<void> _deleteStep(RouteStep s) async {
    if (!await _confirm('Supprimer cette étape ?', 'L\'étape sera supprimée.')) return;
    await supabase.from('route_steps').delete().eq('id', s.id!);
    _loadAll();
  }

  /// Bascule l'étoile : l'icône change immédiatement, l'écriture en base
  /// suit. En cas d'échec on restaure l'état précédent et on prévient.
  Future<void> _toggleFavorite() async {
    final previous = _isFavorite;
    setState(() => _isFavorite = !previous);

    try {
      await toggleFavorite(_address!.id!, previous);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isFavorite = previous);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Erreur : $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_error != null) {
      return Scaffold(body: Center(child: Text('Erreur : $_error')));
    }

    final address = _address!;
    // Seul le propriétaire voit les actions de modification. La RLS protège
    // déjà le serveur, mais l'interface ne doit pas non plus proposer des
    // actions interdites à un simple visiteur (public ou autorisé en lecture).
    final isOwner = address.ownerId == supabase.auth.currentUser?.id;

    return Scaffold(
      appBar: AppBar(
        title: Text(address.name),
        actions: [
          IconButton(
            icon: Icon(_isFavorite ? Icons.star : Icons.star_outline),
            tooltip: _isFavorite ? 'Retirer des favoris' : 'Ajouter aux favoris',
            color: _isFavorite ? Colors.amber : null,
            onPressed: _toggleFavorite,
          ),
          if (isOwner) ...[
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: 'Modifier',
              onPressed: () async {
                await context.push<bool>('/address/${address.id}/edit', extra: address);
                _loadAll();
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Supprimer',
              onPressed: _deleteAddress,
            ),
          ],
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
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
            const SizedBox(height: 16),
          ],
          // ---- Infos générales ----
          Row(
            children: [
              Icon(
                address.visibility == AddressVisibility.public
                    ? Icons.public
                    : Icons.lock,
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(address.visibility == AddressVisibility.public ? 'Publique' : 'Privée'),
              const SizedBox(width: 16),
              Icon(
                address.gpsType == GpsType.exact ? Icons.gps_fixed : Icons.route,
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(address.gpsType == GpsType.exact ? 'Position exacte' : "Point d'accès"),
            ],
          ),
          const SizedBox(height: 16),
          if (address.locality != null) ...[
            Text('Localité', style: Theme.of(context).textTheme.titleSmall),
            Text(address.locality!),
            const SizedBox(height: 16),
          ],
          if (address.description != null) ...[
            Text('Description', style: Theme.of(context).textTheme.titleSmall),
            Text(address.description!),
            const SizedBox(height: 16),
          ],
          Text('Coordonnées GPS', style: Theme.of(context).textTheme.titleSmall),
          Text('${address.latitude.toStringAsFixed(6)}, ${address.longitude.toStringAsFixed(6)}'),
          const SizedBox(height: 12),
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
                    // La politique d'usage d'OpenStreetMap exige de
                    // s'identifier : doit correspondre à l'applicationId
                    // déclaré dans android/app/build.gradle.kts.
                    userAgentPackageName: 'com.example.carnet_adresses_repere',
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
                      // Repères qui ont eux-mêmes des coordonnées GPS (optionnel).
                      ..._landmarks
                          .where((l) => l.latitude != null && l.longitude != null)
                          .map(
                            (l) => Marker(
                              point: LatLng(l.latitude!, l.longitude!),
                              width: 36,
                              height: 36,
                              child: const Icon(
                                Icons.place,
                                color: Colors.blue,
                                size: 30,
                              ),
                            ),
                          ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Divider(),

          // ---- Repères ----
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Repères', style: Theme.of(context).textTheme.titleMedium),
              if (isOwner)
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  tooltip: 'Ajouter un repère',
                  onPressed: () async {
                    final ok = await showLandmarkFormSheet(context, addressId: address.id!);
                    if (ok == true) _loadAll();
                  },
                ),
            ],
          ),
          if (_landmarks.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('Aucun repère pour le moment.', style: TextStyle(color: Colors.grey)),
            )
          else
            ..._landmarks.map((l) => Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundImage: l.photoUrl != null ? NetworkImage(l.photoUrl!) : null,
                      child: l.photoUrl == null ? const Icon(Icons.place) : null,
                    ),
                    title: Text(l.name),
                    subtitle: l.description != null ? Text(l.description!) : null,
                    trailing: isOwner
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, size: 20),
                                onPressed: () async {
                                  final ok = await showLandmarkFormSheet(
                                    context,
                                    addressId: address.id!,
                                    existing: l,
                                  );
                                  if (ok == true) _loadAll();
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 20),
                                onPressed: () => _deleteLandmark(l),
                              ),
                            ],
                          )
                        : null,
                  ),
                )),

          const SizedBox(height: 16),
          const Divider(),

          // ---- Étapes ----
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Étapes du trajet', style: Theme.of(context).textTheme.titleMedium),
              if (isOwner)
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  tooltip: 'Ajouter une étape',
                  onPressed: () async {
                    final ok = await showRouteStepFormSheet(
                      context,
                      addressId: address.id!,
                      landmarks: _landmarks,
                      nextStepOrder: _steps.length + 1,
                    );
                    if (ok == true) _loadAll();
                  },
                ),
            ],
          ),
          if (_steps.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('Aucune étape pour le moment.', style: TextStyle(color: Colors.grey)),
            )
          else
            ..._steps.map((s) {
              final matches = _landmarks.where((l) => l.id == s.landmarkId);
              final landmark = matches.isEmpty ? null : matches.first;
              return Card(
                child: ListTile(
                  leading: CircleAvatar(child: Text('${s.stepOrder}')),
                  title: Text(s.instruction),
                  subtitle: Text([
                    if (s.distance != null) '${s.distance!.toStringAsFixed(0)} m',
                    if (s.direction != null) s.direction!,
                    if (landmark != null) 'Repère : ${landmark.name}',
                  ].join(' · ')),
                  trailing: isOwner
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, size: 20),
                              onPressed: () async {
                                final ok = await showRouteStepFormSheet(
                                  context,
                                  addressId: address.id!,
                                  landmarks: _landmarks,
                                  nextStepOrder: _steps.length + 1,
                                  existing: s,
                                );
                                if (ok == true) _loadAll();
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 20),
                              onPressed: () => _deleteStep(s),
                            ),
                          ],
                        )
                      : null,
                ),
              );
            }),
        ],
      ),
    );
  }
}