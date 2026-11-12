import 'dart:async';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/supabase_client.dart';
import '../../../models/share_link.dart';
import '../../../ui/app_feedback.dart';
import '../../help/widgets/contextual_help_button.dart';

/// Panneau de gestion du partage d'une adresse : création de nouveaux
/// liens temporaires et révocation des liens existants.
Future<void> showShareLinkSheet(BuildContext context,
    {required String addressId}) {
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
  static const Map<String, int?> _maxUsesOptions = {
    '1 personne': 1,
    '3 personnes': 3,
    '5 personnes': 5,
    'Illimité': null,
  };

  /// Domaine des App Links (voir AndroidManifest.xml et assetlinks.json).
  static const _shareBaseUrl = 'https://mampionona-rakotovao.github.io/a/';

  ExpirationLien _selectedExpiration = ExpirationLien.j7;
  String _selectedMaxUsesLabel = '1 personne';
  bool _creating = false;
  String? _error;
  List<ShareLink> _links = [];
  bool _loadingLinks = true;
  final Set<String> _revoking = {};
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _loadLinks();
    _countdownTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadLinks() async {
    setState(() => _loadingLinks = true);
    try {
      final rows = await supabase
          .from('share_links')
          .select()
          .eq('address_id', widget.addressId)
          .order('created_at', ascending: false);

      final links = (rows as List).map((r) => ShareLink.fromJson(r)).toList();

      final counts = <String, int>{};
      if (links.isNotEmpty) {
        final ids = links.map((l) => l.id).toList();
        final redemptions = await supabase
            .from('share_link_redemptions')
            .select('share_link_id')
            .inFilter('share_link_id', ids);
        for (final raw in redemptions as List) {
          final row = raw as Map<String, dynamic>;
          final linkId = row['share_link_id'] as String?;
          if (linkId != null) counts[linkId] = (counts[linkId] ?? 0) + 1;
        }
      }

      if (!mounted) return;
      setState(() {
        _links = links
            .map((link) => link.copyWith(usedCount: counts[link.id] ?? 0))
            .toList();
      });
    } catch (e) {
      if (!mounted) return;
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
      final result = await supabase.rpc(
        'create_share_link',
        params: {
          'p_address_id': widget.addressId,
          'p_max_uses': _maxUsesOptions[_selectedMaxUsesLabel],
          'p_duration_minutes': _selectedExpiration.minutes,
        },
      );
      final data = result is Map
          ? result.cast<String, dynamic>()
          : const <String, dynamic>{};

      if (data['ok'] != true || data['link'] is! Map) {
        if (!mounted) return;
        setState(
            () => _error = _creationErrorMessage(data['error'] as String?));
        return;
      }

      final link = ShareLink.fromJson(
        (data['link'] as Map).cast<String, dynamic>(),
      );
      await _loadLinks();

      if (mounted) {
        await _shareToken(link.token);
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  String _creationErrorMessage(String? code) {
    switch (code) {
      case 'invalid_duration':
        return 'Durée de validité invalide.';
      case 'invalid_max_uses':
        return 'Nombre de personnes invalide.';
      case 'auth_required':
        return 'Connecte-toi pour créer un lien.';
      case 'not_found':
        return "Impossible de partager cette adresse : elle n'existe plus.";
      default:
        return 'Création du lien impossible. Réessayez.';
    }
  }

  Future<void> _shareToken(String token) async {
    final link = '$_shareBaseUrl$token';
    await Share.share(
      "📍 Une adresse a été partagée avec toi sur Carnet d'adresses.\n\n"
      "Appuie sur le lien pour l'ouvrir :\n$link",
    );
  }

  Future<void> _revoke(ShareLink link) async {
    if (_revoking.contains(link.id)) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Révoquer ce lien ?'),
        content: const Text(
          'Le lien ne fonctionnera plus pour les personnes qui le possèdent.',
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Annuler'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.tonal(
                  style: FilledButton.styleFrom(
                    foregroundColor: Colors.red,
                    backgroundColor: Colors.red.shade50,
                  ),
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: const Text('Révoquer'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _revoking.add(link.id));
    try {
      final result = await supabase.rpc(
        'revoke_share_link',
        params: {'p_link_id': link.id},
      );
      final data = result is Map
          ? result.cast<String, dynamic>()
          : const <String, dynamic>{};

      if (data['ok'] != true) {
        if (!mounted) return;
        AppSnack.error(
          context,
          Exception(data['error'] ?? 'not_found'),
          fallback: 'Révocation impossible. Réessayez.',
        );
        return;
      }

      await _loadLinks();
      if (mounted) AppSnack.success(context, 'Lien révoqué.');
    } catch (e) {
      if (!mounted) return;
      AppSnack.error(
        context,
        e,
        fallback: 'Révocation impossible. Réessayez.',
      );
    } finally {
      if (mounted) setState(() => _revoking.remove(link.id));
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
                    final usedAt =
                        DateTime.parse(u['used_at'] as String).toLocal();
                    return ListTile(
                      leading: const Icon(Icons.person_outline),
                      title: Text(
                          profile?['name'] as String? ?? 'Utilisateur inconnu'),
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
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Fermer'),
            ),
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
    if (l.isExpired) return 'Expiré';
    if (l.isFull) return 'Complet';
    return 'Actif';
  }

  Color _statusColor(BuildContext context, ShareLink l) {
    if (l.status == ShareLinkStatus.revoked) return Colors.grey;
    if (l.isExpired) return Theme.of(context).colorScheme.error;
    if (l.isFull) return Colors.orange;
    return Colors.green;
  }

  String _expiryLabel(ShareLink l) => expirationLabel(l.expiresAt);

  String _usesLabel(ShareLink l) {
    if (l.maxUses == null) {
      return '${l.usedCount} utilisation(s) · Illimité';
    }
    return '${l.usedCount} sur ${l.maxUses} personnes';
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      minChildSize: 0.45,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text('Partager cette adresse',
                        style: Theme.of(context).textTheme.titleMedium),
                  ),
                  const ContextualHelpButton(
                    articleIds: [
                      'creer-partage',
                      'duree-partage',
                      'personnes-partage',
                      'revoquer-partage',
                    ],
                    title: 'Aide sur le partage',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _selectedMaxUsesLabel,
                decoration: const InputDecoration(
                  labelText: 'Nombre de personnes',
                  border: OutlineInputBorder(),
                ),
                items: _maxUsesOptions.keys
                    .map((label) =>
                        DropdownMenuItem(value: label, child: Text(label)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedMaxUsesLabel = v!),
              ),
              const SizedBox(height: 12),
              Text(
                'Durée de validité',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ExpirationLien.values.map((expiration) {
                  return ChoiceChip(
                    label: Text(expiration.libelle),
                    selected: _selectedExpiration == expiration,
                    onSelected: (_) {
                      setState(() => _selectedExpiration = expiration);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _creating ? null : _createLink,
                icon: _creating
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.link),
                label: const Text('Créer le lien'),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child:
                      Text(_error!, style: const TextStyle(color: Colors.red)),
                ),
              const SizedBox(height: 12),
              const Divider(),
              Text('Liens existants',
                  style: Theme.of(context).textTheme.titleSmall),
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
                                    backgroundColor: _statusColor(context, l)
                                        .withValues(alpha: 0.15),
                                    child: Icon(Icons.link,
                                        color: _statusColor(context, l),
                                        size: 18),
                                  ),
                                  title: Text(_statusLabel(l)),
                                  subtitle: Text(
                                    'Code : ${l.token.substring(0, 8)}...\n'
                                    '${_usesLabel(l)} · ${_expiryLabel(l)}',
                                  ),
                                  isThreeLine: true,
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon:
                                            const Icon(Icons.history, size: 20),
                                        tooltip: 'Historique des accès',
                                        onPressed: () => _showAccessLog(l),
                                      ),
                                      if (l.isEffectivelyActive)
                                        IconButton(
                                          icon:
                                              const Icon(Icons.share, size: 20),
                                          tooltip: 'Repartager',
                                          onPressed: () => _shareToken(l.token),
                                        ),
                                      if (l.status != ShareLinkStatus.revoked)
                                        IconButton(
                                          icon: _revoking.contains(l.id)
                                              ? const SizedBox(
                                                  height: 18,
                                                  width: 18,
                                                  child:
                                                      CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                  ),
                                                )
                                              : const Icon(Icons.block,
                                                  size: 20),
                                          tooltip: 'Révoquer',
                                          onPressed: _revoking.contains(l.id)
                                              ? null
                                              : () => _revoke(l),
                                        ),
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
