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
    this.createdAt,
    this.updatedAt,
  });

  factory Beehive.fromJson(Map<String, dynamic> json) {
    return Beehive(
      id: (json['id'] ?? json['beehive_id'] ?? '').toString(),
      apiaryId: (json['apiary_id'] ?? '').toString(),
      beehiveNumber: json['hive_number'] ?? json['beehive_number'],
      activityLevel: json['activity_level'],
      beePopulation: json['bee_population'],
      foodFrames: json['food_frames'],
      broodFrames: json['brood_frames'],
      hiveStatus: json['hive_status'],
      healthStatus: json['health_status'],
      hasProductionChamber: json['has_production_chamber'],
      observations: json['observations'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
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
    createdAt,
    updatedAt,
  ];
}
