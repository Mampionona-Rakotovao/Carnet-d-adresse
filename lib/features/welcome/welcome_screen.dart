import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/address_refresh.dart';
import '../../core/favorites.dart';
import '../../core/onboarding.dart';
import '../../core/share_links.dart';
import '../../core/supabase_client.dart';
import '../../core/theme/app_spacing.dart';
import '../../models/address.dart';
import '../../ui/address_actions_menu.dart';
import '../../ui/address_list_card.dart';
import '../../ui/app_background.dart';
import '../../ui/app_bottom_nav.dart';
import '../../ui/app_button.dart';
import '../../ui/app_menu_button.dart';
import '../../ui/section.dart';
import '../help/widgets/onboarding_tour.dart';

/// Cache des blocs, conservé d'un onglet à l'autre (le routeur recrée l'écran).
/// Il est vidé quand l'utilisateur connecté change.
class _WelcomeCache {
  static String? _userId;
  static List<Address>? addresses;
  static Set<String>? favoriteIds;
  static int? activeShareLinks;

  static void prepare(String? userId) {
    if (_userId == userId) return;
    addresses = null;
    favoriteIds = null;
    activeShareLinks = null;
    _userId = userId;
  }
}

/// État indépendant d'un bloc de la page : chaque bloc charge, réussit ou
/// échoue sans entraîner la disparition des autres.
class _AsyncBlock<T> {
  const _AsyncBlock({this.data, this.error, this.loading = false});

  final T? data;
  final Object? error;
  final bool loading;
}

class _Tip {
  const _Tip(this.text, this.articleId);

  final String text;
  final String articleId;
}

const List<_Tip> _tips = [
  _Tip(
    'Ajoutez des repères visibles pour aider quelqu’un à reconnaître le lieu.',
    'ajouter-repere',
  ),
  _Tip(
    'Un lien de partage peut être temporaire : choisissez une durée adaptée.',
    'creer-partage',
  ),
  _Tip(
    'La vue satellite aide à repérer un toit, une cour ou un carrefour.',
    'plan-satellite',
  ),
  _Tip(
    'Le guidage vous accompagne étape par étape jusqu’à la destination.',
    'guidage',
  ),
  _Tip(
    'Ajoutez une adresse en favori pour la retrouver en un seul geste.',
    'ajouter-favoris',
  ),
  _Tip(
    'La recherche retrouve aussi une adresse grâce au nom d’un repère.',
    'rechercher-adresse',
  ),
  _Tip(
    'Décrivez le chemin avec des étapes simples pour guider un proche.',
    'ajouter-etape',
  ),
  _Tip(
    'Un point d’accès est utile quand la position exacte n’est pas la bonne entrée.',
    'type-reperage',
  ),
  _Tip(
    'Vous pouvez partager une adresse sans exposer tout votre carnet.',
    'creer-partage',
  ),
  _Tip(
    'Consultez l’aide depuis le menu si vous hésitez sur une action.',
    'accueil',
  ),
];

