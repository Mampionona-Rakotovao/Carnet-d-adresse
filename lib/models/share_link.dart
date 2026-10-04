enum ShareLinkStatus { active, expired, revoked }

extension ShareLinkStatusX on ShareLinkStatus {
  String toDb() {
    switch (this) {
      case ShareLinkStatus.active:
        return 'ACTIVE';
      case ShareLinkStatus.expired:
        return 'EXPIRED';
      case ShareLinkStatus.revoked:
        return 'REVOKED';
    }
  }

  static ShareLinkStatus fromDb(String v) {
    switch (v) {
      case 'EXPIRED':
        return ShareLinkStatus.expired;
      case 'REVOKED':
        return ShareLinkStatus.revoked;
      default:
        return ShareLinkStatus.active;
    }
  }
}

class ShareLink {
  final String id;
  final String addressId;
  final String createdBy;
  final String token;
  final ShareLinkStatus status;
  final DateTime expiresAt;
  final DateTime createdAt;
  final DateTime? revokedAt;

  ShareLink({
    required this.id,
    required this.addressId,
    required this.createdBy,
    required this.token,
    required this.status,
    required this.expiresAt,
    required this.createdAt,
    this.revokedAt,
  });

  factory ShareLink.fromJson(Map<String, dynamic> json) => ShareLink(
        id: json['id'] as String,
        addressId: json['address_id'] as String,
        createdBy: json['created_by'] as String,
        token: json['token'] as String,
        status: ShareLinkStatusX.fromDb(json['status'] as String),
        expiresAt: DateTime.parse(json['expires_at'] as String),
        createdAt: DateTime.parse(json['created_at'] as String),
        revokedAt: json['revoked_at'] != null
            ? DateTime.parse(json['revoked_at'] as String)
            : null,
      );

  /// Un lien ACTIVE dont la date d'expiration est dépassée doit être
  /// traité comme expiré côté affichage, même avant que le serveur
  /// n'ait mis à jour la colonne status (le serveur le fait au moment
  /// de la consultation via le lien, pas en continu).
  bool get isEffectivelyActive =>
      status == ShareLinkStatus.active && expiresAt.isAfter(DateTime.now());
}