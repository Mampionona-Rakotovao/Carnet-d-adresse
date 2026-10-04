import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/favorites.dart';
import '../../core/supabase_client.dart';
import '../../models/address.dart';

enum SearchScope { all, mine, public, sharedWithMe }

/// Résultat d'une recherche : les adresses trouvées, plus pour chacune
/// le nom du repère qui a fait matcher (recherche par nom de repère).
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

  /// Numéro de la requête en cours : si deux recherches se chevauchent
  /// (l'utilisateur tape vite), seule la dernière réponse est affichée.
  int _requestId = 0;

  @override
  void initState() {
    super.initState();
    // Chargement initial : toutes les adresses accessibles, sans filtre texte.
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

    // ---- 1. Périmètre : "partagées avec moi" part des permissions, car la
    // RLS ne dit pas "on m'a partagé", elle dit seulement "je peux voir".
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

    // ---- 2. Adresses du périmètre, la RLS filtrant ce qui est lisible ----
    var builder = supabase.from('addresses').select();
    if (sharedIds != null) {
      builder = builder.inFilter('id', sharedIds);
    } else if (_scope == SearchScope.mine) {
      builder = builder.eq('owner_id', userId);
    } else if (_scope == SearchScope.public) {
      builder = builder.eq('visibility', 'PUBLIC');
    }

    if (query.isNotEmpty) {
      final pattern = '%$query%';
      builder = builder.or('name.ilike.$pattern,locality.ilike.$pattern');
    }

    final rows = await builder.order('created_at', ascending: false);
    final found = <String, Address>{
      for (final a in (rows as List).map((r) => Address.fromJson(r)))
        a.id!: a,
    };

    if (query.isEmpty) return _SearchResults(found.values.toList(), {});

    // Sur le périmètre "partagées avec moi", le filtre texte est appliqué en
    // mémoire : le nombre d'adresses partagées reste faible, et surtout le
    // filtre par repère doit pouvoir passer plus loin.
    if (sharedIds != null) {
      final q = query.toLowerCase();
      found.removeWhere(
        (_, a) =>
            !a.name.toLowerCase().contains(q) &&
            !(a.locality?.toLowerCase().contains(q) ?? false),
      );
    }

    // ---- 3. Recherche complémentaire par nom de repère : le carnet est
    // indexé sur les repères ("la porte rouge du 12"), pas seulement sur
    // le nom de l'adresse.
    var landmarks = supabase
        .from('landmarks')
        .select('address_id,name')
        .ilike('name', '%$query%');
    if (sharedIds != null) {
      landmarks = landmarks.inFilter('address_id', sharedIds);
    }

    final landmarkMatches = <String, String>{};
    final extraIds = <String>[];

    for (final r in (await landmarks as List)) {
      final id = r['address_id'] as String;
      if (found.containsKey(id)) continue;
      landmarkMatches.putIfAbsent(id, () => r['name'] as String);
      extraIds.add(id);
    }

    if (extraIds.isNotEmpty) {
      var extraBuilder =
          supabase.from('addresses').select().inFilter('id', extraIds);
      if (_scope == SearchScope.mine) {
        extraBuilder = extraBuilder.eq('owner_id', userId);
      } else if (_scope == SearchScope.public) {
        extraBuilder = extraBuilder.eq('visibility', 'PUBLIC');
      }

      for (final r in (await extraBuilder as List)) {
        final a = Address.fromJson(r);
        found[a.id!] = a;
      }

      // La RLS a pu écarter des adresses : on n'annonce le repère que
      // pour celles qui sont réellement affichées.
      landmarkMatches.removeWhere((id, _) => !found.containsKey(id));
    }

    return _SearchResults(found.values.toList(), landmarkMatches);
  }

  /// Recharge les étoiles sans relancer toute la recherche (retour du détail).
  Future<void> _reloadFavorites() async {
    final favorites = (await favoriteAddressIds()).toSet();
    if (!mounted) return;
    setState(() => _favoriteIds = favorites);
  }

  void _setFavorite(String id, bool value) {
    final next = {..._favoriteIds};
    if (value) {
      next.add(id);
    } else {
      next.remove(id);
    }
    setState(() => _favoriteIds = next);
  }

  Future<void> _toggleFavorite(Address a) async {
    final id = a.id!;
    final wasFavorite = _favoriteIds.contains(id);

    _setFavorite(id, !wasFavorite);

    try {
      await toggleFavorite(id, wasFavorite);
    } catch (e) {
      if (!mounted) return;
      _setFavorite(id, wasFavorite);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Erreur : $e')));
    }
  }

  void _clearQuery() {
    setState(_controller.clear);
    _search();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recherche')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _controller,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Nom, localité ou repère...',
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
                suffixIcon: _controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        tooltip: 'Effacer',
                        onPressed: _clearQuery,
                      )
                    : null,
              ),
              // setState vide : le bouton "effacer" dépend du texte saisi.
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => _search(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ChoiceChip(
                    label: const Text('Toutes'),
                    selected: _scope == SearchScope.all,
                    onSelected: (_) {
                      setState(() => _scope = SearchScope.all);
                      _search();
                    },
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Mes adresses'),
                    selected: _scope == SearchScope.mine,
                    onSelected: (_) {
                      setState(() => _scope = SearchScope.mine);
                      _search();
                    },
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Publiques'),
                    selected: _scope == SearchScope.public,
                    onSelected: (_) {
                      setState(() => _scope = SearchScope.public);
                      _search();
                    },
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Partagées avec moi'),
                    selected: _scope == SearchScope.sharedWithMe,
                    onSelected: (_) {
                      setState(() => _scope = SearchScope.sharedWithMe);
                      _search();
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text('Erreur : $_error'))
                    : _results.isEmpty
                        ? Center(
                            child: Text(
                              _searchedOnce
                                  ? 'Aucun résultat.'
                                  : 'Lance une recherche.',
                              style: const TextStyle(color: Colors.grey),
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _search,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(12),
                              itemCount: _results.length,
                              itemBuilder: (context, index) {
                                final a = _results[index];
                                final id = a.id!;
                                final favorite = _favoriteIds.contains(id);
                                final landmark = _landmarkMatches[id];

                                return Card(
                                  child: ListTile(
                                    onTap: () async {
                                      await context.push('/address/$id');
                                      // Le favori a pu être basculé depuis
                                      // le détail : on resynchronise.
                                      await _reloadFavorites();
                                    },
                                    leading: Icon(
                                      a.visibility == AddressVisibility.public
                                          ? Icons.public
                                          : Icons.lock,
                                    ),
                                    title: Text(a.name),
                                    subtitle: Text([
                                      if (a.locality != null) a.locality!,
                                      a.gpsType == GpsType.exact
                                          ? 'Position exacte'
                                          : "Point d'accès",
                                      if (landmark != null) 'Repère : $landmark',
                                    ].join(' · ')),
                                    trailing: IconButton(
                                      icon: Icon(
                                        favorite ? Icons.star : Icons.star_outline,
                                      ),
                                      color: favorite ? Colors.amber : null,
                                      tooltip: favorite
                                          ? 'Retirer des favoris'
                                          : 'Ajouter aux favoris',
                                      onPressed: () => _toggleFavorite(a),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}