import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:Softbee/core/error/failures.dart';
import 'package:Softbee/feature/beehive/domain/entities/beehive.dart';
import 'package:Softbee/feature/beehive/domain/usecases/get_beehives_by_apiary_usecase.dart';
import 'package:Softbee/feature/beehive/domain/usecases/create_beehive_usecase.dart';
import 'package:Softbee/feature/beehive/domain/usecases/update_beehive_usecase.dart';
import 'package:Softbee/feature/beehive/domain/usecases/delete_beehive_usecase.dart';

class BeehiveState extends Equatable {
  final bool isLoading;
  final bool isCreating;
  final bool isUpdating;
  final bool isDeleting;
  final List<Beehive> beehives;
  final String? errorMessage;
  final String? successMessage;

  const BeehiveState({
    this.isLoading = false,
    this.isCreating = false,
    this.isUpdating = false,
    this.isDeleting = false,
    this.beehives = const [],
    this.errorMessage,
    this.successMessage,
  });

  BeehiveState copyWith({
    bool? isLoading,
    bool? isCreating,
    bool? isUpdating,
    bool? isDeleting,
    List<Beehive>? beehives,
    String? errorMessage,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return BeehiveState(
      isLoading: isLoading ?? this.isLoading,
      isCreating: isCreating ?? this.isCreating,
      isUpdating: isUpdating ?? this.isUpdating,
      isDeleting: isDeleting ?? this.isDeleting,
      beehives: beehives ?? this.beehives,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      successMessage: clearSuccess
          ? null
          : successMessage ?? this.successMessage,
    );
  }

  @override
  List<Object?> get props => [
    isLoading,
    isCreating,
    isUpdating,
    isDeleting,
    beehives,
    errorMessage,
    successMessage,
  ];
}

class BeehiveController extends StateNotifier<BeehiveState> {
  final GetBeehivesByApiaryUseCase getBeehivesByApiaryUseCase;
  final CreateBeehiveUseCase createBeehiveUseCase;
  final UpdateBeehiveUseCase updateBeehiveUseCase;
  final DeleteBeehiveUseCase deleteBeehiveUseCase;

  BeehiveController({
    required this.getBeehivesByApiaryUseCase,
    required this.createBeehiveUseCase,
    required this.updateBeehiveUseCase,
    required this.deleteBeehiveUseCase,
  }) : super(const BeehiveState());

  Future<void> fetchBeehivesByApiary(String apiaryId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final result = await getBeehivesByApiaryUseCase(apiaryId);
    result.fold(
      (failure) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: _mapFailureToMessage(failure),
        );
      },
      (beehives) {
        state = state.copyWith(isLoading: false, beehives: beehives);
      },
    );
  }

  Future<void> createBeehive(
    String apiaryId,
    int beehiveNumber,
    String? activityLevel,
    String? beePopulation,
    int? foodFrames,
    int? broodFrames,
    String? hiveStatus,
    String? healthStatus,
    String? hasProductionChamber,
    String? observations,
  ) async {
    state = state.copyWith(
      isCreating: true,
      clearError: true,
      clearSuccess: true,
    );
    final params = CreateBeehiveParams(
      apiaryId: apiaryId,
      beehiveNumber: beehiveNumber,
      activityLevel: activityLevel,
      beePopulation: beePopulation,
      foodFrames: foodFrames,
      broodFrames: broodFrames,
      hiveStatus: hiveStatus,
      healthStatus: healthStatus,
      hasProductionChamber: hasProductionChamber,
      observations: observations,
    );
    final result = await createBeehiveUseCase(params);
    result.fold(
      (failure) {
        state = state.copyWith(
          isCreating: false,
          errorMessage: _mapFailureToMessage(failure),
        );
      },
      (newBeehive) {
        state = state.copyWith(
          isCreating: false,
          beehives: [...state.beehives, newBeehive],
          successMessage: 'Colmena creada exitosamente!',
        );
      },
    );
  }

  Future<void> updateBeehive(
    String beehiveId,
    String apiaryId,
    int? beehiveNumber,
    String? activityLevel,
    String? beePopulation,
    int? foodFrames,
    int? broodFrames,
    String? hiveStatus,
    String? healthStatus,
    String? hasProductionChamber,
    String? observations,
  ) async {
    state = state.copyWith(
      isUpdating: true,
      clearError: true,
      clearSuccess: true,
    );
    final params = UpdateBeehiveParams(
      beehiveId: beehiveId,
      apiaryId: apiaryId,
      beehiveNumber: beehiveNumber,
      activityLevel: activityLevel,
      beePopulation: beePopulation,
      foodFrames: foodFrames,
      broodFrames: broodFrames,
      hiveStatus: hiveStatus,
      healthStatus: healthStatus,
      hasProductionChamber: hasProductionChamber,
      observations: observations,
    );
    final result = await updateBeehiveUseCase(params);
    result.fold(
      (failure) {
        state = state.copyWith(
          isUpdating: false,
          errorMessage: _mapFailureToMessage(failure),
        );
      },
      (updatedBeehive) {
        state = state.copyWith(
          isUpdating: false,
          beehives: state.beehives
              .map((b) => b.id == updatedBeehive.id ? updatedBeehive : b)
              .toList(),
          successMessage: 'Colmena actualizada exitosamente!',
        );
      },
    );
  }

  Future<void> deleteBeehive(String beehiveId, String apiaryId) async {
    state = state.copyWith(
      isDeleting: true,
      clearError: true,
      clearSuccess: true,
    );
    final params = DeleteBeehiveParams(
      beehiveId: beehiveId,
      apiaryId: apiaryId,
    );
    final result = await deleteBeehiveUseCase(params);
    result.fold(
      (failure) {
        state = state.copyWith(
          isDeleting: false,
          errorMessage: _mapFailureToMessage(failure),
        );
      },
      (_) {
        state = state.copyWith(
          isDeleting: false,
          beehives: state.beehives.where((b) => b.id != beehiveId).toList(),
          successMessage: 'Colmena eliminada exitosamente!',
        );
      },
    );
  }

  String _mapFailureToMessage(Failure failure) {
    switch (failure.runtimeType) {
      case ServerFailure:
        return 'Error del servidor: ${(failure as ServerFailure).message}';
      case AuthFailure:
        return 'Error de autenticación: ${(failure as AuthFailure).message}';
      case NetworkFailure:
        return 'Error de red: ${(failure as NetworkFailure).message}';
      default:
        return 'Ocurrió un error inesperado.';
    }
  }

  void clearMessages() {
    state = state.copyWith(clearError: true, clearSuccess: true);
  }
}
