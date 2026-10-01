import 'dart:async';
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
  StreamSubscription<List<Map<String, dynamic>>>? _subscription;
  List<Address> _addresses = [];
  bool _loading = true;
  String? _error;

  /// Flux temps réel : Postgres notifie Supabase Realtime à chaque
  /// insert/update/delete sur "addresses", qui pousse la donnée via
  /// websocket. Le cache interne du flux est reconstruit à chaque
  /// resouscription (voir [_resubscribe]) pour repartir de la base.
  Stream<List<Map<String, dynamic>>> _addressesStream() => supabase
      .from('addresses')
      .stream(primaryKey: ['id'])
      .eq('owner_id', supabase.auth.currentUser!.id)
      .order('created_at', ascending: false);

  @override
  void initState() {
    super.initState();
    _subscribe();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void _subscribe() {
    _subscription?.cancel();
    _subscription = _addressesStream().listen(
      (rows) {
        if (!mounted) return;
        setState(() {
          _addresses = rows.map(Address.fromJson).toList();
          _loading = false;
          _error = null;
        });
      },
      onError: (Object e) {
        if (!mounted) return;
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      },
    );
  }

  /// Relit la liste depuis la base via un flux neuf.
  ///
  /// Utilisé au retour d'un écran qui a pu modifier les données
  /// (création, modification, suppression) : le temps réel ne transmet
  /// pas les événements DELETE quand le filtre porte sur une colonne
  /// qui n'est pas la clé primaire (owner_id), donc la liste doit être
  /// resynchronisée explicitement.
  Future<void> _resubscribe() async {
    _subscribe();
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
      body: _buildBody(user?.email),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await context.push<bool>('/address/create');
          await _resubscribe();
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody(String? email) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return ListView(
        children: [
          const SizedBox(height: 100),
          Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
          const SizedBox(height: 12),
          Center(child: Text('Erreur : $_error')),
        ],
      );
    }

    if (_addresses.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 100),
          const Icon(Icons.map_outlined, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            'Connecté en tant que ${email ?? "?"}',
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
      itemCount: _addresses.length,
      itemBuilder: (context, index) {
        final a = _addresses[index];
        return Card(
          child: ListTile(
            onTap: () async {
              await context.push('/address/${a.id}');
              // L'écran de détail a pu supprimer l'adresse : on
              // resynchronise pour qu'elle disparaisse de la liste.
              await _resubscribe();
            },
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
  }
}