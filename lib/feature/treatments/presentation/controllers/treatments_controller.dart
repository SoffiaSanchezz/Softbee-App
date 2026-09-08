import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/treatment.dart';
import '../../domain/usecases/get_treatments_by_hive.dart';
import '../../domain/usecases/get_treatment_by_id.dart';
import '../../domain/usecases/create_treatment.dart';
import '../../domain/usecases/update_treatment.dart';
import '../../domain/usecases/delete_treatment.dart';
import '../../domain/usecases/create_followup.dart';
import '../../domain/usecases/update_followup.dart';
import '../../domain/usecases/delete_followup.dart';

class TreatmentsState extends Equatable {
  final bool isLoading;
  final bool isCreating;
  final bool isDeleting;
  final List<Treatment> treatments;
  final String searchQuery;
  final String statusFilter; // 'Todos' o un estado concreto
  final String? errorMessage;
  final String? successMessage;

  const TreatmentsState({
    this.isLoading = false,
    this.isCreating = false,
    this.isDeleting = false,
    this.treatments = const [],
    this.searchQuery = '',
    this.statusFilter = 'Todos',
    this.errorMessage,
    this.successMessage,
  });

  /// Tratamientos tras aplicar búsqueda + filtro de estado.
  List<Treatment> get filteredTreatments {
    final query = searchQuery.trim().toLowerCase();
    return treatments.where((t) {
      final matchesStatus =
          statusFilter == 'Todos' || t.status.toLowerCase() == statusFilter.toLowerCase();
      if (!matchesStatus) return false;
      if (query.isEmpty) return true;
      final haystack = [
        t.productName,
        t.treatmentType,
        t.activeIngredient ?? '',
        t.targetDisease ?? '',
        t.appliedBy ?? '',
        t.status,
      ].join(' ').toLowerCase();
      return haystack.contains(query);
    }).toList();
  }

  TreatmentsState copyWith({
    bool? isLoading,
    bool? isCreating,
    bool? isDeleting,
    List<Treatment>? treatments,
    String? searchQuery,
    String? statusFilter,
    String? errorMessage,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return TreatmentsState(
      isLoading: isLoading ?? this.isLoading,
      isCreating: isCreating ?? this.isCreating,
      isDeleting: isDeleting ?? this.isDeleting,
      treatments: treatments ?? this.treatments,
      searchQuery: searchQuery ?? this.searchQuery,
      statusFilter: statusFilter ?? this.statusFilter,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      successMessage: clearSuccess ? null : successMessage ?? this.successMessage,
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        isCreating,
        isDeleting,
        treatments,
        searchQuery,
        statusFilter,
        errorMessage,
        successMessage,
      ];
}

class TreatmentsController extends StateNotifier<TreatmentsState> {
  final GetTreatmentsByHive getTreatmentsByHive;
  final GetTreatmentById getTreatmentById;
  final CreateTreatment createTreatmentUseCase;
  final UpdateTreatment updateTreatmentUseCase;
  final DeleteTreatment deleteTreatmentUseCase;
  final CreateFollowup createFollowupUseCase;
  final UpdateFollowup updateFollowupUseCase;
  final DeleteFollowup deleteFollowupUseCase;

  TreatmentsController({
    required this.getTreatmentsByHive,
    required this.getTreatmentById,
    required this.createTreatmentUseCase,
    required this.updateTreatmentUseCase,
    required this.deleteTreatmentUseCase,
    required this.createFollowupUseCase,
    required this.updateFollowupUseCase,
    required this.deleteFollowupUseCase,
  }) : super(const TreatmentsState());

  Future<void> fetchTreatments(String hiveId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final result = await getTreatmentsByHive.execute(hiveId);
    result.fold(
      (failure) => state = state.copyWith(isLoading: false, errorMessage: failure),
      (treatments) => state = state.copyWith(isLoading: false, treatments: treatments),
    );
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void setStatusFilter(String status) {
    state = state.copyWith(statusFilter: status);
  }

  void resetFilters() {
    state = state.copyWith(searchQuery: '', statusFilter: 'Todos');
  }

  Treatment? treatmentById(String id) {
    for (final t in state.treatments) {
      if (t.id == id) return t;
    }
    return null;
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

  Future<void> updateTreatment(String id, Map<String, dynamic> data) async {
    state = state.copyWith(isCreating: true, clearError: true, clearSuccess: true);
    final result = await updateTreatmentUseCase.execute(id, data);
    result.fold(
      (failure) => state = state.copyWith(isCreating: false, errorMessage: failure),
      (updated) {
        final updatedList = state.treatments
            .map((t) => t.id == updated.id ? updated : t)
            .toList();
        state = state.copyWith(
          isCreating: false,
          treatments: updatedList,
          successMessage: 'Tratamiento actualizado exitosamente',
        );
      },
    );
  }

  Future<void> deleteTreatment(String id) async {
    state = state.copyWith(isDeleting: true, clearError: true, clearSuccess: true);
    final result = await deleteTreatmentUseCase.execute(id);
    result.fold(
      (failure) => state = state.copyWith(isDeleting: false, errorMessage: failure),
      (_) {
        final updatedList = state.treatments.where((t) => t.id != id).toList();
        state = state.copyWith(
          isDeleting: false,
          treatments: updatedList,
          successMessage: 'Tratamiento eliminado exitosamente',
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
            return t.copyWith(
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

  Future<void> updateFollowup(String followupId, Map<String, dynamic> data) async {
    state = state.copyWith(isCreating: true, clearError: true, clearSuccess: true);
    final result = await updateFollowupUseCase.execute(followupId, data);
    result.fold(
      (failure) => state = state.copyWith(isCreating: false, errorMessage: failure),
      (followup) {
        final updatedTreatments = state.treatments.map((t) {
          if (t.id == followup.treatmentId) {
            final followups = t.followups
                .map((f) => f.id == followup.id ? followup : f)
                .toList();
            return t.copyWith(updateDate: DateTime.now(), followups: followups);
          }
          return t;
        }).toList();

        state = state.copyWith(
          isCreating: false,
          treatments: updatedTreatments,
          successMessage: 'Seguimiento actualizado exitosamente',
        );
      },
    );
  }

  Future<void> deleteFollowup(String treatmentId, String followupId) async {
    state = state.copyWith(isDeleting: true, clearError: true, clearSuccess: true);
    final result = await deleteFollowupUseCase.execute(followupId);
    result.fold(
      (failure) => state = state.copyWith(isDeleting: false, errorMessage: failure),
      (_) {
        final updatedTreatments = state.treatments.map((t) {
          if (t.id == treatmentId) {
            final followups =
                t.followups.where((f) => f.id != followupId).toList();
            return t.copyWith(updateDate: DateTime.now(), followups: followups);
          }
          return t;
        }).toList();

        state = state.copyWith(
          isDeleting: false,
          treatments: updatedTreatments,
          successMessage: 'Seguimiento eliminado exitosamente',
        );
      },
    );
  }

  void clearMessages() {
    state = state.copyWith(clearError: true, clearSuccess: true);
  }
}
