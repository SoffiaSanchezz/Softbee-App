import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/treatment.dart';
import '../../domain/usecases/get_treatments_by_hive.dart';
import '../../domain/usecases/create_treatment.dart';
import '../../domain/usecases/create_followup.dart';

class TreatmentsState extends Equatable {
  final bool isLoading;
  final bool isCreating;
  final List<Treatment> treatments;
  final String? errorMessage;
  final String? successMessage;

  const TreatmentsState({
    this.isLoading = false,
    this.isCreating = false,
    this.treatments = const [],
    this.errorMessage,
    this.successMessage,
  });

  TreatmentsState copyWith({
    bool? isLoading,
    bool? isCreating,
    List<Treatment>? treatments,
    String? errorMessage,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return TreatmentsState(
      isLoading: isLoading ?? this.isLoading,
      isCreating: isCreating ?? this.isCreating,
      treatments: treatments ?? this.treatments,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      successMessage: clearSuccess ? null : successMessage ?? this.successMessage,
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        isCreating,
        treatments,
        errorMessage,
        successMessage,
      ];
}

class TreatmentsController extends StateNotifier<TreatmentsState> {
  final GetTreatmentsByHive getTreatmentsByHive;
  final CreateTreatment createTreatmentUseCase;
  final CreateFollowup createFollowupUseCase;

  TreatmentsController({
    required this.getTreatmentsByHive,
    required this.createTreatmentUseCase,
    required this.createFollowupUseCase,
  }) : super(const TreatmentsState());

  Future<void> fetchTreatments(String hiveId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final result = await getTreatmentsByHive.execute(hiveId);
    result.fold(
      (failure) => state = state.copyWith(isLoading: false, errorMessage: failure),
      (treatments) => state = state.copyWith(isLoading: false, treatments: treatments),
    );
  }

  Future<void> createTreatment(Map<String, dynamic> data) async {
    state = state.copyWith(isCreating: true, clearError: true, clearSuccess: true);
    final result = await createTreatmentUseCase.execute(data);
    result.fold(
      (failure) => state = state.copyWith(isCreating: false, errorMessage: failure),
      (treatment) {
        state = state.copyWith(
          isCreating: false,
          treatments: [...state.treatments, treatment],
          successMessage: 'Tratamiento registrado exitosamente',
        );
      },
    );
  }

  Future<void> addFollowup(Map<String, dynamic> data) async {
    state = state.copyWith(isCreating: true, clearError: true, clearSuccess: true);
    final result = await createFollowupUseCase.execute(data);
    result.fold(
      (failure) => state = state.copyWith(isCreating: false, errorMessage: failure),
      (followup) {
        final updatedTreatments = state.treatments.map((t) {
          if (t.id == followup.treatmentId) {
            return Treatment(
              id: t.id,
              hiveId: t.hiveId,
              treatmentType: t.treatmentType,
              productName: t.productName,
              startDate: t.startDate,
              activeIngredient: t.activeIngredient,
              targetDisease: t.targetDisease,
              estimatedDurationDays: t.estimatedDurationDays,
              endDate: t.endDate,
              applicationMethod: t.applicationMethod,
              dosageApplied: t.dosageApplied,
              dosageUnit: t.dosageUnit,
              batchNumber: t.batchNumber,
              supplier: t.supplier,
              expiryDate: t.expiryDate,
              status: t.status,
              finalResult: t.finalResult,
              finalHiveCondition: t.finalHiveCondition,
              requiresRepeat: t.requiresRepeat,
              futureRecommendations: t.futureRecommendations,
              appliedBy: t.appliedBy,
              registrationDate: t.registrationDate,
              updateDate: DateTime.now(),
              followups: [...t.followups, followup],
            );
          }
          return t;
        }).toList();

        state = state.copyWith(
          isCreating: false,
          treatments: updatedTreatments,
          successMessage: 'Seguimiento registrado exitosamente',
        );
      },
    );
  }

  void clearMessages() {
    state = state.copyWith(clearError: true, clearSuccess: true);
  }
}
