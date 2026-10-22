import '../models/shared_address.dart';
import 'supabase_client.dart';

/// Adresses reçues par lien de partage et encore valides.
///
/// RG20-RG21 : aucune décision de validité n'est prise côté client. C'est la
/// fonction SQL `get_my_shared_addresses` qui écarte les liens expirés ou
/// révoqués ; l'application n'affiche que ce que le serveur renvoie, et la
/// liste est recalculée à chaque appel.
Future<List<SharedAddressEntry>> fetchSharedWithMe() async {
  final result = await supabase.rpc('get_my_shared_addresses');
  final rows = (result as List? ?? []).cast<Map<String, dynamic>>();
  return rows.map(SharedAddressEntry.fromJson).toList();
}

/// Enregistre l'ouverture d'un lien partagé pour l'utilisateur connecté.
/// Retourne true si l'enregistrement a réussi (idempotent côté SQL).
/// Ne lance jamais d'exception pour ne pas casser l'affichage de l'adresse.
Future<bool> recordShareOpen(String token) async {
  try {
    await supabase.rpc('record_share_open', params: {'p_token': token});
    return true;
  } catch (_) {
    return false;
  }
}
