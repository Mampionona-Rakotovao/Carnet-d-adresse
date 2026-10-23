import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/app_scaffold.dart';
import '../../core/supabase_client.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/theme_mode_controller.dart';
import '../../models/address.dart';
import '../../ui/app_states.dart';
import '../../ui/section.dart';
import '../../ui/status_chip.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final Stream<List<Map<String, dynamic>>> _addressesStream;

  @override
  void initState() {
    super.initState();
    final userId = supabase.auth.currentUser!.id;
    _addressesStream = supabase
        .from('addresses')
        .stream(primaryKey: ['id'])
        .eq('owner_id', userId)
        .order('created_at', ascending: false);
  }

    Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final scheme = Theme.of(context).colorScheme;
        return AlertDialog(
          icon: Icon(Icons.logout, color: scheme.error),
          title: const Text('Se déconnecter ?'),
          content: const Text(
            'Vous devrez vous reconnecter pour accéder à vos adresses.',
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.spaceBetween,
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Annuler'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: scheme.error,
                  foregroundColor: scheme.onError,
                ),
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Déconnexion'),
              ),
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
            return _shell(const AppLoading());
          }
          return _shell(
            AppErrorState(
                error: snapshot.error, onRetry: () => setState(() {})),
          );
        }

        final addresses =
            (snapshot.data ?? []).map((row) => Address.fromJson(row)).toList();

        return _shell(
          addresses.isEmpty
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
                  padding: AppSpacing.list.copyWith(bottom: AppSpacing.xxl * 2),
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
                        child: _AddressCard(address: a),
                      );
                    }),
                  ],
                ),
        );
      },
    );
  }

  Widget _shell(Widget body) => Scaffold(
        appBar: _appBar(),
        body: body,
        bottomNavigationBar: ShellNavigationBar.of(context),
      );
}

class _AddressCard extends StatelessWidget {
  const _AddressCard({required this.address});

  final Address address;

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
        onTap: () => context.push('/address/${address.id}'),
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
