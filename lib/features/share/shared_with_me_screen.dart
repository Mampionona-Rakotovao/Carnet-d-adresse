import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/shared_with_me.dart';
import '../../core/theme/app_spacing.dart';
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
                            return Card(
                              child: ListTile(
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
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () async {
                                  await context.push('/a/${item.token}');
                                  if (mounted) _load();
                                },
                              ),
                            );
                          },
                        ),
                ),
    );
  }
}
