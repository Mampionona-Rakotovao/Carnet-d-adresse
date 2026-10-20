import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/supabase_client.dart';
import '../../core/theme/app_spacing.dart';

/// Adresses reçues par lien de partage et encore valides.
/// Une adresse disparaît d'ici dès que le lien expire ou est révoqué.
class SharedWithMeScreen extends StatefulWidget {
  const SharedWithMeScreen({super.key});

  @override
  State<SharedWithMeScreen> createState() => _SharedWithMeScreenState();
}

class _SharedWithMeScreenState extends State<SharedWithMeScreen> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Map<String, dynamic>>> _load() async {
    final rows = await supabase.rpc('list_shared_with_me');
    return (rows as List).cast<Map<String, dynamic>>();
  }

  Future<void> _refresh() async {
    setState(() => _future = _load());
    try {
      await _future;
    } catch (_) {
      // L'erreur est déjà affichée par le FutureBuilder.
    }
  }

  String _expiryLabel(DateTime expiresAt) {
    final remaining = expiresAt.difference(DateTime.now());
    if (remaining.isNegative) return 'Expiré';
    if (remaining.inDays >= 1) return 'Expire dans ${remaining.inDays} j';
    if (remaining.inHours >= 1) {
      return 'Expire dans ${remaining.inHours} h ${remaining.inMinutes % 60} min';
    }
    return 'Expire dans ${remaining.inMinutes} min';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Partagées avec moi')),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  const SizedBox(height: 80),
                  Icon(Icons.error_outline, size: 48, color: scheme.error),
                  const SizedBox(height: AppSpacing.md),
                  const Text(
                    'Impossible de charger les adresses partagées.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Center(
                    child: OutlinedButton(
                      onPressed: _refresh,
                      child: const Text('Réessayer'),
                    ),
                  ),
                ],
              );
            }

            final rows = snapshot.data ?? [];

            if (rows.isEmpty) {
              return ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  const SizedBox(height: 80),
                  Icon(Icons.inbox_outlined, size: 56, color: scheme.outline),
                  const SizedBox(height: AppSpacing.md),
                  const Text(
                    'Aucune adresse partagée pour le moment.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Les adresses reçues par lien apparaissent ici tant que '
                    'le lien est valide.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: rows.length,
              itemBuilder: (context, index) {
                final row = rows[index];
                final expiresAt = DateTime.parse(row['expires_at'] as String);
                final sharedBy = row['shared_by_name'] as String?;
                final locality = row['locality'] as String?;

                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.share_location_outlined),
                    title: Text(row['name'] as String),
                    subtitle: Text([
                      if (locality != null && locality.isNotEmpty) locality,
                      if (sharedBy != null) 'Partagé par $sharedBy',
                      _expiryLabel(expiresAt),
                    ].join(' · ')),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      await context.push('/shared/${row['share_link_id']}');
                      // Le lien a pu être révoqué entre-temps : on recharge.
                      if (mounted) _refresh();
                    },
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