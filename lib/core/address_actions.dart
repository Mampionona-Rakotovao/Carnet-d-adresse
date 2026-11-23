import 'package:flutter/material.dart';

import '../core/theme/app_spacing.dart';
import '../models/address.dart';
import 'photo_storage.dart';
import 'supabase_client.dart';

/// Confirmation de suppression d'une adresse, partagée entre la fiche de détail
/// et le menu « ⋮ » des cartes : même titre, même message, mêmes libellés.
Future<bool> confirmAddressDeletion(BuildContext context, Address address) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) {
      final scheme = Theme.of(context).colorScheme;
      const compact = ButtonStyle(
        minimumSize: WidgetStatePropertyAll(Size(0, 44)),
        padding: WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        ),
      );
      return AlertDialog(
        title: const Text('Supprimer cette adresse ?'),
        content: Text(
          'Cette action est irréversible : "${address.name}" et toutes ses '
          'données associées (repères, étapes, favoris, liens de partage) '
          'seront supprimés.',
        ),
        actionsPadding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.xs,
          AppSpacing.md,
          AppSpacing.md,
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: compact,
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Annuler'),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: FilledButton(
                  style: compact.copyWith(
                    foregroundColor: WidgetStatePropertyAll(scheme.onError),
                    backgroundColor: WidgetStatePropertyAll(scheme.error),
                  ),
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Supprimer'),
                ),
              ),
            ],
          ),
        ],
      );
    },
  );
  return confirmed ?? false;
}

/// Supprime l'adresse et son dossier photos.
///
/// Lève une [StateError] si aucune ligne n'a été supprimée (droits insuffisants
/// ou adresse déjà disparue) pour que l'appelant affiche un message lisible.
Future<void> deleteAddressRow(Address address) async {
  final addressId = address.id;
  if (addressId == null) return;

  final deleted = await supabase
      .from('addresses')
      .delete()
      .eq('id', addressId)
      .select();

  if ((deleted as List).isEmpty) {
    throw StateError(
      "Suppression impossible : l'adresse n'a pas été supprimée. "
      'Vérifiez vos droits puis réessayez.',
    );
  }

  await removePhotoFolder(addressId);
}
