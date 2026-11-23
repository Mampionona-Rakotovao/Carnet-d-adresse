import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/address_actions.dart';
import '../core/address_refresh.dart';
import '../core/app_haptics.dart';
import '../core/favorites.dart';
import '../core/supabase_client.dart';
import '../features/address_detail/widgets/share_link_sheet.dart';
import '../models/address.dart';
import 'app_feedback.dart';

enum _AddressMenuAction { favorite, share, edit, delete }

/// Menu « ⋮ » d'une carte d'adresse, identique dans l'onglet Adresses et dans
/// les adresses récentes de la page Accueil.
///
/// Le widget exécute lui-même les actions (favori, partage, modification,
/// suppression) et prévient le reste de l'application via
/// [notifyAddressDataChanged] : aucun écran ne garde une copie obsolète.
class AddressActionsMenu extends StatefulWidget {
  const AddressActionsMenu({
    super.key,
    required this.address,
    required this.isFavorite,
    required this.onFavoriteChanged,
    required this.onDeleted,
  });

  final Address address;

  /// État connu du favori, fourni par l'écran qui affiche la carte.
  final bool isFavorite;

  /// Mise à jour optimiste de l'étoile, avant l'écriture en base.
  final ValueChanged<bool> onFavoriteChanged;

  /// Retrait immédiat de la carte après une suppression confirmée.
  final ValueChanged<Address> onDeleted;

  @override
  State<AddressActionsMenu> createState() => _AddressActionsMenuState();
}

class _AddressActionsMenuState extends State<AddressActionsMenu> {
  bool _busy = false;

  /// Comme dans la fiche de détail : les actions de gestion sont réservées au
  /// propriétaire. Le favori reste disponible pour tous.
  bool get _isOwner =>
      widget.address.ownerId == supabase.auth.currentUser?.id;

  Future<void> _toggleFavorite() async {
    final addressId = widget.address.id;
    if (addressId == null) return;

    final previous = widget.isFavorite;
    widget.onFavoriteChanged(!previous);
    try {
      await toggleFavorite(addressId, previous);
    } catch (e) {
      debugPrint('AddressActionsMenu._toggleFavorite → $e');
      if (!mounted) return;
      widget.onFavoriteChanged(previous);
      AppSnack.error(context, e,
          fallback: 'Impossible de modifier les favoris. Réessayez.');
      return;
    }
    if (!mounted) return;
    notifyAddressDataChanged();
  }

  Future<void> _share() async {
    final addressId = widget.address.id;
    if (addressId == null) return;

    await showShareLinkSheet(context, addressId: addressId);
    if (!mounted) return;
    notifyAddressDataChanged();
  }

  Future<void> _edit() async {
    final addressId = widget.address.id;
    if (addressId == null) return;

    await context.push<bool>('/address/$addressId/edit', extra: widget.address);
    if (!mounted) return;
    notifyAddressDataChanged();
  }

  Future<void> _delete() async {
    if (_busy) return;
    final confirmed = await confirmAddressDeletion(context, widget.address);
    if (!confirmed || !mounted) return;

    if (!mounted) return;
    setState(() => _busy = true);
    try {
      await deleteAddressRow(widget.address);
    } catch (e) {
      debugPrint('AddressActionsMenu._delete → $e');
      if (!mounted) return;
      AppSnack.error(context, e,
          fallback:
              "Suppression impossible. Vérifiez votre connexion et réessayez.");
      return;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    if (!mounted) return;

    widget.onDeleted(widget.address);
    notifyAddressDataChanged();
    if (!mounted) return;
    AppSnack.success(context, 'Adresse supprimée.');
  }

  Future<void> _onSelected(_AddressMenuAction action) async {
    switch (action) {
      case _AddressMenuAction.favorite:
        await _toggleFavorite();
      case _AddressMenuAction.share:
        await _share();
      case _AddressMenuAction.edit:
        await _edit();
      case _AddressMenuAction.delete:
        await _delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final favoriteLabel = widget.isFavorite
        ? 'Retirer des favoris'
        : 'Ajouter aux favoris';

    return Semantics(
      button: true,
      container: true,
      label: "Plus d'actions",
      child: PopupMenuButton<_AddressMenuAction>(
        icon: const Icon(Icons.more_vert),
        tooltip: "Plus d'actions",
        enabled: !_busy,
        padding: EdgeInsets.zero,
        // 48 dp minimum, sans empiéter sur l'appui de la carte elle-même.
        style: IconButton.styleFrom(
          minimumSize: const Size.square(48),
          tapTargetSize: MaterialTapTargetSize.padded,
        ),
        onOpened: () => AppHaptics.selectionClick(),
        onSelected: (action) => _onSelected(action),
        itemBuilder: (context) => [
          PopupMenuItem(
            value: _AddressMenuAction.favorite,
            child: ListTile(
              leading: Icon(widget.isFavorite ? Icons.star : Icons.star_outline),
              title: Text(favoriteLabel),
              contentPadding: EdgeInsets.zero,
            ),
          ),
          if (_isOwner) ...[
            const PopupMenuItem(
              value: _AddressMenuAction.share,
              child: ListTile(
                leading: Icon(Icons.share_outlined),
                title: Text('Partager'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: _AddressMenuAction.edit,
              child: ListTile(
                leading: Icon(Icons.edit),
                title: Text('Modifier'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem(
              value: _AddressMenuAction.delete,
              child: ListTile(
                leading: Icon(Icons.delete_outline, color: Colors.red),
                title: Text(
                  'Supprimer',
                  style: TextStyle(color: Colors.red),
                ),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
