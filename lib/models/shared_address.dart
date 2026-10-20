/// Une adresse reçue par un lien de partage, tant que ce lien reste valide.
///
/// Construite depuis le JSON renvoyé par la fonction SQL
/// `get_my_shared_addresses` : le serveur ne retourne que les liens encore
/// actifs (ni expirés ni révoqués) et utilisés par l'utilisateur connecté.
/// Rien n'est copié côté client, la liste est recalculée à chaque ouverture.
class SharedAddressEntry {
  const SharedAddressEntry({
    required this.token,
    required this.expiresAt,
    required this.name,
    this.addressId,
    this.locality,
    this.photoUrl,
    this.sharedByName,
  });

  final String token;
  final DateTime expiresAt;
  final String name;
  final String? addressId;
  final String? locality;
  final String? photoUrl;
  final String? sharedByName;

  factory SharedAddressEntry.fromJson(Map<String, dynamic> json) {
    final address =
        (json['address'] as Map<String, dynamic>?) ?? const <String, dynamic>{};
    final sharedBy = json['shared_by'] as Map<String, dynamic>?;

    return SharedAddressEntry(
      token: json['token'] as String,
      expiresAt: DateTime.parse(json['expires_at'] as String),
      name: (address['name'] as String?) ?? 'Adresse partagée',
      addressId: address['id'] as String?,
      locality: address['locality'] as String?,
      photoUrl: address['photo_url'] as String?,
      sharedByName: (sharedBy?['name'] as String?) ?? json['owner_name'] as String?,
    );
  }

  /// Instants restants avant expiration. Négatif : le lien est mort mais le
  /// serveur n'a pas encore été interrogé pour le retirer.
  Duration get timeLeft => expiresAt.difference(DateTime.now());

  bool get isExpired => timeLeft.isNegative;

  /// Libellé du compte à rebours, du plus lisible au moins.
  String get expiryLabel {
    final left = timeLeft;
    if (left.isNegative) return 'Lien expiré';
    if (left.inMinutes < 1) return "Expire à l'instant";
    if (left.inHours < 1) return 'Expire dans ${left.inMinutes} min';
    if (left.inHours < 24) return 'Expire dans ${left.inHours} h';
    return 'Expire dans ${left.inDays} j';
  }
}
