import 'package:flutter/foundation.dart';
import 'supabase_client.dart';

const _bucket = 'photos';

/// Supprime un fichier du bucket à partir de son URL publique.
///
/// Le nettoyage est volontairement « best effort » : si Storage est
/// indisponible, l'opération métier (suppression de la ligne) reste valide.
Future<void> removePhotoAtUrl(String? url) async {
  if (url == null || url.isEmpty) return;

  try {
    final uri = Uri.tryParse(url);
    if (uri == null) return;

    final segments = uri.pathSegments;
    final bucketIndex = segments.indexOf(_bucket);
    if (bucketIndex < 0 || bucketIndex >= segments.length - 1) return;

    final path = segments.sublist(bucketIndex + 1).join('/');
    if (path.isEmpty) return;

    await supabase.storage.from(_bucket).remove([path]);
  } catch (e) {
    debugPrint('Nettoyage photo impossible ($url) : $e');
  }
}

/// Supprime tous les fichiers d'un dossier (les photos d'une adresse et de
/// ses repères sont rangées sous `photos/<addressId>/`).
Future<void> removePhotoFolder(String folder) async {
  if (folder.isEmpty) return;

  try {
    final files = await supabase.storage.from(_bucket).list(path: folder);
    final paths = files
        .where((file) => file.name.isNotEmpty)
        .map((file) => '$folder/${file.name}')
        .toList();

    if (paths.isNotEmpty) {
      await supabase.storage.from(_bucket).remove(paths);
    }
  } catch (e) {
    debugPrint('Nettoyage du dossier photos $folder impossible : $e');
  }
}
