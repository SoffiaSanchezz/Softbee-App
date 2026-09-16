import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_config.dart';
import '../../feature/auth/data/datasources/auth_local_datasource.dart';
import 'auth_interceptor.dart';
import 'session_expired_notifier.dart';

final dioClientProvider = Provider<Dio>((ref) {
  final baseUrl = AppConfig.backUrl;

  final BaseOptions options = BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
  );

  final dio = Dio(options);

  // Instanciamos el local datasource directamente (no tiene dependencias) para
  // evitar importar auth_providers.dart y provocar una dependencia circular.
  final AuthLocalDataSource localDataSource = AuthLocalDataSourceImpl();
  final sessionExpiredNotifier = ref.read(sessionExpiredNotifierProvider);

  dio.interceptors.add(
    AuthInterceptor(
      localDataSource: localDataSource,
      baseUrl: baseUrl,
      onSessionExpired: sessionExpiredNotifier.notifyExpired,
    ),
  );

  return dio;
});
