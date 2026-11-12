import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/onboarding.dart';
import '../../core/supabase_client.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/theme_mode_controller.dart';
import '../../models/address.dart';
import '../../ui/app_background.dart';
import '../../ui/app_bottom_nav.dart';
import '../../ui/app_states.dart';
import '../../ui/section.dart';
import '../../ui/status_chip.dart';
import '../help/widgets/onboarding_tour.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final Stream<List<Map<String, dynamic>>> _addressesStream;
  final Set<String> _deletedAddressIds = {};

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
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowOnboarding());
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

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final scheme = Theme.of(context).colorScheme;
        return AlertDialog(
          icon: Icon(Icons.logout, color: scheme.error),
          title: const Text('Se déconnecter ?', textAlign: TextAlign.center),
          content: const Text(
            'Vous devrez vous reconnecter pour accéder à vos adresses.',
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.center,
          actionsPadding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          actions: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: scheme.error,
                      foregroundColor: scheme.onError,
                      minimumSize: const Size.fromHeight(48),
                    ),
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('Déconnexion'),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Annuler'),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
    if (confirmed == true && mounted) {
      await supabase.auth.signOut();
    }
  }

  PreferredSizeWidget _appBar() => AppBar(
        title: const Text('Mes adresses'),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Menu',
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              final mode = ThemeMode.values.asNameMap()[value];
              if (mode != null) {
                ThemeModeScope.set(context, mode);
              } else if (value == 'add_address') {
                context.push('/address/create');
              } else if (value == 'shared_with_me') {
                context.push('/shared');
              } else if (value == 'help') {
                context.push('/aide');
              } else if (value == 'logout') {
                _confirmLogout();
              }
            },
            itemBuilder: (context) {
              final theme = Theme.of(context);
              final scheme = theme.colorScheme;
              return [
                PopupMenuItem(
                  enabled: false,
                  child: Text(
                    'Apparence',
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ),
                for (final mode in ThemeModeController.choices)
                  CheckedPopupMenuItem(
                    value: mode.name,
                    checked: ThemeModeScope.of(context) == mode,
                    child: Row(
                      children: [
                        Icon(
                          ThemeModeController.icon(mode),
                          size: 20,
                          color: scheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(ThemeModeController.label(mode)),
                      ],
                    ),
                  ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'add_address',
                  child: ListTile(
                    leading: Icon(Icons.add),
                    title: Text('Ajouter une adresse'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuItem(
                  value: 'shared_with_me',
                  child: ListTile(
                    leading: Icon(Icons.share_location),
                    title: Text('Partagées avec moi'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuItem(
                  value: 'help',
                  child: ListTile(
                    leading: Icon(Icons.help_outline),
                    title: Text('Aide'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuItem(
                  value: 'logout',
                  child: ListTile(
                    leading: Icon(Icons.logout, color: Colors.red),
                    title: Text(
                      'Se déconnecter',
                      style: TextStyle(color: Colors.red),
                    ),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ];
            },
          ),
        ],
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
                        Text('Bienvenue !',
                            style: theme.textTheme.headlineSmall),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          'Retrouvez facilement vos lieux importants',
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
                        child: _AddressCard(
                          address: a,
                          onTap: () => _openAddress(a),
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

class _AddressCard extends StatelessWidget {
  const _AddressCard({required this.address, required this.onTap});

  final Address address;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final subtitleParts = <String>[];
    if (address.locality != null && address.locality!.isNotEmpty) {
      subtitleParts.add(address.locality!);
    }
    subtitleParts.add(address.gpsType.label);

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.cardRadius,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: scheme.primaryContainer,
                foregroundColor: scheme.onPrimaryContainer,
                backgroundImage: address.photoUrl != null
                    ? NetworkImage(address.photoUrl!)
                    : null,
                child: address.photoUrl == null
                    ? Icon(
                        address.visibility == AddressVisibility.public
                            ? Icons.public
                            : Icons.lock_outline,
                      )
                    : null,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      address.name,
                      style: theme.textTheme.titleMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subtitleParts.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        subtitleParts.join(' · '),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xxs,
                      children: [
                        AppStatusChip.gpsType(address.gpsType, dense: true),
                        AppStatusChip.visibility(
                          address.visibility,
                          dense: true,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Icon(
                Icons.chevron_right,
                color: scheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
