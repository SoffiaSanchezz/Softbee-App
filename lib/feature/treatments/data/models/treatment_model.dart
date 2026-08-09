import 'package:Softbee/core/utils/date_parser.dart';
import '../../domain/entities/treatment.dart';

class TreatmentModel extends Treatment {
  TreatmentModel({
    required super.id,
    required super.hiveId,
    required super.treatmentType,
    required super.productName,
    required super.startDate,
    super.activeIngredient,
    super.targetDisease,
    super.estimatedDurationDays,
    super.endDate,
    super.applicationMethod,
    super.dosageApplied,
    super.dosageUnit,
    super.batchNumber,
    super.supplier,
    super.expiryDate,
    required super.status,
    super.finalResult,
    super.finalHiveCondition,
    required super.requiresRepeat,
    super.futureRecommendations,
    super.appliedBy,
    super.registrationDate,
    super.updateDate,
    super.followups,
  });

  factory TreatmentModel.fromJson(Map<String, dynamic> json) {
    return TreatmentModel(
      id: json['id'],
      hiveId: json['hive_id'],
      treatmentType: json['treatment_type'],
      productName: json['product_name'],
      startDate: DateParser.parseBackendDateOr(json['start_date']),
      activeIngredient: json['active_ingredient'],
      targetDisease: json['target_disease'],
      estimatedDurationDays: json['estimated_duration_days'],
      endDate: DateParser.parseBackendDate(json['end_date']),
      applicationMethod: json['application_method'],
      dosageApplied: json['dosage_applied'],
      dosageUnit: json['dosage_unit'],
      batchNumber: json['batch_number'],
      supplier: json['supplier'],
      expiryDate: DateParser.parseBackendDate(json['expiry_date']),
      status: json['status'],
      finalResult: json['final_result'],
      finalHiveCondition: json['final_hive_condition'],
      requiresRepeat: json['requires_repeat'] ?? false,
      futureRecommendations: json['future_recommendations'],
      appliedBy: json['applied_by'],
      registrationDate: DateParser.parseBackendDate(json['registration_date']),
      updateDate: DateParser.parseBackendDate(json['update_date']),
      followups: (json['followups'] as List? ?? [])
          .map((f) => FollowupModel.fromJson(f))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'hive_id': hiveId,
      'treatment_type': treatmentType,
      'product_name': productName,
      'start_date': startDate.toIso8601String(),
      'active_ingredient': activeIngredient,
      'target_disease': targetDisease,
      'estimated_duration_days': estimatedDurationDays,
      'end_date': endDate?.toIso8601String(),
      'application_method': applicationMethod,
      'dosage_applied': dosageApplied,
      'dosage_unit': dosageUnit,
      'batch_number': batchNumber,
      'supplier': supplier,
      'expiry_date': expiryDate?.toIso8601String(),
      'status': status,
      'final_result': finalResult,
      'final_hive_condition': finalHiveCondition,
      'requires_repeat': requiresRepeat,
      'future_recommendations': futureRecommendations,
      'applied_by': appliedBy,
      'registration_date': registrationDate?.toIso8601String(),
      'update_date': updateDate?.toIso8601String(),
    };
  }
}

class FollowupModel extends Followup {
  FollowupModel({
    required super.id,
    required super.treatmentId,
    required super.reviewDate,
    super.hiveCondition,
    super.observedChanges,
    super.partialResults,
    super.infestationLevel,
    super.notes,
    super.reviewer,
    super.registrationDate,
  });

  factory FollowupModel.fromJson(Map<String, dynamic> json) {
    return FollowupModel(
      id: json['followup_id'] ?? json['id'],
      treatmentId: json['treatment_id'],
      reviewDate: DateParser.parseBackendDateOr(json['review_date']),
      hiveCondition: json['hive_condition'],
      observedChanges: json['observed_changes'],
      partialResults: json['partial_results'],
      infestationLevel: json['infestation_level'],
      notes: json['notes'],
      reviewer: json['reviewer'],
      registrationDate: DateParser.parseBackendDate(json['registration_date']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'followup_id': id,
      'treatment_id': treatmentId,
      'review_date': reviewDate.toIso8601String(),
      'hive_condition': hiveCondition,
      'observed_changes': observedChanges,
      'partial_results': partialResults,
      'infestation_level': infestationLevel,
      'notes': notes,
      'reviewer': reviewer,
      'registration_date': registrationDate?.toIso8601String(),
    };
  }
}
