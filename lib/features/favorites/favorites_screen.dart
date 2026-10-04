import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/favorites.dart';
import '../../core/supabase_client.dart';
import '../../models/address.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  late Future<List<Address>> _favoritesFuture;

  @override
  void initState() {
    super.initState();
    _favoritesFuture = _fetchFavorites();
  }

  Future<List<Address>> _fetchFavorites() async {
    // RG13 : un favori n'est pas un droit d'accès — la lecture se fait sur
    // "addresses" et la RLS retire d'elle-même les adresses devenues
    // inaccessibles, sans qu'il faille nettoyer "favorites".
    final ids = await favoriteAddressIds();
    if (ids.isEmpty) return [];

    final addressRows =
        await supabase.from('addresses').select().inFilter('id', ids);

    final addresses =
        (addressRows as List).map((r) => Address.fromJson(r)).toList();

    // On garde l'ordre des favoris (le plus récent en premier).
    final byId = {for (final a in addresses) a.id!: a};
    return ids.where(byId.containsKey).map((id) => byId[id]!).toList();
  }

  /// Relit la liste et attend le résultat : le RefreshIndicator attend
  /// vraiment la base au lieu de s'arrêter sur le setState.
  Future<void> _refresh() async {
    final future = _fetchFavorites();
    setState(() => _favoritesFuture = future);
    await future;
  }

  /// Retire le favori depuis la liste elle-même, avec annulation possible.
  Future<void> _remove(Address a) async {
    try {
      await removeFavorite(a.id!);
      if (!mounted) return;
      await _refresh();
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: Text('"${a.name}" retiré des favoris.'),
            action: SnackBarAction(
              label: 'Annuler',
              onPressed: () async {
                try {
                  await addFavorite(a.id!);
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text('Erreur : $e')));
                }
                if (mounted) await _refresh();
              },
            ),
          ),
        );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Erreur : $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Favoris')),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<Address>>(
          future: _favoritesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return ListView(
                children: [
                  const SizedBox(height: 100),
                  Center(child: Text('Erreur : ${snapshot.error}')),
                ],
              );
            }
            final addresses = snapshot.data ?? [];
            if (addresses.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 100),
                  Icon(Icons.star_border, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Center(
                    child: Text(
                      "Aucun favori pour le moment.",
                      style: TextStyle(color: Colors.grey),
                    ),
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
                    onTap: () async {
                      await context.push('/address/${a.id}');
                      if (!mounted) return;
                      // au cas où retiré des favoris depuis le détail
                      await _refresh();
                    },
                    leading: Icon(
                      a.visibility == AddressVisibility.public
                          ? Icons.public
                          : Icons.lock,
                    ),
                    title: Text(a.name),
                    subtitle: Text([
                      if (a.locality != null) a.locality!,
                      a.gpsType == GpsType.exact ? 'Position exacte' : "Point d'accès",
                    ].join(' · ')),
                    trailing: IconButton(
                      icon: const Icon(Icons.star, color: Colors.amber),
                      tooltip: 'Retirer des favoris',
                      onPressed: () => _remove(a),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}