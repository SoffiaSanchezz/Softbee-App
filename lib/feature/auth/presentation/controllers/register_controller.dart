// lib/feature/auth/presentation/controllers/register_controller.dart
import '../../core/entities/user.dart'; // Importar la entidad User

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/error/failures.dart';
import '../../core/usecase/register_usecase.dart';
import '../../core/usecase/create_apiary_usecase.dart'; // Importar el nuevo caso de uso
import '../../data/datasources/auth_remote_datasource.dart'; // Para generateUsername
import '../controllers/auth_controller.dart';
import '../providers/register_state.dart';
import 'package:Softbee/core/services/geocoding_service.dart'; // Importar GeocodingService

class RegisterController extends StateNotifier<RegisterState> {
  final AuthController _authController;
  final RegisterUseCase _registerUseCase;
  final CreateApiaryUseCase _createApiaryUseCase;
  final GeocodingService _geocodingService; // Inyectar GeocodingService

  RegisterController(
    this._authController,
    this._registerUseCase,
    this._createApiaryUseCase,
    this._geocodingService, // Recibir GeocodingService en el constructor
  ) : super(const RegisterState());

  // Métodos para actualizar los campos del formulario
  void onNameChanged(String value) {
    state = state.copyWith(name: value, clearErrorMessage: true);
  }

  void onEmailChanged(String value) {
    state = state.copyWith(email: value, clearErrorMessage: true);
  }

  void onPhoneChanged(String value) {
    state = state.copyWith(phone: value, clearErrorMessage: true);
  }

  void onPasswordChanged(String value) {
    state = state.copyWith(password: value, clearErrorMessage: true);
  }

  void onConfirmPasswordChanged(String value) {
    state = state.copyWith(confirmPassword: value, clearErrorMessage: true);
  }

  void togglePasswordVisibility() {
    state = state.copyWith(isPasswordVisible: !state.isPasswordVisible);
  }

