import 'package:either_dart/either.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/services/offline_storage_service.dart';
import '../../../auth/data/datasources/auth_local_datasource.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/repositories/maya_repository.dart';
import '../datasources/maya_remote_datasource.dart';
import '../models/maya_response_model.dart';

class MayaRepositoryImpl implements MayaRepository {
  final MayaRemoteDataSource remoteDataSource;
  final AuthLocalDataSource localDataSource;
  final OfflineStorageService offlineStorage;

  MayaRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.offlineStorage,
  });

  @override
  Future<Either<Failure, ChatMessage>> sendMessage({
    required String prompt,
    String? sessionId,
    String agentId = 'general',
    String provider = 'gemini',
    Map<String, dynamic>? context,
  }) async {
    try {
      final token = await localDataSource.getToken();
      final responseMap = await remoteDataSource.askMaya(
        prompt: prompt,
        sessionId: sessionId,
        agentId: agentId,
        provider: provider,
        context: context,
        token: token,
      );

      final model = MayaResponseModel.fromJson(responseMap);
      return Right(model.toEntity());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> iniciarMonitoreoVoz(String hiveId) async {
    // Offline-first: intentamos el servidor y cacheamos; si falla (sin señal),
    // devolvemos las preguntas cacheadas para que Maya complete el trazado.
    try {
      final token = await localDataSource.getToken();

      // LOG DIAGNÓSTICO DEL TOKEN
      debugPrint("[Maya][iniciar-monitoreo] hive_id=$hiveId");
      debugPrint("[Maya][iniciar-monitoreo] token -> ${_describeToken(token)}");

      final result = await remoteDataSource.iniciarMonitoreoVoz(hiveId, token ?? '');

      // Guardar el contexto de monitoreo (preguntas) para uso offline.
      await offlineStorage.cacheHiveMonitoring(hiveId, result);

      return Right(result);
    } catch (e) {
      debugPrint("[Maya][iniciar-monitoreo] ERROR: $e");
      // Fallback al cache: si hay preguntas precargadas, Maya sigue offline.
      final cached = await offlineStorage.getCachedHiveMonitoring(hiveId);
      if (cached != null) {
        debugPrint("[Maya][iniciar-monitoreo] usando preguntas cacheadas offline.");
        return Right(cached);
      }
      return Left(ServerFailure(e.toString()));
    }
  }

  /// Describe el token para diagnóstico sin volcar el JWT completo en logs.
  String _describeToken(String? token) {
    if (token == null) return 'NULL (no hay token guardado)';
    if (token.isEmpty) return 'VACÍO (string de longitud 0)';
    final length = token.length;
    final preview = length <= 12
        ? token
        : '${token.substring(0, 6)}...${token.substring(length - 4)}';
    return 'len=$length, preview=$preview';
  }

  @override
  Future<void> precacheHiveMonitoring(String hiveId) async {
    try {
      final token = await localDataSource.getToken();
      final result = await remoteDataSource.iniciarMonitoreoVoz(hiveId, token ?? '');
      await offlineStorage.cacheHiveMonitoring(hiveId, result);
    } catch (_) {
      // best-effort: si no hay señal, simplemente no se precarga.
    }
  }

  @override
  Future<Either<Failure, void>> guardarRespuestasVoz(String hiveId, List<Map<String, dynamic>> respuestas) async {
    try {
      final token = await localDataSource.getToken();

      // LOG DIAGNÓSTICO DEL TOKEN
      debugPrint("[Maya][guardar-respuestas] hive_id=$hiveId, respuestas=${respuestas.length}");
      debugPrint("[Maya][guardar-respuestas] token -> ${_describeToken(token)}");

      await remoteDataSource.guardarRespuestasVoz(hiveId, respuestas, token ?? '');
      return const Right(null);
    } catch (e) {
      debugPrint("[Maya][guardar-respuestas] ERROR: $e");
      return Left(ServerFailure(e.toString()));
    }
  }
}
