import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/supabase_client.dart';
import '../../../models/share_link.dart';

/// Panneau de gestion du partage d'une adresse : création de nouveaux
/// liens temporaires et révocation des liens existants.
Future<void> showShareLinkSheet(BuildContext context, {required String addressId}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => _ShareLinkSheet(addressId: addressId),
  );
}

class _ShareLinkSheet extends StatefulWidget {
  final String addressId;
  const _ShareLinkSheet({required this.addressId});

  @override
  State<_ShareLinkSheet> createState() => _ShareLinkSheetState();
}

class _ShareLinkSheetState extends State<_ShareLinkSheet> {
  // Durées proposées, en minutes.
  static const Map<String, int> _durations = {
    '30 minutes': 30,
    '1 heure': 60,
    '2 heures': 120,
    '6 heures': 360,
    '24 heures': 1440,
  };

  String _selectedLabel = '1 heure';
  bool _creating = false;
  String? _error;
  List<ShareLink> _links = [];
  bool _loadingLinks = true;

  @override
  void initState() {
    super.initState();
    _loadLinks();
  }

  Future<void> _loadLinks() async {
    setState(() => _loadingLinks = true);
    try {
      final rows = await supabase
          .from('share_links')
          .select()
          .eq('address_id', widget.addressId)
          .order('created_at', ascending: false);
      setState(() {
        _links = (rows as List).map((r) => ShareLink.fromJson(r)).toList();
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loadingLinks = false);
    }
  }

  Future<void> _createLink() async {
    setState(() {
      _creating = true;
      _error = null;
    });
    try {
      final minutes = _durations[_selectedLabel]!;
      final expiresAt = DateTime.now().toUtc().add(Duration(minutes: minutes));
      final inserted = await supabase
          .from('share_links')
          .insert({
            'address_id': widget.addressId,
            'created_by': supabase.auth.currentUser!.id,
            'expires_at': expiresAt.toIso8601String(),
          })
          .select()
          .single();

      final link = ShareLink.fromJson(inserted);
      await _loadLinks();

      if (mounted) {
        await _shareToken(link.token);
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  Future<void> _shareToken(String token) async {
    // On partage un code court plutôt qu'une URL (pas de domaine déployé
    // pour ce MVP) : le destinataire le colle dans "Ouvrir un lien".
    await Share.share(
      "Voici l'adresse que je partage avec toi.\n"
      "Ouvre l'app \"Carnet d'adresses\" → \"Ouvrir un lien\" et colle ce code :\n\n"
      '$token',
    );
  }

  Future<void> _revoke(ShareLink link) async {
    try {
      await supabase.from('share_links').update({
        'status': 'REVOKED',
        'revoked_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', link.id);
      _loadLinks();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Erreur : $e')));
      }
    }
  }

  Future<void> _showAccessLog(ShareLink link) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Historique des accès'),
        content: SizedBox(
          width: 400,
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _fetchAccessLog(link.id),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  height: 80,
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (snapshot.hasError) {
                return Text('Erreur : ${snapshot.error}');
              }
              final uses = snapshot.data ?? [];
              if (uses.isEmpty) {
                return const Text(
                  "Ce lien n'a encore été consulté par personne.",
                  style: TextStyle(color: Colors.grey),
                );
              }
              return SizedBox(
                height: 300,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: uses.length,
                  itemBuilder: (context, index) {
                    final u = uses[index];
                    final profile = u['profiles'] as Map<String, dynamic>?;
                    final usedAt = DateTime.parse(u['used_at'] as String).toLocal();
                    return ListTile(
                      leading: const Icon(Icons.person_outline),
                      title: Text(profile?['name'] as String? ?? 'Utilisateur inconnu'),
                      subtitle: Text(
                        '${profile?['email'] ?? ''}\n'
                        '${usedAt.toString().substring(0, 16)}',
                      ),
                      isThreeLine: true,
                    );
                  },
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _fetchAccessLog(String shareLinkId) async {
    final rows = await supabase
        .from('share_link_uses')
        .select('used_at, profiles(name, email)')
        .eq('share_link_id', shareLinkId)
        .order('used_at', ascending: false);
    return (rows as List).cast<Map<String, dynamic>>();
  }

  String _statusLabel(ShareLink l) {
    if (l.status == ShareLinkStatus.revoked) return 'Révoqué';
    if (!l.isEffectivelyActive) return 'Expiré';
    return 'Actif';
  }

  Color _statusColor(ShareLink l) {
    if (l.status == ShareLinkStatus.revoked) return Colors.grey;
    if (!l.isEffectivelyActive) return Colors.orange;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Partager cette adresse', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedLabel,
                      decoration: const InputDecoration(
                        labelText: 'Durée de validité',
                        border: OutlineInputBorder(),
                      ),
                      items: _durations.keys
                          .map((label) => DropdownMenuItem(value: label, child: Text(label)))
                          .toList(),
                      onChanged: (v) => setState(() => _selectedLabel = v!),
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: _creating ? null : _createLink,
                    icon: _creating
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.link),
                    label: const Text('Créer'),
                  ),
                ],
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(_error!, style: const TextStyle(color: Colors.red)),
                ),
              const SizedBox(height: 16),
              const Divider(),
              Text('Liens existants', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              Expanded(
                child: _loadingLinks
                    ? const Center(child: CircularProgressIndicator())
                    : _links.isEmpty
                        ? const Center(
                            child: Text(
                              'Aucun lien créé pour le moment.',
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        : ListView.builder(
                            controller: scrollController,
                            itemCount: _links.length,
                            itemBuilder: (context, index) {
                              final l = _links[index];
                              return Card(
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: _statusColor(l).withOpacity(0.15),
                                    child: Icon(Icons.link, color: _statusColor(l), size: 18),
                                  ),
                                  title: Text(_statusLabel(l)),
                                  subtitle: Text(
                                    'Code : ${l.token.substring(0, 8)}...\n'
                                    'Expire : ${l.expiresAt.toLocal().toString().substring(0, 16)}',
                                  ),
                                  isThreeLine: true,
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.history, size: 20),
                                        tooltip: 'Historique des accès',
                                        onPressed: () => _showAccessLog(l),
                                      ),
                                      if (l.isEffectivelyActive) ...[
                                        IconButton(
                                          icon: const Icon(Icons.share, size: 20),
                                          tooltip: 'Repartager',
                                          onPressed: () => _shareToken(l.token),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.block, size: 20),
                                          tooltip: 'Révoquer',
                                          onPressed: () => _revoke(l),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        );
      },
    );
  }
}