import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Puente desacoplado para notificar que la sesión expiró (el refresh de token
/// falló definitivamente).
///
/// Existe para romper la dependencia circular entre [dioClientProvider] y los
/// providers de auth: el interceptor de red solo conoce este notifier neutral,
/// y el `AuthController` registra aquí su handler de logout al inicializarse.
class SessionExpiredNotifier {
  Future<void> Function()? _handler;

  /// Registra el handler que se ejecuta cuando la sesión expira.
  void setHandler(Future<void> Function() handler) {
    _handler = handler;
  }

  /// Invocado por el interceptor cuando el refresh falla. Ejecuta el handler
  /// registrado (por ejemplo, forzar logout y redirigir al login).
  Future<void> notifyExpired() async {
    final handler = _handler;
    if (handler != null) {
      await handler();
    }
  }
}

final sessionExpiredNotifierProvider = Provider<SessionExpiredNotifier>((ref) {
  return SessionExpiredNotifier();
});
