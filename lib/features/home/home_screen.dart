import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/supabase_client.dart';
import '../../models/address.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<Address>> _addressesFuture;

  @override
  void initState() {
    super.initState();
    _addressesFuture = _fetchMyAddresses();
  }

  /// Récupère les adresses appartenant à l'utilisateur connecté.
  /// (La recherche parmi toutes les adresses accessibles viendra
  /// à l'étape "recherche" — ici on affiche juste "mes adresses".)
  Future<List<Address>> _fetchMyAddresses() async {
    final userId = supabase.auth.currentUser!.id;
    final data = await supabase
        .from('addresses')
        .select()
        .eq('owner_id', userId)
        .order('created_at', ascending: false);

    return (data as List).map((row) => Address.fromJson(row)).toList();
  }

  Future<void> _refresh() async {
    setState(() => _addressesFuture = _fetchMyAddresses());
    await _addressesFuture;
  }

  @override
  Widget build(BuildContext context) {
    final user = supabase.auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes adresses'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Se déconnecter',
            onPressed: () async {
              await supabase.auth.signOut();
              // go_router redirige automatiquement vers /login.
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<Address>>(
          future: _addressesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return ListView(
                children: [
                  const SizedBox(height: 100),
                  Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
                  const SizedBox(height: 12),
                  Center(child: Text('Erreur : ${snapshot.error}')),
                ],
              );
            }

            final addresses = snapshot.data ?? [];

            if (addresses.isEmpty) {
              return ListView(
                children: [
                  const SizedBox(height: 100),
                  const Icon(Icons.map_outlined, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    'Connecté en tant que ${user?.email ?? "?"}',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Aucune adresse pour le moment.\nAppuie sur + pour en créer une.",
                    textAlign: TextAlign.center,
                  ),
                ],
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: addresses.length,
              itemBuilder: (context, index) {
                final a = addresses[index];
                return Card(
                  child: ListTile(
                    leading: Icon(
                      a.visibility == AddressVisibility.public
                          ? Icons.public
                          : Icons.lock,
                    ),
                    title: Text(a.name),
                    subtitle: Text(
                      [
                        if (a.locality != null) a.locality!,
                        a.gpsType == GpsType.exact
                            ? 'Position exacte'
                            : "Point d'accès",
                      ].join(' · '),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final created = await context.push<bool>('/address/create');
          if (created == true && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Adresse enregistrée !')),
            );
            _refresh();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}