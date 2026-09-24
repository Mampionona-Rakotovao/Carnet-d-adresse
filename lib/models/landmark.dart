class Landmark {
  final String? id;
  final String addressId;
  final String name;
  final String? description;
  final String? photoUrl;
  final double? latitude;
  final double? longitude;
  final int positionOrder;

  Landmark({
    this.id,
    required this.addressId,
    required this.name,
    this.description,
    this.photoUrl,
    this.latitude,
    this.longitude,
    this.positionOrder = 0,
  });

  factory Landmark.fromJson(Map<String, dynamic> json) => Landmark(
        id: json['id'] as String,
        addressId: json['address_id'] as String,
        name: json['name'] as String,
        description: json['description'] as String?,
        photoUrl: json['photo_url'] as String?,
        latitude: json['latitude'] != null
            ? (json['latitude'] as num).toDouble()
            : null,
        longitude: json['longitude'] != null
            ? (json['longitude'] as num).toDouble()
            : null,
        positionOrder: json['position_order'] as int? ?? 0,
      );

  Map<String, dynamic> toInsertJson() => {
        'address_id': addressId,
        'name': name,
        'description': description,
        'photo_url': photoUrl,
        'latitude': latitude,
        'longitude': longitude,
        'position_order': positionOrder,
      };
}