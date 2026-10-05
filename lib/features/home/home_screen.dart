import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/app_scaffold.dart';
import '../../core/supabase_client.dart';
import '../../core/theme/app_spacing.dart';
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
      builder: (context) => AlertDialog(
        title: const Text('Se déconnecter ?'),
        content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton.tonal(
            style: FilledButton.styleFrom(
              foregroundColor: Colors.red,
              backgroundColor: Colors.red.shade50,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Se déconnecter'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await supabase.auth.signOut();
    }
  }

  PreferredSizeWidget _appBar() => AppBar(
        title: const Text('Mes adresses'),
        // Les deux actions secondaires sont regroupées dans un menu : l'AppBar
        // garde la place pour le titre au lieu de la partager avec des icônes
        // de 48 px qui n'apportent rien tant qu'on ne les cherche pas.
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Menu',
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'open_link') {
                context.push('/share/open');
              } else if (value == 'logout') {
                _confirmLogout();
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'open_link',
                child: ListTile(
                  leading: Icon(Icons.link),
                  title: Text('Ouvrir un lien'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
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
            ],
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
        // L'écran est monté une seule fois : le `Scaffold` ne dépend pas de
        // l'état du flux, seul son `body` change.
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _shell(const AppLoading());
        }

        if (snapshot.hasError) {
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
                    child: Text(
                      'Connecté en tant que ${user?.email ?? "?"}',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                )
              : ListView(
                  // Réserve basse doublée : sans elle, la dernière carte passe
                  // sous le bouton flottant et devient impossible à toucher.
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
                        // `go` et non `push` : /search est un onglet du shell,
                        // le pousser y empilerait une seconde barre de navigation.
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
          // Masqué quand la liste est vide : l'état vide affiche déjà un bouton
          // « Ajouter une adresse » en pleine largeur.
          fab: addresses.isEmpty
              ? null
              : FloatingActionButton(
                  onPressed: () => context.push('/address/create'),
                  tooltip: 'Ajouter une adresse',
                  child: const Icon(Icons.add),
                ),
        );
      },
    );
  }

  /// Squelette commun à tous les états de l'écran, pour que la barre de
  /// navigation reste présente pendant le chargement comme en erreur.
  Widget _shell(Widget body, {Widget? fab}) => Scaffold(
        appBar: _appBar(),
        body: body,
        floatingActionButton: fab,
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
