import 'package:Softbee/feature/auth/core/usecase/create_apiary_usecase.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../../core/entities/user.dart';
import '../../core/usecase/check_auth_status_usecase.dart';
import '../../core/usecase/get_user_from_token_usecase.dart';
import '../../core/usecase/login_usecase.dart';
import '../../core/usecase/logout_usecase.dart';
import '../../core/usecase/register_usecase.dart';

class AuthState {
  final bool isLoading;
  final User? user;
  final String? error;
  final bool isRegistered;
  final bool isAuthenticating; // For initial auth check
  final String? token;

  const AuthState({
    this.isLoading = false,
    this.user,
    this.error,
    this.isRegistered = false,
    this.isAuthenticating = true,
    this.token,
  });

  bool get isAuthenticated => user != null;

  AuthState copyWith({
    bool? isLoading,
    User? user,
    String? error,
    bool? isRegistered,
    bool? isAuthenticating,
    String? token,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      user: user ?? this.user,
      error: error,
      isRegistered: isRegistered ?? this.isRegistered,
      isAuthenticating: isAuthenticating ?? this.isAuthenticating,
      token: token ?? this.token,
    );
  }
}

class AuthController extends StateNotifier<AuthState> {
  final LoginUseCase loginUseCase;
  final LogoutUseCase logoutUseCase;
  final CheckAuthStatusUseCase checkAuthStatusUseCase;
  final GetUserFromTokenUseCase getUserFromTokenUseCase;
  final RegisterUseCase registerUseCase; // Add RegisterUseCase
  final CreateApiaryUseCase
  createApiaryUseCase; // Se inyectará en RegisterController

  AuthController({
    required this.loginUseCase,
    required this.logoutUseCase,
    required this.checkAuthStatusUseCase,
    required this.getUserFromTokenUseCase,
    required this.registerUseCase,
    required this.createApiaryUseCase,
  }) : super(const AuthState()) {
    _init(); // Call _init to check auth status on startup
  }

  void _init() {
    checkAuthStatus();
  }

  Future<void> checkAuthStatus() async {
    state = state.copyWith(isAuthenticating: true);
    final result = await checkAuthStatusUseCase(NoParams());

    result.fold(
      (failure) {
        state = state.copyWith(
          isAuthenticating: false,
          user: null,
          error: _mapFailureToMessage(failure),
        );
      },
      (user) {
        state = state.copyWith(isAuthenticating: false, user: user);
      },
    );
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(
      isLoading: true,
      isAuthenticating: true,
      error: null,
    );

    final loginResult = await loginUseCase(LoginParams(email, password));

    await loginResult.fold(
      (failure) async {
        state = state.copyWith(
          isLoading: false,
          isAuthenticating: false,
          error: _mapFailureToMessage(failure),
        );
      },
      (token) async {
        final userResult = await getUserFromTokenUseCase(token);
        userResult.fold(
          (failure) {
            state = state.copyWith(
              isLoading: false,
              isAuthenticating: false,
              user: null,
              error: _mapFailureToMessage(failure),
            );
          },
          (user) {
            state = state.copyWith(
              isLoading: false,
              isAuthenticating: false,
              user: user,
              token: token,
            );
          },
        );
      },
    );
  }

  Future<Map<String, dynamic>> register(
    String name, // Este 'name' es de la UI, no se pasa al backend directamente
    String username,
    String email,
    String phone,
    String password,
    // final List<Map<String, dynamic>> apiaries, // Eliminado de aquí
  ) async {
    state = state.copyWith(isLoading: true, error: null, isRegistered: false);

    final registerResult = await registerUseCase(
      RegisterParams(
        name: name,
        username: username,
        email: email,
        phone: phone,
        password: password,
      ),
    );

    return await registerResult.fold(
      (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
          isRegistered: false,
        );
        throw Exception(_mapFailureToMessage(failure));
      },
      (data) {
        final token =
            data['access_token']
                as String; // Usar 'access_token' para consistencia
        final user = data['user'] as User;
        state = state.copyWith(
          isLoading: false,
          isRegistered: true,
          user: user,
          token: token,
          isAuthenticating: false,
          error: null,
        );
        return {'token': token, 'user': user};
      },
    );
  }

  Future<void> logout() async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await logoutUseCase(NoParams());
    result.fold(
      (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
      },
      (_) {
        state = const AuthState(
          isAuthenticating: false,
        ); // Reset state completely
      },
    );
  }

  String _mapFailureToMessage(Failure failure) {
    switch (failure.runtimeType) {
      case ServerFailure:
        return (failure as ServerFailure).message;
      case CacheFailure:
        return (failure as CacheFailure).message;
      case NetworkFailure:
        return (failure as NetworkFailure).message;
      case AuthFailure:
        return (failure as AuthFailure).message;
      case InvalidInputFailure:
        return (failure as InvalidInputFailure).message;
      default:
        return 'An unexpected error occurred.';
    }
  }

  void resetRegisterStatus() {
    state = state.copyWith(isRegistered: false);
  }
}
