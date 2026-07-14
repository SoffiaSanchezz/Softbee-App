// lib/feature/auth/presentation/providers/register_state.dart
import 'package:equatable/equatable.dart';

// Definir ApiaryData para el estado del formulario de registro
class RegisterApiaryData extends Equatable {
  final String name;
  final String address;
  final bool isLocationValid;
  final bool locationValidationAttempted;

  const RegisterApiaryData({
    this.name = '',
    this.address = '',
    this.isLocationValid = false,
    this.locationValidationAttempted = false,
  });

  RegisterApiaryData copyWith({
    String? name,
    String? address,
    bool? isLocationValid,
    bool? locationValidationAttempted,
  }) {
    return RegisterApiaryData(
      name: name ?? this.name,
      address: address ?? this.address,
      isLocationValid: isLocationValid ?? this.isLocationValid,
      locationValidationAttempted:
          locationValidationAttempted ?? this.locationValidationAttempted,
    );
  }

  Map<String, dynamic> toJson() {
    return {"name": name, "location": address};
  }

  @override
  List<Object?> get props => [
    name,
    address,
    isLocationValid,
    locationValidationAttempted,
  ];
}

class RegisterState extends Equatable {
  final bool isLoading;
  final String? errorMessage;
  final bool isRegistered;
  final int currentStep;
  final bool isPasswordVisible;
  final bool showValidationErrors;

  // Campos del formulario
  final String name;
  final String email;
  final String phone;
  final String password;
  final String confirmPassword;
  final List<RegisterApiaryData> apiaries;

  const RegisterState({
    this.isLoading = false,
    this.errorMessage,
    this.isRegistered = false,
    this.currentStep = 0,
    this.isPasswordVisible = false,
    this.showValidationErrors = false,
    this.name = '',
    this.email = '',
    this.phone = '',
    this.password = '',
    this.confirmPassword = '',
    this.apiaries = const [
      RegisterApiaryData(),
    ], // Al menos un apiario por defecto
  });

  RegisterState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool? isRegistered,
    int? currentStep,
    bool? isPasswordVisible,
    bool? showValidationErrors,
    String? name,
    String? email,
    String? phone,
    String? password,
    String? confirmPassword,
    List<RegisterApiaryData>? apiaries,
    bool clearErrorMessage = false,
  }) {
    return RegisterState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearErrorMessage
          ? null
          : errorMessage ?? this.errorMessage,
      isRegistered: isRegistered ?? this.isRegistered,
      currentStep: currentStep ?? this.currentStep,
      isPasswordVisible: isPasswordVisible ?? this.isPasswordVisible,
      showValidationErrors: showValidationErrors ?? this.showValidationErrors,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      password: password ?? this.password,
      confirmPassword: confirmPassword ?? this.confirmPassword,
      apiaries: apiaries ?? this.apiaries,
    );
  }

  @override
  List<Object?> get props => [
    isLoading,
    errorMessage,
    isRegistered,
    currentStep,
    isPasswordVisible,
    showValidationErrors,
    name,
    email,
    phone,
    password,
    confirmPassword,
    apiaries,
  ];
}
