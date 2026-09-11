import 'package:Softbee/feature/auth/data/datasources/auth_local_datasource.dart';
import 'package:Softbee/feature/auth/data/repositories/auth_repository_impl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/repositories/auth_repository.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import 'package:Softbee/core/network/dio_client.dart'; // Importar dio_client.dart
import 'package:Softbee/core/network/session_expired_notifier.dart';
import 'package:Softbee/core/services/geocoding_service.dart'; // Importar GeocodingService
import '../../core/usecase/check_auth_status_usecase.dart';
import '../../core/usecase/get_user_from_token_usecase.dart';
import '../../core/usecase/login_usecase.dart';
import '../../core/usecase/logout_usecase.dart';
import '../../core/usecase/register_usecase.dart'; // Importar RegisterUseCase
import '../../core/usecase/create_apiary_usecase.dart'; // Importar CreateApiaryUseCase
import '../../core/usecase/update_profile_usecase.dart';
import '../controllers/auth_controller.dart';
import '../controllers/forgot_password_controller.dart';
import '../controllers/reset_password_controller.dart';
import '../controllers/register_controller.dart'; // Importar RegisterController
import 'login_controller.dart'; // Import the new login controller
import 'login_state.dart'; // Import the new login state
import 'forgot_password_state.dart';
import 'reset_password_state.dart';
import 'register_state.dart'; // Importar RegisterState

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  final dio = ref.read(dioClientProvider);
  final localDataSource = ref.read(authLocalDataSourceProvider);
  return AuthRemoteDataSourceImpl(dio, localDataSource);
});

final authLocalDataSourceProvider = Provider<AuthLocalDataSource>((ref) {
  return AuthLocalDataSourceImpl();
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    remoteDataSource: ref.read(authRemoteDataSourceProvider),
    localDataSource: ref.read(authLocalDataSourceProvider),
  );
});

final loginUseCaseProvider = Provider<LoginUseCase>((ref) {
  return LoginUseCase(ref.read(authRepositoryProvider));
});

final logoutUseCaseProvider = Provider<LogoutUseCase>((ref) {
  return LogoutUseCase(ref.read(authRepositoryProvider));
});

final checkAuthStatusUseCaseProvider = Provider<CheckAuthStatusUseCase>((ref) {
  return CheckAuthStatusUseCase(ref.read(authRepositoryProvider));
});

final getUserFromTokenUseCaseProvider = Provider<GetUserFromTokenUseCase>((
  ref,
) {
  return GetUserFromTokenUseCase(ref.read(authRepositoryProvider));
});

final registerUseCaseProvider = Provider<RegisterUseCase>((ref) {
  return RegisterUseCase(ref.read(authRepositoryProvider));
});

final createApiaryUseCaseProvider = Provider<CreateApiaryUseCase>((ref) {
  return CreateApiaryUseCase(ref.read(authRepositoryProvider));
});

final updateProfileUseCaseProvider = Provider<UpdateProfileUseCase>((ref) {
  return UpdateProfileUseCase(ref.read(authRepositoryProvider));
});

final geocodingServiceProvider = Provider<GeocodingService>((ref) {
  return GeocodingService();
});

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>(
  (ref) {
    return AuthController(
      loginUseCase: ref.read(loginUseCaseProvider),
      logoutUseCase: ref.read(logoutUseCaseProvider),
      checkAuthStatusUseCase: ref.read(checkAuthStatusUseCaseProvider),
      getUserFromTokenUseCase: ref.read(getUserFromTokenUseCaseProvider),
      registerUseCase: ref.read(
        registerUseCaseProvider,
      ), // Inyectar RegisterUseCase
      createApiaryUseCase: ref.read(createApiaryUseCaseProvider),
      updateProfileUseCase: ref.read(updateProfileUseCaseProvider),
      sessionExpiredNotifier: ref.read(sessionExpiredNotifierProvider),
    );
  },
);

final loginControllerProvider =
    StateNotifierProvider.autoDispose<LoginController, LoginState>((ref) {
      final authController = ref.watch(
        authControllerProvider.notifier,
      ); // Get notifier for actions
      return LoginController(authController);
    });

final registerControllerProvider =
    StateNotifierProvider.autoDispose<RegisterController, RegisterState>((ref) {
      final authController = ref.watch(authControllerProvider.notifier);
      final registerUseCase = ref.read(registerUseCaseProvider);
      final createApiaryUseCase = ref.read(createApiaryUseCaseProvider);
      final geocodingService = ref.read(geocodingServiceProvider);
      return RegisterController(
        authController,
        registerUseCase,
        createApiaryUseCase,
        geocodingService,
      );
    });

final forgotPasswordControllerProvider =
    StateNotifierProvider.autoDispose<
      ForgotPasswordController,
      ForgotPasswordState
    >((ref) {
      return ForgotPasswordController();
    });

final resetPasswordControllerProvider =
    StateNotifierProvider.autoDispose<
      ResetPasswordController,
      ResetPasswordState
    >((ref) {
      return ResetPasswordController();
    });
