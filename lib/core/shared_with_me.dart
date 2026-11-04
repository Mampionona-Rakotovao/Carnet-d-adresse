import '../models/address.dart';
import '../models/landmark.dart';
import '../models/route_step.dart';
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

/// Résultat de l'ouverture d'un lien partagé.
///
/// La place n'est consommée que si [ok] est true. Un compte déjà enregistré
/// peut rouvrir le lien sans nouvelle consommation.
class ShareRedeemResult {
  const ShareRedeemResult({
    required this.ok,
    this.error,
    this.address,
    this.landmarks = const [],
    this.steps = const [],
    this.expiresAt,
    this.maxUses,
    this.usedCount,
    this.remaining,
    this.alreadyRedeemed = false,
    this.isOwner = false,
  });

  final bool ok;
  final String? error;
  final Address? address;
  final List<Landmark> landmarks;
  final List<RouteStep> steps;
  final DateTime? expiresAt;
  final int? maxUses;
  final int? usedCount;
  final int? remaining;
  final bool alreadyRedeemed;
  final bool isOwner;

  factory ShareRedeemResult.fromJson(Map<String, dynamic> json) {
    if (json['ok'] != true) {
      return ShareRedeemResult(
        ok: false,
        error: json['error'] as String? ?? 'not_found',
      );
    }

    final addressJson = json['address'] as Map<String, dynamic>?;
    return ShareRedeemResult(
      ok: true,
      address: addressJson == null ? null : Address.fromJson(addressJson),
      landmarks: ((json['landmarks'] as List?) ?? [])
          .map((row) => Landmark.fromJson(row as Map<String, dynamic>))
          .toList(),
      steps: ((json['steps'] as List?) ?? [])
          .map((row) => RouteStep.fromJson(row as Map<String, dynamic>))
          .toList(),
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'] as String)
          : null,
      maxUses: (json['max_uses'] as num?)?.toInt(),
      usedCount: (json['used_count'] as num?)?.toInt(),
      remaining: (json['remaining'] as num?)?.toInt(),
      alreadyRedeemed: json['already_redeemed'] == true,
      isOwner: json['is_owner'] == true,
    );
  }
}

/// Ouvre un lien partagé et consomme une place si nécessaire.
///
/// Toute la décision (existence, expiration, révocation, limite, idempotence)
/// est prise par la fonction SQL `redeem_share_link`, sous verrou. Le client
/// ne fait qu'afficher le résultat.
Future<ShareRedeemResult> redeemShareLink(String token) async {
  final raw = await supabase.rpc(
    'redeem_share_link',
    params: {'p_token': token},
  );

  if (raw is Map) {
    return ShareRedeemResult.fromJson(raw.cast<String, dynamic>());
  }
  return const ShareRedeemResult(ok: false, error: 'not_found');
}

/// Message utilisateur associé aux codes d'erreur renvoyés par le serveur.
String shareRedeemErrorMessage(String? code) {
  switch (code) {
    case 'auth_required':
      return 'Connecte-toi pour ouvrir cette adresse.';
    case 'expired':
      return 'Ce lien a expiré. Demande un nouveau lien au propriétaire.';
    case 'revoked':
      return 'Ce lien a été désactivé par son auteur.';
    case 'full':
      return 'Ce lien a déjà été utilisé par le nombre de personnes autorisé.';
    default:
      return 'Lien invalide. Vérifie le lien ou demande-en un nouveau.';
  }
}