/// Onglet d'accueil : tableau de bord affiché en premier dans la barre.
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  _AsyncBlock<List<Address>> _addresses = const _AsyncBlock(loading: true);
  _AsyncBlock<Set<String>> _favorites = const _AsyncBlock(loading: true);
  _AsyncBlock<int> _shareLinks = const _AsyncBlock(loading: true);

  @override
  void initState() {
    super.initState();
    final userId = supabase.auth.currentUser?.id;
    _WelcomeCache.prepare(userId);
    _addresses = _AsyncBlock(
      data: _WelcomeCache.addresses,
      loading: _WelcomeCache.addresses == null,
    );
    _favorites = _AsyncBlock(
      data: _WelcomeCache.favoriteIds,
      loading: _WelcomeCache.favoriteIds == null,
    );
    _shareLinks = _AsyncBlock(
      data: _WelcomeCache.activeShareLinks,
      loading: _WelcomeCache.activeShareLinks == null,
    );

    // Une action faite depuis une carte (favori, partage, suppression…) met
    // aussi à jour cette page, même si l'onglet Adresses était ouvert.
    addressDataRevision.addListener(_onDataChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeShowOnboarding();
      _load();
    });
  }

  @override
  void dispose() {
    addressDataRevision.removeListener(_onDataChanged);
    super.dispose();
  }

  void _onDataChanged() {
    if (!mounted) return;
    _load(refresh: true);
  }

  Future<void> _maybeShowOnboarding() async {
    if (!mounted) return;
    if (await OnboardingStorage.alreadySeen()) return;
    if (!mounted) return;
    await showOnboardingTour(context);
  }

  /// Trois chargements indépendants : un échec n'affecte que son bloc.
  Future<void> _load({bool refresh = false}) => Future.wait<void>([
        _loadAddresses(refresh: refresh),
        _loadFavorites(refresh: refresh),
        _loadShareLinks(refresh: refresh),
      ]);

  Future<void> _loadAddresses({bool refresh = false}) async {
    if (!mounted) return;
    if (refresh || _addresses.data == null) {
      setState(() => _addresses =
          _AsyncBlock(data: _addresses.data, loading: true));
    }
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        if (!mounted) return;
        setState(() => _addresses = const _AsyncBlock(data: <Address>[]));
        return;
      }

      final rows = await supabase
          .from('addresses')
          .select()
          .eq('owner_id', userId)
          .order('created_at', ascending: false);
      if (!mounted) return;

      final addresses = (rows as List)
          .cast<Map<String, dynamic>>()
          .map(Address.fromJson)
          .toList();
      _WelcomeCache.addresses = addresses;
      if (!mounted) return;
      setState(() => _addresses = _AsyncBlock(data: addresses));
    } catch (e) {
      debugPrint('WelcomeScreen._loadAddresses → $e');
      if (!mounted) return;
      setState(() =>
          _addresses = _AsyncBlock(data: _addresses.data, error: e));
    }
  }

  Future<void> _loadFavorites({bool refresh = false}) async {
    if (!mounted) return;
    if (refresh || _favorites.data == null) {
      setState(
          () => _favorites = _AsyncBlock(data: _favorites.data, loading: true));
    }
    try {
      if (supabase.auth.currentUser?.id == null) {
        if (!mounted) return;
        setState(() => _favorites = const _AsyncBlock(data: <String>{}));
        return;
      }

      final ids = await favoriteAddressIds();
      if (!mounted) return;

      final favoriteIds = ids.toSet();
      _WelcomeCache.favoriteIds = favoriteIds;
      if (!mounted) return;
      setState(() => _favorites = _AsyncBlock(data: favoriteIds));
    } catch (e) {
      debugPrint('WelcomeScreen._loadFavorites → $e');
      if (!mounted) return;
      setState(() => _favorites = _AsyncBlock(data: _favorites.data, error: e));
    }
  }

  Future<void> _loadShareLinks({bool refresh = false}) async {
    if (!mounted) return;
    if (refresh || _shareLinks.data == null) {
      setState(() => _shareLinks =
          _AsyncBlock(data: _shareLinks.data, loading: true));
    }
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        if (!mounted) return;
        setState(() => _shareLinks = const _AsyncBlock(data: 0));
        return;
      }

      // Même chargeur et même règle « actif » que le panneau de gestion :
      // plus aucun select() sur une colonne used_count inexistante.
      final links = await fetchShareLinksWithUsage(
        column: 'created_by',
        value: userId,
      );
      if (!mounted) return;

      final activeCount = links.where((link) => link.isEffectivelyActive).length;
      _WelcomeCache.activeShareLinks = activeCount;
      if (!mounted) return;
      setState(() => _shareLinks = _AsyncBlock(data: activeCount));
    } catch (e) {
      debugPrint('WelcomeScreen._loadShareLinks → $e');
      if (!mounted) return;
      setState(() => _shareLinks = _AsyncBlock(data: _shareLinks.data, error: e));
    }
  }

  Future<void> _refresh() => _load(refresh: true);

  String _greetingName() {
    final raw = supabase.auth.currentUser?.userMetadata?['name'];
    final name = raw is String ? raw.trim() : '';
    if (name.isEmpty) return 'Bonjour';
    return 'Bonjour, $name';
  }

  String _greetingMoment() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Bonjour';
    if (hour < 18) return 'Bon après-midi';
    return 'Bonsoir';
  }

  _Tip _tipOfDay() {
    final now = DateTime.now();
    final daySeed = now.year * 10000 + now.month * 100 + now.day;
    return _tips[daySeed % _tips.length];
  }

  Future<void> _openAddress(Address address) async {
    final id = address.id;
    if (id == null) return;
    await context.push('/address/$id');
    if (mounted) await _refresh();
  }

  void _setFavoriteLocally(String? addressId, bool favorite) {
    if (addressId == null || !mounted) return;
    setState(() {
      final updated = Set<String>.from(_favorites.data ?? const <String>{});
      if (favorite) {
        updated.add(addressId);
      } else {
        updated.remove(addressId);
      }
      _favorites = _AsyncBlock(data: updated);
      _WelcomeCache.favoriteIds = updated;
    });
  }

  void _removeAddressLocally(Address address) {
    if (!mounted) return;
    setState(() {
      final updated = (_addresses.data ?? const <Address>[])
          .where((item) => item.id != address.id)
          .toList();
      _addresses = _AsyncBlock(data: updated);
      _WelcomeCache.addresses = updated;

      if (address.id != null) {
        final favorites = Set<String>.from(_favorites.data ?? const <String>{});
        favorites.remove(address.id);
        _favorites = _AsyncBlock(data: favorites);
        _WelcomeCache.favoriteIds = favorites;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding =
        AppBottomNav.hauteurTotale(context) + AppSpacing.md;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Bienvenue'),
        actions: const [AppMenuButton()],
      ),
      body: AppBackground(
        style: AppBackgroundStyle.releve,
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: TweenAnimationBuilder<double>(
            key: const ValueKey('welcome-content'),
            tween: Tween(begin: 0, end: 1),
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            builder: (context, value, child) => Opacity(
              opacity: value,
              child: child,
            ),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: AppSpacing.list.copyWith(bottom: bottomPadding),
              children: _buildContent(context),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildContent(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final addresses = _addresses.data ?? const <Address>[];
    final recent = addresses.take(3).toList();
    final tip = _tipOfDay();

    return [
      Semantics(
        header: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _greetingName(),
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              '${_greetingMoment()} ! Retrouvez vos lieux et reprenez où vous en étiez.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: AppSpacing.lg),
      _buildSummary(context),
      const SizedBox(height: AppSpacing.lg),
      const SectionHeader(
        title: 'Actions rapides',
        icon: Icons.bolt_outlined,
      ),
      const SizedBox(height: AppSpacing.sm),
      _buildQuickActions(context),
      const SizedBox(height: AppSpacing.lg),
      SectionHeader(
        title: 'Reprendre où j’en étais',
        icon: Icons.history,
        trailing: addresses.isNotEmpty
            ? TextButton(
                onPressed: () => context.go('/'),
                child: const Text('Voir tout'),
              )
            : null,
      ),
      const SizedBox(height: AppSpacing.sm),
      _buildRecentBlock(context, recent),
      const SizedBox(height: AppSpacing.lg),
      const SectionHeader(
        title: 'Astuce du jour',
        icon: Icons.lightbulb_outline,
      ),
      const SizedBox(height: AppSpacing.sm),
      Card(
        child: InkWell(
          borderRadius: AppRadius.cardRadius,
          onTap: () => context.push('/aide/${tip.articleId}'),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.tips_and_updates_outlined, color: scheme.primary),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tip.text, style: theme.textTheme.bodyMedium),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        'Lire l’article d’aide',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: scheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
              ],
            ),
          ),
        ),
      ),
      _buildShareLinksBlock(context),
      const SizedBox(height: AppSpacing.xl),
      const Divider(),
      const SizedBox(height: AppSpacing.sm),
      Center(
        child: Wrap(
          alignment: WrapAlignment.center,
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          children: [
            TextButton.icon(
              onPressed: () => showOnboardingTour(context),
              icon: const Icon(Icons.play_circle_outline),
              label: const Text('Revoir le tour de bienvenue'),
            ),
            TextButton.icon(
              onPressed: () => context.push('/aide'),
              icon: const Icon(Icons.help_outline),
              label: const Text('Aide et support'),
            ),
          ],
        ),
      ),
    ];
  }

  /// Petit message d'erreur local : jamais le détail technique de l'exception.
  Widget _blockError(BuildContext context, {required VoidCallback onRetry}) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        child: Row(
          children: [
            Icon(Icons.cloud_off_outlined, size: 18, color: scheme.error),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                'Impossible de charger',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            TextButton(
              onPressed: onRetry,
              child: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _blockLoading() => const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Center(
          child: SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );

  Widget _buildRecentBlock(BuildContext context, List<Address> recent) {
    if (_addresses.error != null) {
      return _blockError(
        context,
        onRetry: () => _loadAddresses(refresh: true),
      );
    }
    if (_addresses.data == null) return _blockLoading();
    if (recent.isEmpty) return _buildEmptyRecent(context);

    return Column(
      children: List.generate(recent.length, (index) {
        final address = recent[index];
        return Padding(
          padding: EdgeInsets.only(
            bottom: index < recent.length - 1 ? AppSpacing.sm : 0,
          ),
          child: AddressListCard(
            address: address,
            onTap: () => _openAddress(address),
            actions: AddressActionsMenu(
              address: address,
              isFavorite: _favorites.data?.contains(address.id) ?? false,
              onFavoriteChanged: (value) =>
                  _setFavoriteLocally(address.id, value),
              onDeleted: _removeAddressLocally,
            ),
          ),
        );
      }),
    );
  }

  Widget _buildShareLinksBlock(BuildContext context) {
    final block = _shareLinks;
    const header = SectionHeader(
      title: 'Partages actifs',
      icon: Icons.share_outlined,
    );

    if (block.error != null) {
      return Column(
        children: [
          const SizedBox(height: AppSpacing.lg),
          header,
          const SizedBox(height: AppSpacing.sm),
          _blockError(context, onRetry: () => _loadShareLinks(refresh: true)),
        ],
      );
    }
    if (block.data == null) {
      return Column(
        children: [
          const SizedBox(height: AppSpacing.lg),
          header,
          _blockLoading(),
        ],
      );
    }

    final count = block.data!;
    if (count == 0) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Column(
      children: [
        const SizedBox(height: AppSpacing.lg),
        header,
        const SizedBox(height: AppSpacing.sm),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.link, color: scheme.primary),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Vous avez $count lien${count > 1 ? 's' : ''} de partage actif${count > 1 ? 's' : ''}.',
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        'Gérez-les depuis la fiche de chaque adresse.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => context.go('/'),
                  child: const Text('Adresses'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummary(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final addressesError = _addresses.error;
    final favoritesError = _favorites.error;

    if (addressesError != null || favoritesError != null) {
      return _blockError(
        context,
        onRetry: () {
          if (addressesError != null) _loadAddresses(refresh: true);
          if (favoritesError != null) _loadFavorites(refresh: true);
        },
      );
    }

    final addressCount = _addresses.data?.length;
    final favoriteCount = _favorites.data?.length;

    Widget chip({
      required IconData icon,
      required String label,
      required String value,
      required String semanticsLabel,
      required VoidCallback onTap,
    }) {
      return Expanded(
        child: Semantics(
          button: true,
          label: semanticsLabel,
          child: Card(
            child: InkWell(
              borderRadius: AppRadius.cardRadius,
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  children: [
                    Icon(icon, color: scheme.primary),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      value,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      label,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        chip(
          icon: Icons.place_outlined,
          label: 'Adresses',
          value: addressCount == null ? '…' : '$addressCount',
          semanticsLabel: addressCount == null
              ? 'Chargement des adresses'
              : '$addressCount adresse${addressCount > 1 ? 's' : ''}',
          onTap: () => context.go('/'),
        ),
        const SizedBox(width: AppSpacing.sm),
        chip(
          icon: Icons.star_outline,
          label: 'Favoris',
          value: favoriteCount == null ? '…' : '$favoriteCount',
          semanticsLabel: favoriteCount == null
              ? 'Chargement des favoris'
              : '$favoriteCount favori${favoriteCount > 1 ? 's' : ''}',
          onTap: () => context.go('/favorites'),
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          button: true,
          label: 'Ajouter une adresse',
          child: AppButton.primary(
            label: 'Ajouter une adresse',
            icon: Icons.add_location_alt_outlined,
            expanded: true,
            onPressed: () => context.push('/address/create'),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: Semantics(
                button: true,
                label: 'Rechercher une adresse',
                child: AppButton.outline(
                  label: 'Rechercher',
                  icon: Icons.search,
                  expanded: true,
                  onPressed: () => context.go('/search'),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Semantics(
                button: true,
                label: 'Mes favoris',
                child: AppButton.outline(
                  label: 'Favoris',
                  icon: Icons.star_outline,
                  expanded: true,
                  onPressed: () => context.go('/favorites'),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Semantics(
          button: true,
          label: 'Ouvrir l’aide',
          child: AppButton.text(
            label: 'Ouvrir l’aide',
            icon: Icons.help_outline,
            onPressed: () => context.push('/aide'),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyRecent(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            Icon(
              Icons.map_outlined,
              size: 40,
              color: scheme.onSurfaceVariant,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Ajoutez votre première adresse',
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              'Elle apparaîtra ici pour que vous puissiez la retrouver facilement.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            AppButton.primary(
              label: 'Ajouter une adresse',
              icon: Icons.add,
              onPressed: () => context.push('/address/create'),
            ),
          ],
        ),
      ),
    );
  }
}
