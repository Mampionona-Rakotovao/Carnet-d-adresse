import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/app_scaffold.dart';
import '../../core/shared_with_me.dart';
import '../../core/theme/app_spacing.dart';
import '../../models/shared_address.dart';
import '../../ui/app_states.dart';
import 'shared_address_tile.dart';
import 'shared_address_view.dart';

/// Liste des adresses reçues par lien et encore valides.
///
/// Rien n'est copié : la liste est recalculée côté serveur à chaque
/// ouverture, et un lien révoqué ou expiré disparaît de lui-même au
/// prochain rafraîchissement (RG20-RG22).
///
/// Un appui sur une entrée affiche l'adresse directement dans cet écran
/// (mode détail), sans changer de page : la flèche de retour — ou le retour
/// système — ramène à la liste.
class SharedWithMeScreen extends StatefulWidget {
  const SharedWithMeScreen({super.key, this.initial});

  /// Entrée déjà choisie à l'ouverture, quand on arrive depuis la section
  /// de l'accueil (`context.push('/shared', extra: entry)`).
  final SharedAddressEntry? initial;

  @override
  State<SharedWithMeScreen> createState() => _SharedWithMeScreenState();
}

class _SharedWithMeScreenState extends State<SharedWithMeScreen> {
  bool _loading = true;
  Object? _error;
  List<SharedAddressEntry> _items = [];
  SharedAddressEntry? _selected;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _selected = widget.initial;
    _load();
    // Les libellés du compte à rebours vieillissent : sans ce ticker, un lien
    // qui expire pendant que l'écran est ouvert afficherait encore « Expire
    // dans 5 min » dix minutes plus tard.
    _ticker = Timer.periodic(const Duration(seconds: 30), (_) => _onTick());
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _onTick() {
    if (_items.isEmpty) return;
    if (_items.any((entry) => entry.isExpired)) {
      // Le serveur a maintenant de quoi retirer les liens morts.
      _load(silent: true);
      return;
    }
    if (mounted) setState(() {});
  }

  void _open(SharedAddressEntry entry) => setState(() => _selected = entry);

  void _back() {
    setState(() => _selected = null);
    // Le lien vient d'être consulté : il a pu expirer ou être révoqué depuis
    // le dernier chargement de la liste.
    _load(silent: true);
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final items = await fetchSharedWithMe();
      if (!mounted) return;
      setState(() {
        _items = items;
        _error = null;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      // Un rafraîchissement silencieux qui échoue laisse la liste affichée.
      if (silent) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  PreferredSizeWidget _appBar() {
    final selected = _selected;
    if (selected != null) {
      final theme = Theme.of(context);
      return AppBar(
        // Explicitement construite : le BackButton automatique démonterait
        // tout l'écran /shared au lieu de fermer le mode détail.
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Retour à la liste',
          onPressed: _back,
        ),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              selected.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              selected.expiryLabel,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return AppBar(
      title: const Text('Partagées avec moi'),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          tooltip: 'Rafraîchir',
          onPressed: _loading ? null : _load,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selected;

    // Retour système (gesture ou bouton Android) : ferme d'abord le mode
    // détail, ne quitte la liste qu'ensuite.
    return PopScope(
      canPop: selected == null,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _back();
      },
      child: Scaffold(
        appBar: _appBar(),
        body: selected != null
            ? SharedAddressView(token: selected.token)
            : _loading
                ? const AppLoading()
                : _error != null
                    ? AppErrorState(
                        error: _error,
                        title: 'Impossible de charger vos adresses partagées',
                        onRetry: _load,
                      )
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: _items.isEmpty
                            ? AppEmptyState(
                                icon: Icons.group_add_outlined,
                                title: 'Aucune adresse partagée avec toi',
                                message:
                                    'Les adresses reçues par lien apparaissent '
                                    'ici tant que le lien est valide.',
                                actionLabel: 'Ouvrir un lien',
                                actionIcon: Icons.link,
                                onAction: () => context.push('/share/open'),
                              )
                            : ListView.builder(
                                padding: AppSpacing.list,
                                itemCount: _items.length,
                                itemBuilder: (context, index) => Padding(
                                  padding: EdgeInsets.only(
                                    bottom: index < _items.length - 1
                                        ? AppSpacing.sm
                                        : 0,
                                  ),
                                  child: SharedAddressTile(
                                    entry: _items[index],
                                    onTap: () => _open(_items[index]),
                                  ),
                                ),
                              ),
                      ),
        bottomNavigationBar: ShellNavigationBar.of(context),
      ),
    );
  }
}
