enum GpsType { exact, accessPoint }

enum AddressVisibility { public, private }

extension GpsTypeX on GpsType {
  String toDb() => this == GpsType.exact ? 'EXACT' : 'ACCESS_POINT';
  static GpsType fromDb(String v) =>
      v == 'EXACT' ? GpsType.exact : GpsType.accessPoint;
}

extension AddressVisibilityX on AddressVisibility {
  String toDb() => this == AddressVisibility.public ? 'PUBLIC' : 'PRIVATE';
  static AddressVisibility fromDb(String v) =>
      v == 'PUBLIC' ? AddressVisibility.public : AddressVisibility.private;
}

class Address {
  final String? id; // null tant que non enregistrée en base
  final String ownerId;
  final String name;
  final String? description;
  final String? locality;
  final AddressVisibility visibility;
  final double latitude;
  final double longitude;
  final GpsType gpsType;
  final DateTime? createdAt;

  Address({
    this.id,
    required this.ownerId,
    required this.name,
    this.description,
    this.locality,
    this.visibility = AddressVisibility.private,
    required this.latitude,
    required this.longitude,
    this.gpsType = GpsType.exact,
    this.createdAt,
  });

  factory Address.fromJson(Map<String, dynamic> json) => Address(
        id: json['id'] as String,
        ownerId: json['owner_id'] as String,
        name: json['name'] as String,
        description: json['description'] as String?,
        locality: json['locality'] as String?,
        visibility: AddressVisibilityX.fromDb(json['visibility'] as String),
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        gpsType: GpsTypeX.fromDb(json['gps_type'] as String),
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'] as String)
            : null,
      );

  /// Utilisé pour un insert (pas d'id, généré côté base).
  Map<String, dynamic> toInsertJson() => {
        'owner_id': ownerId,
        'name': name,
        'description': description,
        'locality': locality,
        'visibility': visibility.toDb(),
        'latitude': latitude,
        'longitude': longitude,
        'gps_type': gpsType.toDb(),
      };
}