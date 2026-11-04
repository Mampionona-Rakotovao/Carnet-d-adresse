enum ExpirationLien {
  min30('30 minutes', 30),
  h1('1 heure', 60),
  h2('2 heures', 120),
  h5('5 heures', 300),
  h12('12 heures', 720),
  h24('24 heures', 1440),
  j7('7 jours', 10080),
  j30('30 jours', 43200),
  jamais('Jamais', null);

  const ExpirationLien(this.libelle, this.minutes);

  final String libelle;
  final int? minutes;
}

const _moisAbreviations = [
  'janv.',
  'févr.',
  'mars',
  'avr.',
  'mai',
  'juin',
  'juil.',
  'août',
  'sept.',
  'oct.',
  'nov.',
  'déc.',
];

String _deuxChiffres(int valeur) => valeur.toString().padLeft(2, '0');

String formatExpirationDate(DateTime date) {
  final local = date.toLocal();
  return 'le ${local.day} ${_moisAbreviations[local.month - 1]} '
      'à ${_deuxChiffres(local.hour)}:${_deuxChiffres(local.minute)}';
}

String formatRemainingDuration(Duration duration) {
  if (duration.inMinutes < 1) return "moins d'une minute";

  final hours = duration.inHours;
  final minutes = duration.inMinutes % 60;

  if (hours == 0) return '$minutes min';
  if (minutes == 0) return '$hours h';
  return '$hours h $minutes min';
}

String expirationLabel(DateTime? expiresAt, {DateTime? now}) {
  if (expiresAt == null) return 'Sans expiration';

  final remaining = expiresAt.difference(now ?? DateTime.now());
  if (remaining <= Duration.zero) return 'Expiré';

  if (remaining > const Duration(hours: 24)) {
    return 'Expire ${formatExpirationDate(expiresAt)}';
  }
  return 'Expire dans ${formatRemainingDuration(remaining)}';
}

String? recipientExpirationNotice(DateTime? expiresAt, {DateTime? now}) {
  if (expiresAt == null) return null;

  final remaining = expiresAt.difference(now ?? DateTime.now());
  if (remaining <= Duration.zero) return 'Ce lien a expiré';

  if (remaining < const Duration(hours: 24)) {
    return 'Ce lien expire dans ${formatRemainingDuration(remaining)}';
  }
  return null;
}

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
  final DateTime? expiresAt;
  final int? maxUses;
  final int usedCount;
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
    this.maxUses,
    this.usedCount = 0,
    this.revokedAt,
  });

  factory ShareLink.fromJson(Map<String, dynamic> json) => ShareLink(
        id: json['id'] as String,
        addressId: json['address_id'] as String,
        createdBy: json['created_by'] as String,
        token: json['token'] as String,
        status: ShareLinkStatusX.fromDb(json['status'] as String),
        expiresAt: json['expires_at'] != null
            ? DateTime.parse(json['expires_at'] as String)
            : null,
        maxUses: (json['max_uses'] as num?)?.toInt(),
        usedCount: (json['used_count'] as num?)?.toInt() ?? 0,
        createdAt: DateTime.parse(json['created_at'] as String),
        revokedAt: json['revoked_at'] != null
            ? DateTime.parse(json['revoked_at'] as String)
            : null,
      );

  ShareLink copyWith({int? usedCount}) => ShareLink(
        id: id,
        addressId: addressId,
        createdBy: createdBy,
        token: token,
        status: status,
        expiresAt: expiresAt,
        maxUses: maxUses,
        usedCount: usedCount ?? this.usedCount,
        createdAt: createdAt,
        revokedAt: revokedAt,
      );

  bool get isExpired =>
      status == ShareLinkStatus.expired ||
      (expiresAt != null && !expiresAt!.isAfter(DateTime.now()));

  bool get isFull => maxUses != null && usedCount >= maxUses!;

  bool get isEffectivelyActive =>
      status == ShareLinkStatus.active && !isExpired && !isFull;
}
