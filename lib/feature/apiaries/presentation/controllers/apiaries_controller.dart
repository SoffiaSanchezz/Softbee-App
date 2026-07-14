import 'package:Softbee/core/error/failures.dart';
import 'package:Softbee/core/usecase/usecase.dart';
import 'package:Softbee/feature/apiaries/domain/entities/apiary.dart';
import 'package:Softbee/feature/apiaries/domain/usecases/get_apiaries.dart';
import 'package:Softbee/feature/apiaries/domain/usecases/create_apiary_usecase.dart';
import 'package:Softbee/feature/apiaries/domain/usecases/update_apiary_usecase.dart';
import 'package:Softbee/feature/apiaries/domain/usecases/delete_apiary_usecase.dart';
import 'package:Softbee/feature/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:equatable/equatable.dart';

// 1. ApiariesState: Represents the UI state
class ApiariesState extends Equatable {
  final bool isLoading;
  final bool isCreating;
  final bool isUpdating;
  final bool isDeleting;
  final List<Apiary> allApiaries; // Original list of all apiaries
  final List<Apiary> filteredApiaries; // List to display after filtering
  final String searchQuery; // Current search query
  final String? errorMessage;
  final String? successMessage;
  final String? errorCreating;
  final String? errorUpdating;
  final String? errorDeleting;

  const ApiariesState({
    this.isLoading = false,
    this.isCreating = false,
    this.isUpdating = false,
    this.isDeleting = false,
    this.allApiaries = const [],
    this.filteredApiaries = const [],
    this.searchQuery = '',
    this.errorMessage,
    this.successMessage,
    this.errorCreating,
    this.errorUpdating,
    this.errorDeleting,
  });

  ApiariesState copyWith({
    bool? isLoading,
    bool? isCreating,
    bool? isUpdating,
    bool? isDeleting,
    List<Apiary>? allApiaries,
    List<Apiary>? filteredApiaries,
    String? searchQuery,
    String? errorMessage,
    String? successMessage,
    String? errorCreating,
    String? errorUpdating,
    String? errorDeleting,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return ApiariesState(
      isLoading: isLoading ?? this.isLoading,
      isCreating: isCreating ?? this.isCreating,
      isUpdating: isUpdating ?? this.isUpdating,
      isDeleting: isDeleting ?? this.isDeleting,
      allApiaries: allApiaries ?? this.allApiaries,
      filteredApiaries: filteredApiaries ?? this.filteredApiaries,
      searchQuery: searchQuery ?? this.searchQuery,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      successMessage: clearSuccess
          ? null
          : successMessage ?? this.successMessage,
      errorCreating: clearError ? null : errorCreating ?? this.errorCreating,
      errorUpdating: clearError ? null : errorUpdating ?? this.errorUpdating,
      errorDeleting: clearError ? null : errorDeleting ?? this.errorDeleting,
    );
  }

  @override
  List<Object?> get props => [
    isLoading,
    isCreating,
    isUpdating,
    isDeleting,
    allApiaries,
    filteredApiaries,
    searchQuery,
    errorMessage,
    successMessage,
    errorCreating,
    errorUpdating,
    errorDeleting,
  ];
}

// 2. ApiariesController: Manages the state and interacts with use cases
class ApiariesController extends StateNotifier<ApiariesState> {
  final GetApiariesUseCase getApiariesUseCase;
  final CreateApiaryUseCase createApiaryUseCase;
  final UpdateApiaryUseCase updateApiaryUseCase;
  final DeleteApiaryUseCase deleteApiaryUseCase;
  final AuthController authController; // To get the current user ID

  ApiariesController({
    required this.getApiariesUseCase,
    required this.createApiaryUseCase,
    required this.updateApiaryUseCase,
    required this.deleteApiaryUseCase,
    required this.authController,
  }) : super(const ApiariesState());

  String? get _currentUserId => authController.state.user?.id;
  String? get _currentToken => authController.state.token;

  void applyFilter(String query) {
    final lowerCaseQuery = query.toLowerCase();
    final filtered = state.allApiaries.where((apiary) {
      return apiary.name.toLowerCase().contains(lowerCaseQuery);
    }).toList();

    state = state.copyWith(searchQuery: query, filteredApiaries: filtered);
  }

  Future<void> fetchApiaries() async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearSuccess: true,
    );

