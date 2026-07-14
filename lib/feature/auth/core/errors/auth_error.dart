/// Códigos de error de autenticación compartidos con el backend.
///
/// El backend devuelve un `error_code` estable (en inglés) junto con un
/// `message`. El frontend interpreta ese código para mostrar un mensaje claro
/// y profesional en español, independiente del texto que envíe el servidor.
class AuthErrorCode {
  static const String emptyFields = 'EMPTY_FIELDS';
  static const String invalidEmail = 'INVALID_EMAIL';
  static const String emailNotRegistered = 'EMAIL_NOT_REGISTERED';
  static const String invalidPassword = 'INVALID_PASSWORD';
  static const String accountDisabled = 'ACCOUNT_DISABLED';
  static const String accountLocked = 'ACCOUNT_LOCKED';
  static const String serverError = 'SERVER_ERROR';
  static const String networkError = 'NETWORK_ERROR';
}

/// Traduce un código de error a un mensaje amigable en español.
///
/// Si el código es desconocido, usa [fallback] (por ejemplo el mensaje del
/// servidor) o un mensaje genérico como último recurso.
String authErrorMessage(String? code, {String? fallback}) {
  switch (code) {
    case AuthErrorCode.emptyFields:
      return 'Por favor completa todos los campos.';
    case AuthErrorCode.invalidEmail:
      return 'El correo electrónico no es válido.';
    case AuthErrorCode.emailNotRegistered:
      return 'El correo electrónico no está registrado.';
    case AuthErrorCode.invalidPassword:
      return 'La contraseña es incorrecta.';
    case AuthErrorCode.accountDisabled:
      return 'Tu cuenta está desactivada. Contacta al soporte.';
    case AuthErrorCode.accountLocked:
      return 'Tu cuenta está bloqueada temporalmente por múltiples intentos '
          'fallidos. Intenta más tarde.';
    case AuthErrorCode.serverError:
      return 'Ocurrió un error en el servidor. Intenta nuevamente más tarde.';
    case AuthErrorCode.networkError:
      return 'No se pudo conectar con el servidor. Verifica tu conexión.';
    default:
      return fallback ?? 'No se pudo iniciar sesión. Intenta nuevamente.';
  }
}

/// Excepción tipada para errores de autenticación.
///
/// Transporta el [code] estable del backend y el [message] ya traducido para
/// que las capas superiores lo muestren directamente.
class AuthException implements Exception {
  final String code;
  final String message;

  const AuthException(this.code, this.message);

  @override
  String toString() => message;
}
