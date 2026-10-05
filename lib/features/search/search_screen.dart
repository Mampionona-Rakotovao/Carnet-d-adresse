import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/favorites.dart';
import '../../core/supabase_client.dart';
import '../../core/theme/app_spacing.dart';
import '../../models/address.dart';
import '../../ui/app_feedback.dart';
import '../../ui/app_states.dart';
import '../../ui/status_chip.dart';

enum SearchScope { all, mine, public, sharedWithMe }

class _SearchResults {
  final List<Address> addresses;
  final Map<String, String> landmarkMatches;

  _SearchResults(this.addresses, this.landmarkMatches);
}

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  SearchScope _scope = SearchScope.all;
  List<Address> _results = [];
  Set<String> _favoriteIds = {};
  Map<String, String> _landmarkMatches = {};
  bool _loading = false;
  String? _error;
  bool _searchedOnce = false;
  int _requestId = 0;

  @override
  void initState() {
    super.initState();
    _search();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final requestId = ++_requestId;
    setState(() {
      _loading = true;
      _error = null;
      _searchedOnce = true;
    });
    try {
      final results = await _runQuery();
      final favorites = (await favoriteAddressIds()).toSet();
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _results = results.addresses;
        _landmarkMatches = results.landmarkMatches;
        _favoriteIds = favorites;
      });
    } catch (e) {
      if (!mounted || requestId != _requestId) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted && requestId == _requestId) {
        setState(() => _loading = false);
      }
    }
  }

  Future<_SearchResults> _runQuery() async {
    final userId = supabase.auth.currentUser!.id;
    final query = _controller.text.trim();

    List<String>? sharedIds;
    if (_scope == SearchScope.sharedWithMe) {
      final permissionRows = await supabase
          .from('address_permissions')
          .select('address_id')
          .eq('user_id', userId)
          .isFilter('revoked_at', null);
      sharedIds =
          (permissionRows as List).map((r) => r['address_id'] as String).toList();
      if (sharedIds.isEmpty) return _SearchResults([], {});
    }

    var builder = supabase.from('addresses').select();
    if (sharedIds != null) {
      builder = builder.inFilter('id', sharedIds);
    } else if (_scope == SearchScope.mine) {
      builder = builder.eq('owner_id', userId);
    } else if (_scope == SearchScope.public) {
      builder = builder.eq('visibility', 'PUBLIC');
    }

    final pattern = query.isNotEmpty ? '%$query%' : null;
    if (pattern != null) {
      builder = builder.or('name.ilike.$pattern,locality.ilike.$pattern');
    }

    final rows = await builder.order('created_at', ascending: false);
    final found = <String, Address>{
      for (final a in (rows as List).map((r) => Address.fromJson(r))) a.id!: a,
    };

    if (query.isEmpty) return _SearchResults(found.values.toList(), {});

    final landmarkRows = await supabase
        .from('landmarks')
        .select('address_id, name, description')
        .ilike('name', pattern!)
        .or('description.ilike.$pattern');

    final matches = <String, String>{};
    for (final r in landmarkRows as List) {
      final aid = r['address_id'] as String?;
      final lname = r['name'] as String?;
      if (aid != null && lname != null) {
        if (!found.containsKey(aid)) {
          final addrRows = await supabase
              .from('addresses')
              .select()
              .eq('id', aid)
              .maybeSingle();
          if (addrRows != null) {
            found[aid] = Address.fromJson(addrRows);
          }
        }
        matches[aid] = 'Repère : $lname';
      }
    }
    return _SearchResults(found.values.toList(), matches);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Rechercher')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: Column(
              children: [
                TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    labelText: 'Rechercher',
                    hintText: 'Nom, localité ou repère',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _controller.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _controller.clear();
                              _search();
                            },
                          )
                        : null,
                  ),
                  onChanged: (_) => setState(() {}),
                  onSubmitted: (_) => _search(),
                ),
                const SizedBox(height: AppSpacing.sm),
                SegmentedButton<SearchScope>(
                  segments: const [
                    ButtonSegment(value: SearchScope.all, label: Text('Tout')),
                    ButtonSegment(value: SearchScope.mine, label: Text('Mes adresses')),
                    ButtonSegment(value: SearchScope.public, label: Text('Publiques')),
                    ButtonSegment(value: SearchScope.sharedWithMe, label: Text('Partagées')),
                  ],
                  selected: {_scope},
                  onSelectionChanged: (s) {
                    setState(() => _scope = s.first);
                    _search();
                  },
                ),
                const SizedBox(height: AppSpacing.sm),
                if (_loading && _results.isEmpty)
                  const LinearProgressIndicator()
                else if (_loading)
                  const SizedBox(height: 2),
              ],
            ),
          ),
          Expanded(
            child: _buildResults(theme, scheme),
          ),
        ],
      ),
    );
  }

  Widget _buildResults(ThemeData theme, ColorScheme scheme) {
    if (!_searchedOnce) return const SizedBox.shrink();
    if (_error != null) {
      return AppErrorState(
        error: _error,
        onRetry: _search,
      );
    }
    if (!_loading && _results.isEmpty) {
      return const AppEmptyState(
        icon: Icons.search_off_outlined,
        title: 'Aucun résultat',
        message: 'Essayez un autre terme ou modifiez le périmètre de recherche.',
      );
    }
    if (_loading && _results.isEmpty) {
      return const AppLoading();
    }
    return ListView.builder(
      padding: AppSpacing.list,
      itemCount: _results.length,
      itemBuilder: (context, index) {
        final a = _results[index];
        final match = _landmarkMatches[a.id];
        final subtitleParts = <String>[];
        if (a.locality != null && a.locality!.isNotEmpty) {
          subtitleParts.add(a.locality!);
        }
        subtitleParts.add(a.gpsType.label);
        if (match != null) subtitleParts.add(match);

        return Padding(
          padding: EdgeInsets.only(
            bottom: index < _results.length - 1 ? AppSpacing.sm : 0,
          ),
          child: Card(
            child: ListTile(
              onTap: () => context.push('/address/${a.id}'),
              leading: a.photoUrl != null
                  ? CircleAvatar(backgroundImage: NetworkImage(a.photoUrl!))
                  : CircleAvatar(
                      backgroundColor: scheme.primaryContainer,
                      child: Icon(
                        a.visibility == AddressVisibility.public
                            ? Icons.public
                            : Icons.lock_outline,
                        color: scheme.onPrimaryContainer,
                      ),
                    ),
              title: Text(a.name),
              subtitle: Text(
                subtitleParts.join(' · '),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: IconButton(
                icon: Icon(
                  _favoriteIds.contains(a.id) ? Icons.star : Icons.star_border,
                ),
                onPressed: () async {
                  try {
                    if (_favoriteIds.contains(a.id)) {
                      await removeFavorite(a.id!);
                      if (!mounted) return;
                      setState(() {
                        _favoriteIds.remove(a.id);
                      });
                      if (mounted) {
                        AppSnack.info(context, '"${a.name}" retiré des favoris');
                      }
                    } else {
                      await addFavorite(a.id!);
                      if (!mounted) return;
                      setState(() {
                        _favoriteIds.add(a.id!);
                      });
                      if (mounted) {
                        AppSnack.success(this.context, '"${a.name}" ajouté aux favoris');
                      }
                    }
                  } catch (e) {
                    if (mounted) AppSnack.error(this.context, e);
                  }
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