    if (!_isAuthenticated()) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'User not authenticated.',
      );
      return;
    }

    final result = await getApiariesUseCase(NoParams());

    result.fold(
      (failure) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: _mapFailureToMessage(failure, 'fetching apiaries'),
        );
      },
      (allApiaries) {
        final userApiaries = allApiaries
            .where((apiary) => apiary.userId == _currentUserId)
            .toList();
        state = state.copyWith(
          isLoading: false,
          allApiaries: userApiaries,
          filteredApiaries:
              userApiaries, // Initially, filtered list is all apiaries
          searchQuery: '',
        );
      },
    );
  }

  Future<void> createApiary(
    String name,
    String? location,
    int? beehivesCount,
  ) async {
    state = state.copyWith(
      isCreating: true,
      clearError: true,
      clearSuccess: true,
    );

    if (!_isAuthenticated()) {
      state = state.copyWith(
        isCreating: false,
        errorCreating: 'User not authenticated.',
      );
      return;
    }

    final params = CreateApiaryParams(
      userId: _currentUserId!,
      name: name,
      location: location,
      beehivesCount: beehivesCount,
    );

    final result = await createApiaryUseCase(params);

    result.fold(
      (failure) {
        state = state.copyWith(
          isCreating: false,
          errorCreating: _mapFailureToMessage(failure, 'creating apiary'),
        );
      },
      (newApiary) {
        final updatedAllApiaries = [...state.allApiaries, newApiary];
        state = state.copyWith(
          isCreating: false,
          allApiaries: updatedAllApiaries,
          successMessage: 'Apiary created successfully!',
        );
        applyFilter(
          state.searchQuery,
        ); // Re-apply filter to update filteredApiaries
      },
    );
  }

  Future<void> updateApiary(
    String apiaryId,
    String? name,
    String? location,
    int? beehivesCount,
  ) async {
    state = state.copyWith(
      isUpdating: true,
      clearError: true,
      clearSuccess: true,
    );

    if (!_isAuthenticated()) {
      state = state.copyWith(
        isUpdating: false,
        errorUpdating: 'User not authenticated.',
      );
      return;
    }

    final params = UpdateApiaryParams(
      apiaryId: apiaryId,
      userId: _currentUserId!,
      name: name,
      location: location,
      beehivesCount: beehivesCount,
    );

    final result = await updateApiaryUseCase(params);

    result.fold(
      (failure) {
        state = state.copyWith(
          isUpdating: false,
          errorUpdating: _mapFailureToMessage(failure, 'updating apiary'),
        );
      },
      (updatedApiary) {
        final updatedAllApiaries = state.allApiaries.map((apiary) {
          return apiary.id == updatedApiary.id ? updatedApiary : apiary;
        }).toList();
        state = state.copyWith(
          isUpdating: false,
          allApiaries: updatedAllApiaries,
          successMessage: 'Apiary updated successfully!',
        );
        applyFilter(
          state.searchQuery,
        ); // Re-apply filter to update filteredApiaries
      },
    );
  }

  Future<void> deleteApiary(String apiaryId) async {
    state = state.copyWith(
      isDeleting: true,
      clearError: true,
      clearSuccess: true,
    );

    if (!_isAuthenticated()) {
      state = state.copyWith(
        isDeleting: false,
        errorDeleting: 'User not authenticated.',
      );
      return;
    }

    final params = DeleteApiaryParams(
      apiaryId: apiaryId,
      userId: _currentUserId!,
    );

    final result = await deleteApiaryUseCase(params);

    result.fold(
      (failure) {
        state = state.copyWith(
          isDeleting: false,
          errorDeleting: _mapFailureToMessage(failure, 'deleting apiary'),
        );
      },
      (_) {
        final updatedAllApiaries = state.allApiaries
            .where((apiary) => apiary.id != apiaryId)
            .toList();
        state = state.copyWith(
          isDeleting: false,
          allApiaries: updatedAllApiaries,
          successMessage: 'Apiary deleted successfully!',
        );
        applyFilter(
          state.searchQuery,
        ); // Re-apply filter to update filteredApiaries
      },
    );
  }

  bool _isAuthenticated() {
    return authController.state.isAuthenticated &&
        authController.state.user != null &&
        _currentUserId != null;
  }

  String _mapFailureToMessage(Failure failure, String operation) {
    switch (failure.runtimeType) {
      case ServerFailure:
        return 'Server Error during $operation: ${(failure as ServerFailure).message}';
      case AuthFailure: // Token expired, etc.
        return 'Authentication Error during $operation: ${(failure as AuthFailure).message}';
      case NetworkFailure:
        return 'Network Error during $operation: ${(failure as NetworkFailure).message}';
      case InvalidInputFailure:
        return 'Invalid Input during $operation: ${(failure as InvalidInputFailure).message}';
      default:
        return 'An unexpected error occurred during $operation.';
    }
  }

  void clearMessages() {
    state = state.copyWith(clearError: true, clearSuccess: true);
  }
}
