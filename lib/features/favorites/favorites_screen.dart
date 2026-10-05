import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/favorites.dart';
import '../../core/supabase_client.dart';
import '../../core/theme/app_spacing.dart';
import '../../models/address.dart';
import '../../ui/app_feedback.dart';
import '../../ui/app_states.dart';
import '../../ui/status_chip.dart';

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
    final ids = await favoriteAddressIds();
    if (ids.isEmpty) return [];

    final addressRows =
        await supabase.from('addresses').select().inFilter('id', ids);

    final addresses =
        (addressRows as List).map((r) => Address.fromJson(r)).toList();

    final byId = {for (final a in addresses) a.id!: a};
    return ids.where(byId.containsKey).map((id) => byId[id]!).toList();
  }

  Future<void> _refresh() async {
    final future = _fetchFavorites();
    setState(() => _favoritesFuture = future);
    await future;
  }

  Future<void> _remove(Address a) async {
    try {
      await removeFavorite(a.id!);
      if (!mounted) return;
      await _refresh();
      if (!mounted) return;
      AppSnack.withUndo(
        context,
        '"${a.name}" retiré des favoris.',
        undoLabel: 'Annuler',
        onUndo: () async {
          try {
            await addFavorite(a.id!);
          } catch (e) {
            if (!mounted) return;
            AppSnack.error(context, e);
          }
          if (mounted) await _refresh();
        },
      );
    } catch (e) {
      if (!mounted) return;
      AppSnack.error(context, e);
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
              return const AppLoading();
            }
            if (snapshot.hasError) {
              return AppErrorState(
                error: snapshot.error,
                onRetry: _refresh,
              );
            }
            final addresses = snapshot.data ?? [];
            if (addresses.isEmpty) {
              return const AppEmptyState(
                icon: Icons.star_border,
                title: 'Aucun favori pour le moment',
                message: 'Ajoutez des adresses à vos favoris pour les retrouver ici.',
              );
            }
            return ListView.builder(
              padding: AppSpacing.list,
              itemCount: addresses.length,
              itemBuilder: (context, index) {
                final a = addresses[index];
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: index < addresses.length - 1 ? AppSpacing.sm : 0,
                  ),
                  child: Card(
                    child: ListTile(
                      onTap: () => context.push('/address/${a.id}'),
                      leading: a.photoUrl != null
                          ? CircleAvatar(backgroundImage: NetworkImage(a.photoUrl!))
                          : CircleAvatar(
                              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                              child: Icon(
                                Icons.star,
                                color: Theme.of(context).colorScheme.onPrimaryContainer,
                              ),
                            ),
                      title: Text(a.name),
                      subtitle: Text(
                        [
                          if (a.locality != null) a.locality!,
                          a.gpsType.label,
                        ].join(' · '),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.star),
                        tooltip: 'Retirer des favoris',
                        onPressed: () => _remove(a),
                      ),
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
