import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/supabase_client.dart';
import '../../models/address.dart';
import '../address_create/address_form_screen.dart';

class AddressDetailScreen extends StatefulWidget {
  final String addressId;

  const AddressDetailScreen({super.key, required this.addressId});

  @override
  State<AddressDetailScreen> createState() => _AddressDetailScreenState();
}

class _AddressDetailScreenState extends State<AddressDetailScreen> {
  late Future<Address> _addressFuture;

  @override
  void initState() {
    super.initState();
    _addressFuture = _fetchAddress();
  }

  Future<Address> _fetchAddress() async {
    final row = await supabase
        .from('addresses')
        .select()
        .eq('id', widget.addressId)
        .single();
    return Address.fromJson(row);
  }

  Future<void> _confirmDelete(Address address) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer cette adresse ?'),
        content: Text(
          'Cette action est irréversible : "${address.name}" et toutes ses '
          'données associées (repères, étapes, favoris, liens de partage) '
          'seront supprimés.',
        ),
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

    if (confirmed != true) return;

    try {
      // owner_id = auth.uid() est vérifié côté RLS (addresses_delete_own) :
      // même une requête malveillante ne pourrait pas supprimer l'adresse
      // d'un autre utilisateur.
      await supabase.from('addresses').delete().eq('id', address.id!);
      if (mounted) context.pop(); // retour à la liste, mise à jour via Realtime
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la suppression : $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<Address>(
        future: _addressFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erreur : ${snapshot.error}'));
          }

          final address = snapshot.data!;

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                title: Text(address.name),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    tooltip: 'Modifier',
                    onPressed: () async {
                      await context.push<bool>(
                        '/address/${address.id}/edit',
                        extra: address,
                      );
                      // Le contenu se rafraîchit via Realtime ou en revenant ici ;
                      // on recharge quand même explicitement par simplicité.
                      setState(() => _addressFuture = _fetchAddress());
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    tooltip: 'Supprimer',
                    onPressed: () => _confirmDelete(address),
                  ),
                ],
              ),
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    Row(
                      children: [
                        Icon(
                          address.visibility == AddressVisibility.public
                              ? Icons.public
                              : Icons.lock,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          address.visibility == AddressVisibility.public
                              ? 'Publique'
                              : 'Privée',
                        ),
                        const SizedBox(width: 16),
                        Icon(
                          address.gpsType == GpsType.exact
                              ? Icons.gps_fixed
                              : Icons.route,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          address.gpsType == GpsType.exact
                              ? 'Position exacte'
                              : "Point d'accès",
                        ),
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
                    Text(
                      '${address.latitude.toStringAsFixed(6)}, '
                      '${address.longitude.toStringAsFixed(6)}',
                    ),
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 8),
                    const Text(
                      'Repères et étapes : à venir dans une prochaine étape.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}