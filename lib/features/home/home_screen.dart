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
  late final Stream<List<Map<String, dynamic>>> _addressesStream;

  @override
  void initState() {
    super.initState();
    final userId = supabase.auth.currentUser!.id;

    // Flux temps réel : Postgres notifie Supabase Realtime à chaque
    // insert/update/delete sur "addresses", qui pousse la donnée via
    // websocket. Plus besoin de rafraîchir manuellement après création.
    _addressesStream = supabase
        .from('addresses')
        .stream(primaryKey: ['id'])
        .eq('owner_id', userId)
        .order('created_at', ascending: false);
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
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _addressesStream,
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

          final addresses =
              (snapshot.data ?? []).map((row) => Address.fromJson(row)).toList();

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
                  onTap: () => context.push('/address/${a.id}'),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await context.push<bool>('/address/create');
          // Pas besoin de vérifier le retour ni d'appeler un refresh :
          // dès que l'insert Supabase réussit, le stream pousse la
          // nouvelle donnée tout seul et l'UI se reconstruit.
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}