  // Métodos de validación
  String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'El nombre es requerido';
    } else if (value.length < 2) {
      return 'El nombre debe tener al menos 2 caracteres';
    } else if (!RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]+$').hasMatch(value)) {
      return 'El nombre solo puede contener letras';
    }
    return null;
  }

  String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'El correo es requerido';
    } else if (!RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    ).hasMatch(value)) {
      return 'Ingresa un correo válido (ej: usuario@dominio.com)';
    }
    return null;
  }

  String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'El teléfono es requerido';
    } else {
      String cleanPhone = value.replaceAll(RegExp(r'[^\d]'), '');
      if (cleanPhone.length < 7) {
        return 'Número demasiado corto';
      }
    }
    return null;
  }

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'La contraseña es requerida';
    }
    if (value.length < 8) {
      return 'Debe tener al menos 8 caracteres';
    }
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Debe contener al menos una mayúscula (A-Z)';
    }
    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return 'Debe contener al menos una minúscula (a-z)';
    }
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Debe contener al menos un número (0-9)';
    }
    if (!RegExp(r'[^a-zA-Z0-9\s]').hasMatch(value)) {
      return 'Debe contener al menos un carácter especial';
    }
    return null;
  }

  String? validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Confirma tu contraseña';
    } else if (value != state.password) {
      return 'Las contraseñas no coinciden';
    }
    return null;
  }

  // Métodos auxiliares para la verificación individual de reglas de contraseña
  bool hasMinLength(String password) => password.length >= 8;
  bool hasUppercase(String password) => RegExp(r'[A-Z]').hasMatch(password);
  bool hasLowercase(String password) => RegExp(r'[a-z]').hasMatch(password);
  bool hasDigit(String password) => RegExp(r'[0-9]').hasMatch(password);
  bool hasSpecialChar(String password) =>
      RegExp(r'[^a-zA-Z0-9\s]').hasMatch(password);

  bool _isStep1Valid() {
    return validateName(state.name) == null &&
        validateEmail(state.email) == null &&
        validatePhone(state.phone) == null &&
        validatePassword(state.password) == null &&
        validateConfirmPassword(state.confirmPassword) == null;
  }

  bool _isStep2Valid() {
    if (state.apiaries.isEmpty) return false;
    for (var apiary in state.apiaries) {
      if (apiary.name.isEmpty || apiary.name.length < 3) {
        // Only validate name presence and minimum length
        return false;
      }
      // La dirección es ahora opcional. El backend acepta `null` o cadena vacía.
      // `isLocationValid` y `locationValidationAttempted` son solo para feedback visual, no deben bloquear la presentación.
    }
    return true;
  }

  void incrementStep() {
    if (state.currentStep == 0) {
      state = state.copyWith(showValidationErrors: true);
      if (_isStep1Valid()) {
        state = state.copyWith(
          currentStep: state.currentStep + 1,
          showValidationErrors: false,
        );
      }
    }
  }

  void decrementStep() {
    if (state.currentStep > 0) {
      state = state.copyWith(currentStep: state.currentStep - 1);
    }
  }

  void goToStep(int step) {
    state = state.copyWith(currentStep: step);
  }

  // Métodos para gestionar apiarios
  void addApiary() {
    state = state.copyWith(
      apiaries: [...state.apiaries, const RegisterApiaryData()],
    );
  }

  void removeApiary(int index) {
    if (state.apiaries.length > 1) {
      final newApiaries = List<RegisterApiaryData>.from(state.apiaries);
      newApiaries.removeAt(index);
      state = state.copyWith(apiaries: newApiaries);
    }
  }

  void updateApiaryName(int index, String value) {
    final newApiaries = List<RegisterApiaryData>.from(state.apiaries);
    newApiaries[index] = newApiaries[index].copyWith(name: value);
    state = state.copyWith(apiaries: newApiaries);
  }

  void updateApiaryAddress(int index, String value) {
    final newApiaries = List<RegisterApiaryData>.from(state.apiaries);
    // Reiniciar validación al cambiar la dirección
    newApiaries[index] = newApiaries[index].copyWith(
      address: value,
      isLocationValid: false,
      locationValidationAttempted: false,
    );
    state = state.copyWith(apiaries: newApiaries);
  }

  Future<void> validateApiaryLocation(int index) async {
    final currentApiaries = List<RegisterApiaryData>.from(state.apiaries);
    final apiaryToValidate = currentApiaries[index];

    // Marcar que se ha intentado la validación
    currentApiaries[index] = apiaryToValidate.copyWith(
      locationValidationAttempted: true,
    );
    if (!mounted) return;
    state = state.copyWith(apiaries: currentApiaries);

    // Con el servicio de geocodificación actualizado, obtenemos la validación real.
    final isValid = await _geocodingService.validateAddress(
      apiaryToValidate.address,
    );

    if (!mounted) return;
    currentApiaries[index] = apiaryToValidate.copyWith(
      isLocationValid: isValid,
    );
    state = state.copyWith(apiaries: currentApiaries);
  }

  String _cleanPhone(String phone) {
    return phone.replaceAll(RegExp(r'[^\d]'), '');
  }

  Future<void> submitRegistration() async {
    if (!mounted) return;
    state = state.copyWith(
      isLoading: true,
      clearErrorMessage: true,
      showValidationErrors: true,
    );

    if (!_isStep1Valid() || !_isStep2Valid()) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Por favor, completa todos los campos correctamente.',
      );
      return;
    }

    final username = AuthRemoteDataSourceImpl.generateUsername(state.email);
    final registerParams = RegisterParams(
      name: state.name,
      username: username,
      email: state.email,
      phone: _cleanPhone(state.phone),
      password: state.password,
    );

    try {
      final registerResult = await _authController.register(
        registerParams.name,
        registerParams.username,
        registerParams.email,
        registerParams.phone,
        registerParams.password,
      );

      if (!mounted) return;

      final token = registerResult['token'] as String;
      final user = registerResult['user'] as User;
      final userId = user.id;

      // Apiary creation is now a best-effort, non-blocking operation
      String? apiaryCreationError;
      for (final apiaryData in state.apiaries) {
        final location = apiaryData.address;

        final createApiaryParams = CreateApiaryParams(
          userId: userId,
          apiaryName: apiaryData.name,
          location: location,
          beehivesCount: 0,
          token: token,
        );

        final apiaryResult = await _createApiaryUseCase(createApiaryParams);

        if (apiaryResult.isLeft) {
          apiaryCreationError =
              'Se registró tu cuenta, pero falló la creación del apiario "${apiaryData.name}". Podrás crearlo más tarde.';
          break; // Stop on first error
        }
      }

      if (!mounted) return;

      // The registration is successful regardless of apiary creation.
      state = state.copyWith(
        isLoading: false,
        isRegistered: true,
        errorMessage: apiaryCreationError, // Show warning if apiaries failed
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceFirst("Exception: ", ""),
        isRegistered: false,
      );
    }
  }

  String _mapFailureToMessage(Failure failure) {
    switch (failure.runtimeType) {
      case ServerFailure:
        return (failure as ServerFailure).message;
      case NetworkFailure:
        return (failure as NetworkFailure).message;
      case AuthFailure:
        return (failure as AuthFailure).message;
      case InvalidInputFailure:
        return (failure as InvalidInputFailure).message;
      default:
        return 'Ocurrió un error inesperado durante el registro.';
    }
  }

  void resetState() {
    state = const RegisterState(apiaries: [RegisterApiaryData()]);
  }
}
