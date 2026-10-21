import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/supabase_client.dart';
import '../../core/theme/app_spacing.dart';

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
  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await supabase.rpc('get_my_shared_addresses');
      final list = (result as List? ?? []).cast<Map<String, dynamic>>();
      if (mounted) setState(() => _items = list);
    } catch (e) {
      if (mounted) setState(() => _error = 'Erreur : $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _remaining(String expiresAtIso) {
    final diff =
        DateTime.parse(expiresAtIso).difference(DateTime.now().toUtc());
    if (diff.inMinutes < 1) return "Expire à l'instant";
    if (diff.inHours < 1) return 'Expire dans ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Expire dans ${diff.inHours} h';
    return 'Expire dans ${diff.inDays} j';
  }

  @override
  Widget build(BuildContext context) {
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
                            final a = item['address'] as Map<String, dynamic>;
                            return Card(
                              child: ListTile(
                                leading: const CircleAvatar(
                                  child: Icon(Icons.share_location),
                                ),
                                title: Text(a['name'] as String? ?? ''),
                                subtitle: Text([
                                  if (a['locality'] != null)
                                    a['locality'] as String,
                                  _remaining(item['expires_at'] as String),
                                ].join(' · ')),
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () async {
                                  await context.push('/a/${item['token']}');
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