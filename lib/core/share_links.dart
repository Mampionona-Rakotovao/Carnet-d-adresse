import '../models/share_link.dart';
import 'supabase_client.dart';

/// Nombre maximum d'identifiants envoyés dans un `inFilter` PostgREST.
const int _idsParLot = 100;

/// Charge des liens et complète leur compteur d'utilisations à partir de
/// `share_link_redemptions`, la table autoritaire des places consommées.
///
/// `share_links.used_count` n'existe pas en base : c'est uniquement un champ du
/// modèle, alimenté ici et dans le panneau de gestion des liens de la même
/// manière. [column] est par exemple `address_id` (panneau de gestion) ou
/// `created_by` (page Bienvenue).
Future<List<ShareLink>> fetchShareLinksWithUsage({
  required String column,
  required String value,
}) async {
  final rows = await supabase
      .from('share_links')
      .select()
      .eq(column, value)
      .order('created_at', ascending: false);

  final links = (rows as List)
      .cast<Map<String, dynamic>>()
      .map(ShareLink.fromJson)
      .toList();
  if (links.isEmpty) return links;

  final counts = <String, int>{};
  final ids = links.map((link) => link.id).toList();
  for (var start = 0; start < ids.length; start += _idsParLot) {
    final end = start + _idsParLot > ids.length ? ids.length : start + _idsParLot;
    final redemptions = await supabase
        .from('share_link_redemptions')
        .select('share_link_id')
        .inFilter('share_link_id', ids.sublist(start, end));

    for (final raw in redemptions as List) {
      final row = raw as Map<String, dynamic>;
      final linkId = row['share_link_id'] as String?;
      if (linkId != null) counts[linkId] = (counts[linkId] ?? 0) + 1;
    }
  }

  return links
      .map((link) => link.copyWith(usedCount: counts[link.id] ?? 0))
      .toList();
}
