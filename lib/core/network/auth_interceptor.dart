import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../feature/auth/data/datasources/auth_local_datasource.dart';

/// Marca las peticiones que ya fueron reintentadas tras un refresh, para no
/// entrar en un bucle infinito de reintentos.
const String _kRetriedFlag = 'x-retried-after-refresh';

/// Rutas de autenticación que NO deben pasar por el flujo de refresh.
/// Un 401 en login/refresh es legítimo (credenciales o token inválido) y no
/// debe intentar renovarse.
bool _isAuthEndpoint(String path) {
  return path.contains('/api/v1/auth/login') ||
      path.contains('/api/v1/auth/register') ||
      path.contains('/api/v1/auth/refresh') ||
      path.contains('/api/v1/auth/forgot-password') ||
      path.contains('/api/v1/auth/reset-password');
}

/// Interceptor que:
/// 1. Inyecta automáticamente el `Authorization: Bearer <access_token>` en cada
///    petición protegida (leyendo el token guardado).
/// 2. Ante un 401 por token expirado, refresca el `access_token` usando el
///    `refresh_token` contra `/api/v1/auth/refresh`, guarda el nuevo par
///    (rotación) y reintenta la petición original una sola vez.
/// 3. Si el refresh falla (INVALID_TOKEN u otro), limpia la sesión y notifica
///    para que la app redirija al login.
///
/// Se usa un [QueuedInterceptorsWrapper] para que las respuestas se procesen en
/// orden y, combinado con la bandera [_isRefreshing], garantizar que solo se
/// ejecute UN refresh aunque varias peticiones fallen con 401 al mismo tiempo
/// (importante porque el backend rota el refresh_token).
class AuthInterceptor extends QueuedInterceptor {
  AuthInterceptor({
    required this.localDataSource,
    required this.baseUrl,
    required this.onSessionExpired,
  });

  final AuthLocalDataSource localDataSource;
  final String baseUrl;

  /// Callback invocado cuando el refresh falla definitivamente y hay que
  /// cerrar la sesión (la app debe redirigir al login).
  final Future<void> Function() onSessionExpired;

  /// Dio independiente (sin este interceptor) para llamar al endpoint de
  /// refresh y evitar recursión.
  late final Dio _refreshDio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // No adjuntamos token a los endpoints de auth (login/register/refresh...).
    if (!_isAuthEndpoint(options.path)) {
      final token = await localDataSource.getToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final response = err.response;
    final requestOptions = err.requestOptions;

    final bool isUnauthorized = response?.statusCode == 401;
    final bool alreadyRetried = requestOptions.extra[_kRetriedFlag] == true;
    final bool isAuthCall = _isAuthEndpoint(requestOptions.path);

    // Solo intentamos refrescar ante un 401 en una petición protegida que aún
    // no se ha reintentado.
    if (!isUnauthorized || alreadyRetried || isAuthCall) {
      return handler.next(err);
    }

    final refreshToken = await localDataSource.getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      // No hay forma de refrescar: cerrar sesión.
      await _handleSessionExpired();
      return handler.next(err);
    }

    try {
      final newAccessToken = await _refreshTokens(refreshToken);

      // Reintentar la petición original con el nuevo token.
      requestOptions.extra[_kRetriedFlag] = true;
      requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';

      final retryResponse = await _refreshDio.fetch<dynamic>(requestOptions);
      return handler.resolve(retryResponse);
    } on DioException catch (e) {
      // El refresh o el reintento fallaron. Si fue el refresh el que devolvió
      // 401 (token rotado/expirado), cerramos sesión.
      final refreshFailedWith401 =
          e.requestOptions.path.contains('/api/v1/auth/refresh') &&
          e.response?.statusCode == 401;
      if (refreshFailedWith401) {
        await _handleSessionExpired();
      }
      return handler.next(err);
    } catch (e) {
      debugPrint('[AuthInterceptor] Error inesperado durante el refresh: $e');
      return handler.next(err);
    }
  }

  /// Llama a `/api/v1/auth/refresh`, guarda el nuevo par de tokens (rotación) y
  /// devuelve el nuevo access_token.
  Future<String> _refreshTokens(String refreshToken) async {
    final response = await _refreshDio.post(
      '/api/v1/auth/refresh',
      data: {'refresh_token': refreshToken},
    );

    final Map<String, dynamic> data = response.data is String
        ? json.decode(response.data as String) as Map<String, dynamic>
        : response.data as Map<String, dynamic>;

    final newAccessToken = data['access_token']?.toString();
    final newRefreshToken = data['refresh_token']?.toString();

    if (newAccessToken == null || newAccessToken.isEmpty) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        message: 'Refresh sin access_token en la respuesta',
      );
    }

    await localDataSource.saveToken(newAccessToken);
    // Rotación: el backend invalida el refresh anterior y devuelve uno nuevo.
    if (newRefreshToken != null && newRefreshToken.isNotEmpty) {
      await localDataSource.saveRefreshToken(newRefreshToken);
    }

    return newAccessToken;
  }

  Future<void> _handleSessionExpired() async {
    await localDataSource.clearSession();
    try {
      await onSessionExpired();
    } catch (e) {
      debugPrint('[AuthInterceptor] Error en onSessionExpired: $e');
    }
  }
}
