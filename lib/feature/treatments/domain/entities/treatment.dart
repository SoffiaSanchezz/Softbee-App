class Treatment {
  final String id;
  final String hiveId;
  final String treatmentType;
  final String productName;
  final DateTime startDate;
  final String? activeIngredient;
  final String? targetDisease;
  final int? estimatedDurationDays;
  final DateTime? endDate;
  final String? applicationMethod;
  final String? dosageApplied;
  final String? dosageUnit;
  final String? batchNumber;
  final String? supplier;
  final DateTime? expiryDate;
  final String status;
  final String? finalResult;
  final String? finalHiveCondition;
  final bool requiresRepeat;
  final String? futureRecommendations;
  final String? appliedBy;
  final DateTime? registrationDate;
  final DateTime? updateDate;
  final List<Followup> followups;

  Treatment({
    required this.id,
    required this.hiveId,
    required this.treatmentType,
    required this.productName,
    required this.startDate,
    this.activeIngredient,
    this.targetDisease,
    this.estimatedDurationDays,
    this.endDate,
    this.applicationMethod,
    this.dosageApplied,
    this.dosageUnit,
    this.batchNumber,
    this.supplier,
    this.expiryDate,
    required this.status,
    this.finalResult,
    this.finalHiveCondition,
    required this.requiresRepeat,
    this.futureRecommendations,
    this.appliedBy,
    this.registrationDate,
    this.updateDate,
    this.followups = const [],
  });
}

class Followup {
  final String id;
  final String treatmentId;
  final DateTime reviewDate;
  final String? hiveCondition;
  final String? observedChanges;
  final String? partialResults;
  final String? infestationLevel;
  final String? notes;
  final String? reviewer;
  final DateTime? registrationDate;

  Followup({
    required this.id,
    required this.treatmentId,
    required this.reviewDate,
    this.hiveCondition,
    this.observedChanges,
    this.partialResults,
    this.infestationLevel,
    this.notes,
    this.reviewer,
    this.registrationDate,
  });
}
