import 'package:equatable/equatable.dart';

class Beehive extends Equatable {
  final String id;
  final String apiaryId;
  final int? beehiveNumber;
  final String? activityLevel;
  final String? beePopulation;
  final int? foodFrames;
  final int? broodFrames;
  final String? hiveStatus;
  final String? healthStatus;
  final String? hasProductionChamber;
  final String? observations;
  final bool treatments;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Beehive({
    required this.id,
    required this.apiaryId,
    this.beehiveNumber,
    this.activityLevel,
    this.beePopulation,
    this.foodFrames,
    this.broodFrames,
    this.hiveStatus,
    this.healthStatus,
    this.hasProductionChamber,
    this.observations,
    this.treatments = false,
    this.createdAt,
    this.updatedAt,
  });

  factory Beehive.fromJson(Map<String, dynamic> json) {
    return Beehive(
      id: (json['id'] ?? json['beehive_id'] ?? '').toString(),
      apiaryId: (json['apiary_id'] ?? '').toString(),
      beehiveNumber: _parseInt(json['hive_number'] ?? json['beehive_number']),
      activityLevel: json['activity_level']?.toString(),
      beePopulation: json['bee_population']?.toString(),
      foodFrames: _parseInt(json['food_frames']),
      broodFrames: _parseInt(json['brood_frames']),
      hiveStatus: json['hive_status']?.toString(),
      healthStatus: json['health_status']?.toString(),
      hasProductionChamber: json['has_production_chamber']?.toString(),
      observations: json['observations']?.toString(),
      treatments: json['treatments'] == true || json['treatments'] == 'true',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'apiary_id': apiaryId,
      'hive_number': beehiveNumber,
      'activity_level': activityLevel,
      'bee_population': beePopulation,
      'food_frames': foodFrames,
      'brood_frames': broodFrames,
      'hive_status': hiveStatus,
      'health_status': healthStatus,
      'has_production_chamber': hasProductionChamber,
      'observations': observations,
      'treatments': treatments,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  Beehive copyWith({
    String? id,
    String? apiaryId,
    int? beehiveNumber,
    String? activityLevel,
    String? beePopulation,
    int? foodFrames,
    int? broodFrames,
    String? hiveStatus,
    String? healthStatus,
    String? hasProductionChamber,
    String? observations,
    bool? treatments,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Beehive(
      id: id ?? this.id,
      apiaryId: apiaryId ?? this.apiaryId,
      beehiveNumber: beehiveNumber ?? this.beehiveNumber,
      activityLevel: activityLevel ?? this.activityLevel,
      beePopulation: beePopulation ?? this.beePopulation,
      foodFrames: foodFrames ?? this.foodFrames,
      broodFrames: broodFrames ?? this.broodFrames,
      hiveStatus: hiveStatus ?? this.hiveStatus,
      healthStatus: healthStatus ?? this.healthStatus,
      hasProductionChamber: hasProductionChamber ?? this.hasProductionChamber,
      observations: observations ?? this.observations,
      treatments: treatments ?? this.treatments,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    apiaryId,
    beehiveNumber,
    activityLevel,
    beePopulation,
    foodFrames,
    broodFrames,
    hiveStatus,
    healthStatus,
    hasProductionChamber,
    observations,
    treatments,
    createdAt,
    updatedAt,
  ];
}
