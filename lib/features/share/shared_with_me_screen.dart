import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/shared_with_me.dart';
import '../../core/supabase_client.dart';
import '../../core/theme/app_spacing.dart';
import '../../models/landmark.dart';
import '../../models/route_step.dart';
import '../../models/shared_address.dart';

/// Adresses reçues par lien et encore valides. Rien n'est copié :
/// la liste est recalculée côté serveur à chaque ouverture.
class SharedWithMeScreen extends StatefulWidget {
  const SharedWithMeScreen({super.key});

  @override
  State<SharedWithMeScreen> createState() => _SharedWithMeScreenState();
}

class _SharedWithMeScreenState extends State<SharedWithMeScreen> {
  bool _loading = true;
  String? _error;
  List<SharedAddressEntry> _items = [];
  Timer? _timer;
  final Set<String> _expanded = {};
  final Map<String, List<Landmark>> _landmarks = {};
  final Map<String, List<RouteStep>> _steps = {};
  final Map<String, bool> _loadingDetails = {};

  @override
  void initState() {
    super.initState();
    _load();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await fetchSharedWithMe();
      if (mounted) setState(() => _items = list);
    } catch (e) {
      if (mounted) setState(() => _error = 'Erreur : $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleExpand(SharedAddressEntry item) async {
    final token = item.token;
    if (_expanded.contains(token)) {
      setState(() => _expanded.remove(token));
      return;
    }

    setState(() => _expanded.add(token));

    if (_landmarks.containsKey(token) || _loadingDetails[token] == true) {
      return;
    }

    setState(() => _loadingDetails[token] = true);
    try {
      final result = await supabase.rpc(
        'get_shared_address_full',
        params: {'p_token': token},
      );
      if (result == null) {
        return;
      }
      final data = result as Map<String, dynamic>;
      final landmarks = ((data['landmarks'] as List?) ?? [])
          .map((r) => Landmark.fromJson(r as Map<String, dynamic>))
          .toList();
      final steps = ((data['steps'] as List?) ?? [])
          .map((r) => RouteStep.fromJson(r as Map<String, dynamic>))
          .toList();
      if (mounted) {
        setState(() {
          _landmarks[token] = landmarks;
          _steps[token] = steps;
        });
      }
    } catch (e) {
      // Silencieux pour ne pas casser l'affichage
    } finally {
      if (mounted) {
        setState(() => _loadingDetails[token] = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Partagées avec moi'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/'),
        ),
        actions: [
          IconButton(
            tooltip: 'Voir sur la carte',
            icon: const Icon(Icons.map_outlined),
            onPressed: () {
              // Ouvre la première adresse si disponible
              if (_items.isNotEmpty) {
                context.push('/a/${_items.first.token}');
              }
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: AppSpacing.form,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: AppSpacing.sm),
                        FilledButton(
                          onPressed: _load,
                          child: const Text('Réessayer'),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: _items.isEmpty
                      ? ListView(
                          children: const [
                            SizedBox(height: 120),
                            Center(
                              child: Padding(
                                padding: EdgeInsets.all(24),
                                child: Text(
                                  "Aucune adresse partagée avec toi pour le moment.\n"
                                  "Les adresses reçues par lien apparaissent ici "
                                  "tant que le lien est valide.",
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ],
                        )
                      : ListView.builder(
                          padding: AppSpacing.form,
                          itemCount: _items.length,
                          itemBuilder: (context, i) {
                            final item = _items[i];
                            final token = item.token;
                            final expanded = _expanded.contains(token);
                            final landmarks = _landmarks[token] ?? [];
                            final steps = _steps[token] ?? [];
                            final loading = _loadingDetails[token] == true;

                            return Card(
                              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                              child: Column(
                                children: [
                                  ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor:
                                          theme.colorScheme.primaryContainer,
                                      foregroundColor:
                                          theme.colorScheme.onPrimaryContainer,
                                      backgroundImage: item.photoUrl != null
                                          ? NetworkImage(item.photoUrl!)
                                          : null,
                                      child: item.photoUrl == null
                                          ? const Icon(Icons.share_location)
                                          : null,
                                    ),
                                    title: Text(item.name),
                                    subtitle: Text([
                                      if (item.locality != null &&
                                          item.locality!.isNotEmpty)
                                        item.locality!,
                                      if (item.sharedByName != null &&
                                          item.sharedByName!.isNotEmpty)
                                        'Partagé par ${item.sharedByName}',
                                      item.expiryLabel,
                                    ].join(' · ')),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          tooltip: 'Voir les détails',
                                          icon: Icon(
                                            expanded
                                                ? Icons.expand_less
                                                : Icons.expand_more,
                                          ),
                                          onPressed: () => _toggleExpand(item),
                                        ),
                                        IconButton(
                                          tooltip: 'Ouvrir la fiche complète',
                                          icon: const Icon(Icons.open_in_new),
                                          onPressed: () async {
                                            await context.push('/a/$token');
                                            if (mounted) _load();
                                          },
                                        ),
                                      ],
                                    ),
                                    onTap: () => _toggleExpand(item),
                                  ),
                                  if (expanded) ...[
                                    const Divider(height: 1),
                                    Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              TextButton.icon(
                                                onPressed: () async {
                                                  await context.push('/a/$token');
                                                  if (mounted) _load();
                                                },
                                                icon: const Icon(
                                                    Icons.map_outlined),
                                                label: const Text(
                                                    'Voir sur la carte et fiche complète'),
                                              ),
                                            ],
                                          ),
                                          if (loading) ...[
                                            const SizedBox(height: 8),
                                            const Center(
                                                child:
                                                    CircularProgressIndicator(
                                                        strokeWidth: 2)),
                                          ],
                                          if (!loading && landmarks.isEmpty && steps.isEmpty) ...[
                                            const SizedBox(height: 8),
                                            Text(
                                              'Aucun repère ni étape pour cette adresse.',
                                              style: theme.textTheme.bodySmall
                                                  ?.copyWith(
                                                      color: theme.colorScheme
                                                          .onSurfaceVariant),
                                            ),
                                          ],
                                          if (landmarks.isNotEmpty) ...[
                                            const SizedBox(height: 12),
                                            Text('Repères',
                                                style: theme
                                                    .textTheme.titleSmall),
                                            const SizedBox(height: 8),
                                            ...landmarks.map((l) => Card(
                                                  margin: const EdgeInsets.only(
                                                      bottom: 6),
                                                  child: ListTile(
                                                    dense: true,
                                                    leading: CircleAvatar(
                                                      backgroundImage: l.photoUrl !=
                                                              null
                                                          ? NetworkImage(
                                                              l.photoUrl!)
                                                          : null,
                                                      child: l.photoUrl == null
                                                          ? const Icon(
                                                              Icons.place,
                                                              size: 18)
                                                          : null,
                                                    ),
                                                    title: Text(l.name),
                                                    subtitle: l.description !=
                                                            null
                                                        ? Text(l.description!)
                                                        : null,
                                                  ),
                                                )),
                                          ],
                                          if (steps.isNotEmpty) ...[
                                            const SizedBox(height: 12),
                                            Text('Étapes du trajet',
                                                style: theme
                                                    .textTheme.titleSmall),
                                            const SizedBox(height: 8),
                                            ...steps.map((s) => Card(
                                                  margin: const EdgeInsets.only(
                                                      bottom: 6),
                                                  child: ListTile(
                                                    dense: true,
                                                    leading: CircleAvatar(
                                                        child: Text(
                                                            '${s.stepOrder}')),
                                                    title: Text(s.instruction),
                                                    subtitle: Text([
                                                      if (s.distance != null)
                                                        '${s.distance!.toStringAsFixed(0)} m',
                                                      if (s.direction != null)
                                                        s.direction!,
                                                    ].join(' · ')),
                                                  ),
                                                )),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            );
                          },
                        ),
                ),
    );
  }
}
