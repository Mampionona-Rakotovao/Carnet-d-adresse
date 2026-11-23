import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/address_refresh.dart';
import '../../core/favorites.dart';
import '../../core/onboarding.dart';
import '../../core/supabase_client.dart';
import '../../core/theme/app_spacing.dart';
import '../../models/address.dart';
import '../../ui/address_actions_menu.dart';
import '../../ui/address_list_card.dart';
import '../../ui/app_background.dart';
import '../../ui/app_bottom_nav.dart';
import '../../ui/app_states.dart';
import '../../ui/section.dart';
import '../help/widgets/onboarding_tour.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final Stream<List<Map<String, dynamic>>> _addressesStream;
  final Set<String> _deletedAddressIds = {};
  Set<String> _favoriteIds = <String>{};

  @override
  void initState() {
    super.initState();
    final userId = supabase.auth.currentUser?.id;
    _addressesStream = userId == null
        ? Stream<List<Map<String, dynamic>>>.value(const [])
        : supabase
            .from('addresses')
            .stream(primaryKey: ['id'])
            .eq('owner_id', userId)
            .order('created_at', ascending: false);
    _loadFavoriteIds();
    addressDataRevision.addListener(_onDataChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowOnboarding());
  }

  @override
  void dispose() {
    addressDataRevision.removeListener(_onDataChanged);
    super.dispose();
  }

  /// Le flux Realtime couvre les adresses ; les favoris et les liens sont
  /// rechargés quand une action est faite depuis l'autre onglet.
  void _onDataChanged() {
    if (!mounted) return;
    _loadFavoriteIds();
  }

  Future<void> _loadFavoriteIds() async {
    try {
      final ids = await favoriteAddressIds();
      if (!mounted) return;
      setState(() => _favoriteIds = ids.toSet());
    } catch (e) {
      debugPrint('HomeScreen._loadFavoriteIds → $e');
    }
  }

  void _setFavoriteLocally(String? addressId, bool favorite) {
    if (addressId == null || !mounted) return;
    setState(() {
      final updated = Set<String>.from(_favoriteIds);
      if (favorite) {
        updated.add(addressId);
      } else {
        updated.remove(addressId);
      }
      _favoriteIds = updated;
    });
  }

  void _removeAddressLocally(Address address) {
    final id = address.id;
    if (id == null || !mounted) return;
    setState(() {
      _deletedAddressIds.add(id);
      _favoriteIds.remove(id);
    });
  }

  Future<void> _maybeShowOnboarding() async {
    if (!mounted) return;
    if (await OnboardingStorage.alreadySeen()) return;
    if (!mounted) return;
    await showOnboardingTour(context);
  }

  Future<void> _openAddress(Address address) async {
    final id = address.id;
    if (id == null) return;

    final deleted = await context.push<bool>('/address/$id');
    if (!mounted || deleted != true) return;
    setState(() => _deletedAddressIds.add(id));
  }

  PreferredSizeWidget _appBar() => AppBar(
        title: const Text('Mes adresses'),
      );

  @override
  Widget build(BuildContext context) {
    final user = supabase.auth.currentUser;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _addressesStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          final msg = snapshot.error.toString();
          if (msg.contains('InvalidJWTToken') || msg.contains('JWT')) {
            // Session expirée ou invalide : on repart sur le login.
            WidgetsBinding.instance.addPostFrameCallback((_) async {
              await supabase.auth.signOut();
            });
            return _shell(AppBackgroundStyle.releve, const AppLoading());
          }
          return _shell(
            AppBackgroundStyle.releve,
            AppErrorState(
                error: snapshot.error, onRetry: () => setState(() {})),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return _shell(AppBackgroundStyle.releve, const AppLoading());
        }

        final addresses = (snapshot.data ?? [])
            .where((row) => !_deletedAddressIds.contains(row['id']))
            .map((row) => Address.fromJson(row))
            .toList();

        final vide = addresses.isEmpty;
        return _shell(
          vide ? AppBackgroundStyle.vide : AppBackgroundStyle.releve,
          vide
              ? AppEmptyState(
                  icon: Icons.map_outlined,
                  title: 'Aucune adresse enregistrée',
                  message:
                      'Ajoutez votre première adresse pour la retrouver facilement.',
                  actionLabel: 'Ajouter une adresse',
                  actionIcon: Icons.add,
                  onAction: () => context.push('/address/create'),
                  secondaryAction: Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.sm),
                    child: Column(
                      children: [
                        TextButton.icon(
                          onPressed: () => context.push('/shared'),
                          icon: const Icon(Icons.share_location),
                          label: const Text('Partagées avec moi'),
                        ),
                        Text(
                          'Connecté en tant que ${user?.email ?? "?"}',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                )
              : ListView(
                  padding: AppSpacing.list.copyWith(
                    // La barre flottante est posée par le shell au-dessus du
                    // contenu : la liste réserve sa hauteur + une marge pour
                    // que la dernière carte reste accessible.
                    bottom: AppBottomNav.hauteurTotale(context) + AppSpacing.md,
                  ),
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Vos lieux importants',
                          style: theme.textTheme.headlineSmall,
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          'Retrouvez facilement vos adresses enregistrées.',
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    SectionHeader(
                      title: 'Adresses récentes',
                      icon: Icons.access_time_outlined,
                      trailing: TextButton(
                        onPressed: () => context.go('/search'),
                        child: const Text('Rechercher'),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    ...List.generate(addresses.length, (index) {
                      final a = addresses[index];
                      return Padding(
                        padding: EdgeInsets.only(
                          bottom:
                              index < addresses.length - 1 ? AppSpacing.sm : 0,
                        ),
                        child: AddressListCard(
                          address: a,
                          onTap: () => _openAddress(a),
                          actions: AddressActionsMenu(
                            address: a,
                            isFavorite: _favoriteIds.contains(a.id),
                            onFavoriteChanged: (value) =>
                                _setFavoriteLocally(a.id, value),
                            onDeleted: _removeAddressLocally,
                          ),
                        ),
                      );
                    }),
                  ],
                ),
        );
      },
    );
  }

  Widget _shell(AppBackgroundStyle style, Widget body) => Scaffold(
        backgroundColor: Colors.transparent,
        appBar: _appBar(),
        body: AppBackground(style: style, child: body),
      );
}
