import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/shared_with_me.dart';
import '../../core/theme/app_spacing.dart';
import '../../models/shared_address.dart';
import '../../ui/section.dart';
import 'shared_address_tile.dart';

/// Aperçu « Partagées avec moi » sur l'accueil : les derniers liens encore
/// valides, plus un raccourci vers la liste complète.
///
/// Le bloc reste invisible tant qu'il n'y a rien à montrer (chargement, erreur
/// réseau, liste vide) : l'accueil parle d'abord de ses propres adresses, et
/// le menu ⋮ reste le point d'entrée garanti. Une erreur de cette section
/// n'empêche jamais l'accueil de s'afficher.
class SharedWithMeSection extends StatefulWidget {
  const SharedWithMeSection({super.key});

  @override
  State<SharedWithMeSection> createState() => _SharedWithMeScreenState();
}

class _SharedWithMeScreenState extends State<SharedWithMeSection> {
  List<SharedAddressEntry>? _items;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final items = await fetchSharedWithMe();
      if (mounted) setState(() => _items = items);
    } catch (_) {
      // Silencieux volontairement : la section disparaît plutôt que de
      // polluer l'accueil avec une erreur qui ne concerne que le partage.
      if (mounted) setState(() => _items = const []);
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = _items;
    if (items == null || items.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final shown = items.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.lg),
        SectionHeader(
          title: 'Partagées avec moi',
          icon: Icons.group_add_outlined,
          trailing: TextButton(
            onPressed: () => context.push('/shared'),
            child: const Text('Tout voir'),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        for (var i = 0; i < shown.length; i++)
          Padding(
            padding: EdgeInsets.only(
              bottom: i < shown.length - 1 ? AppSpacing.sm : 0,
            ),
            child: SharedAddressTile(
              entry: shown[i],
              // L'adresse s'ouvre en mode détail dans la page des partages :
              // l'entrée est transmise pour éviter un aller-retour inutile.
              onTap: () => context.push('/shared', extra: shown[i]),
            ),
          ),
        if (items.length > shown.length)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Text(
              items.length - shown.length == 1
                  ? 'Et 1 autre adresse partagée'
                  : 'Et ${items.length - shown.length} autres adresses partagées',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
      ],
    );
  }
}
