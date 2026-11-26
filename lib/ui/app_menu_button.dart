import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/screen_security.dart';
import '../core/supabase_client.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/theme_mode_controller.dart';

/// Menu « Plus d'options » partagé entre les écrans du shell.
///
/// Regroupe les réglages d'apparence et les actions courantes (ajout,
/// partages reçus, aide, déconnexion). Toutes ces actions dépendent uniquement
/// du `BuildContext` du shell, de la portée [ThemeModeScope] (placée au-dessus
/// de `MaterialApp`) et du client Supabase global : elles restent valables
/// depuis n'importe quel onglet, y compris l'accueil.
class AppMenuButton extends StatelessWidget {
  const AppMenuButton({super.key});

  static const String tooltip = 'Plus d\'options';

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: tooltip,
      button: true,
      child: Tooltip(
        message: tooltip,
        child: PopupMenuButton<String>(
          // `Tooltip` porte le libellé accessible : on évite le doublon
          // sémantique avec celui du bouton Material.
          tooltip: '',
          icon: const Icon(Icons.more_vert),
          // Zone tactile 48 dp minimum, sans empiéter sur la barre d'état.
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          onSelected: (value) => _onSelected(context, value),
          itemBuilder: (context) => _items(context),
        ),
      ),
    );
  }

  Future<void> _onSelected(BuildContext context, String value) async {
    final mode = ThemeMode.values.asNameMap()[value];
    if (mode != null) {
      await ThemeModeScope.set(context, mode);
      return;
    }
    switch (value) {
      case 'add_address':
        context.push('/address/create');
      case 'shared_with_me':
        context.push('/shared');
      case 'help':
        context.push('/aide');
      case 'logout':
        await _confirmLogout(context);
    }
  }

  Future<void> _confirmLogout(BuildContext context) async {
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
    if (confirmed == true && context.mounted) {
      await supabase.auth.signOut();
      await screenSecurity.reset();
    }
  }

  List<PopupMenuEntry<String>> _items(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return [
      PopupMenuItem<String>(
        enabled: false,
        child: Text(
          'Apparence',
          style: theme.textTheme.labelSmall
              ?.copyWith(color: scheme.onSurfaceVariant),
        ),
      ),
      for (final mode in ThemeModeController.choices)
        CheckedPopupMenuItem<String>(
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
      const PopupMenuItem<String>(
        value: 'add_address',
        child: ListTile(
          leading: Icon(Icons.add),
          title: Text('Ajouter une adresse'),
          contentPadding: EdgeInsets.zero,
        ),
      ),
      const PopupMenuItem<String>(
        value: 'shared_with_me',
        child: ListTile(
          leading: Icon(Icons.share_location),
          title: Text('Partagées avec moi'),
          contentPadding: EdgeInsets.zero,
        ),
      ),
      const PopupMenuItem<String>(
        value: 'help',
        child: ListTile(
          leading: Icon(Icons.help_outline),
          title: Text('Aide'),
          contentPadding: EdgeInsets.zero,
        ),
      ),
      const PopupMenuItem<String>(
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
  }
}
