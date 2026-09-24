class RouteStep {
  final String? id;
  final String addressId;
  final int stepOrder;
  final String instruction;
  final double? distance;
  final String? direction;
  final String? landmarkId; // optionnel : RG8

  RouteStep({
    this.id,
    required this.addressId,
    required this.stepOrder,
    required this.instruction,
    this.distance,
    this.direction,
    this.landmarkId,
  });

  factory RouteStep.fromJson(Map<String, dynamic> json) => RouteStep(
        id: json['id'] as String,
        addressId: json['address_id'] as String,
        stepOrder: json['step_order'] as int,
        instruction: json['instruction'] as String,
        distance: json['distance'] != null
            ? (json['distance'] as num).toDouble()
            : null,
        direction: json['direction'] as String?,
        landmarkId: json['landmark_id'] as String?,
      );

  Map<String, dynamic> toInsertJson() => {
        'address_id': addressId,
        'step_order': stepOrder,
        'instruction': instruction,
        'distance': distance,
        'direction': direction,
        'landmark_id': landmarkId,
      };
}