import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/favorites.dart';
import '../../core/onboarding.dart';
import '../../core/supabase_client.dart';
import '../../core/theme/app_spacing.dart';
import '../../models/address.dart';
import '../../ui/address_list_card.dart';
import '../../ui/app_background.dart';
import '../../ui/app_bottom_nav.dart';
import '../../ui/app_button.dart';
import '../../ui/app_states.dart';
import '../../ui/section.dart';
import '../help/widgets/onboarding_tour.dart';

class _WelcomeCache {
  static _WelcomeData? data;
}

class _WelcomeData {
  const _WelcomeData({
    required this.addresses,
    required this.favoriteCount,
    required this.activeShareLinks,
  });

  final List<Address> addresses;
  final int favoriteCount;
  final int activeShareLinks;
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
  bool _loading = false;
  String? _error;
  _WelcomeData? _data;

  @override
  void initState() {
    super.initState();
    _data = _WelcomeCache.data;
    _loading = _data == null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeShowOnboarding();
      _load(refresh: _data != null);
    });
  }

  Future<void> _maybeShowOnboarding() async {
    if (!mounted) return;
    if (await OnboardingStorage.alreadySeen()) return;
    if (!mounted) return;
    await showOnboardingTour(context);
  }

  Future<void> _load({bool refresh = false}) async {
    if (!refresh) {
      setState(() {
        _loading = _data == null;
        _error = null;
      });
    }

    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        if (!mounted) return;
        setState(() {
          _loading = false;
          _data = const _WelcomeData(
            addresses: [],
            favoriteCount: 0,
            activeShareLinks: 0,
          );
        });
        return;
      }

      final results = await Future.wait<Object?>([
        supabase
            .from('addresses')
            .select()
            .eq('owner_id', userId)
            .order('created_at', ascending: false),
        favoriteAddressIds(),
        supabase
            .from('share_links')
            .select('id, status, expires_at, max_uses, used_count')
            .eq('created_by', userId)
            .eq('status', 'ACTIVE'),
      ]);

      final addressRows = (results[0] as List).cast<Map<String, dynamic>>();
      final addresses = addressRows.map(Address.fromJson).toList();
      final favoriteCount = (results[1] as List<String>).length;

      final shareRows = (results[2] as List).cast<Map<String, dynamic>>();
      var activeShareLinks = 0;
      for (final row in shareRows) {
        final expiresAt = row['expires_at'] != null
            ? DateTime.tryParse(row['expires_at'] as String)
            : null;
        final maxUses = (row['max_uses'] as num?)?.toInt();
        final usedCount = (row['used_count'] as num?)?.toInt() ?? 0;
        final expired = expiresAt != null && !expiresAt.isAfter(DateTime.now());
        final full = maxUses != null && usedCount >= maxUses;
        if (!expired && !full) activeShareLinks++;
      }

      final data = _WelcomeData(
        addresses: addresses,
        favoriteCount: favoriteCount,
        activeShareLinks: activeShareLinks,
      );
      _WelcomeCache.data = data;

      if (!mounted) return;
      setState(() {
        _data = data;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        if (_data == null) _error = e.toString();
      });
      if (_data != null) {
        // Contenu déjà affiché : on garde l'existant, pas d'erreur bloquante.
      }
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

  @override
  Widget build(BuildContext context) {
    final data = _data;
    final bottomPadding =
        AppBottomNav.hauteurTotale(context) + AppSpacing.md;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('Bienvenue')),
      body: AppBackground(
        style: AppBackgroundStyle.releve,
        child: _loading && data == null
            ? const AppLoading()
            : _error != null && data == null
                ? AppErrorState(error: _error, onRetry: () => _load())
                : RefreshIndicator(
                    onRefresh: _refresh,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: AppSpacing.list.copyWith(bottom: bottomPadding),
                      children: _buildContent(context, data),
                    ),
                  ),
      ),
    );
  }

  List<Widget> _buildContent(BuildContext context, _WelcomeData? data) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final addresses = data?.addresses ?? const <Address>[];
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
      if (_error != null)
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Icon(Icons.cloud_off_outlined, color: scheme.error),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Impossible de rafraîchir certaines données.',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                  TextButton(
                    onPressed: _refresh,
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            ),
          ),
        ),
      _buildSummary(context, data),
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
      if (recent.isEmpty)
        _buildEmptyRecent(context)
      else
        ...List.generate(recent.length, (index) {
          final address = recent[index];
          return Padding(
            padding: EdgeInsets.only(
              bottom: index < recent.length - 1 ? AppSpacing.sm : 0,
            ),
            child: AddressListCard(
              address: address,
              onTap: () => _openAddress(address),
            ),
          );
        }),
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
      if ((data?.activeShareLinks ?? 0) > 0) ...[
        const SizedBox(height: AppSpacing.lg),
        const SectionHeader(
          title: 'Partages actifs',
          icon: Icons.share_outlined,
        ),
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
                        'Vous avez ${data!.activeShareLinks} lien${data.activeShareLinks > 1 ? 's' : ''} de partage actif${data.activeShareLinks > 1 ? 's' : ''}.',
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

  Widget _buildSummary(BuildContext context, _WelcomeData? data) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final addresses = data?.addresses.length ?? 0;
    final favorites = data?.favoriteCount ?? 0;

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
          value: '$addresses',
          semanticsLabel: '$addresses adresse${addresses > 1 ? 's' : ''}',
          onTap: () => context.go('/'),
        ),
        const SizedBox(width: AppSpacing.sm),
        chip(
          icon: Icons.star_outline,
          label: 'Favoris',
          value: '$favorites',
          semanticsLabel: '$favorites favori${favorites > 1 ? 's' : ''}',
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
