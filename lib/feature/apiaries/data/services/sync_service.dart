import 'package:flutter/foundation.dart';
import 'package:Softbee/core/services/offline_storage_service.dart';
import 'package:Softbee/feature/apiaries/data/datasources/apiary_local_datasource.dart';
import 'package:Softbee/feature/apiaries/data/datasources/apiary_remote_datasource.dart';
import 'package:Softbee/feature/apiaries/data/models/pending_operation.dart';
import 'package:Softbee/feature/auth/data/datasources/auth_local_datasource.dart';
import 'package:Softbee/feature/beehive/data/datasources/beehive_local_datasource.dart';
import 'package:Softbee/feature/beehive/data/datasources/beehive_remote_datasource.dart';
import 'package:Softbee/feature/beehive/data/models/pending_beehive_operation.dart';
import 'package:Softbee/feature/maya/domain/repositories/maya_repository.dart';
import 'package:Softbee/core/sync/sync_dispatcher.dart';

class SyncService {
  final ApiaryRemoteDataSource remoteDataSource;
  final ApiaryLocalDataSource localDataSource;
  final AuthLocalDataSource authLocalDataSource;
  final OfflineStorageService offlineStorage;
  final MayaRepository mayaRepository;
  final BeehiveRemoteDataSource beehiveRemoteDataSource;
  final BeehiveLocalDataSource beehiveLocalDataSource;

  /// Despachador de la cola genérica de operaciones (inventario, preguntas,
  /// etc.). Enruta cada operación al handler de su feature.
  final SyncDispatcher syncDispatcher;

  bool _isSyncing = false;

  SyncService({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.authLocalDataSource,
    required this.offlineStorage,
    required this.mayaRepository,
    required this.beehiveRemoteDataSource,
    required this.beehiveLocalDataSource,
    required this.syncDispatcher,
  });

  bool get isSyncing => _isSyncing;

  /// Procesa todas las operaciones pendientes en orden.
  /// Retorna true si todas se sincronizaron correctamente.
  Future<bool> syncPendingOperations() async {
    if (_isSyncing) return false;
    _isSyncing = true;

    try {
      final token = await authLocalDataSource.getToken();
      if (token == null) {
        _isSyncing = false;
        return false;
      }

      // 1. Sincronizar operaciones de apiarios
      final pendingOps = await localDataSource.getPendingOperations();
      for (final operation in pendingOps) {
        final success = await _processOperation(operation, token);
        if (success) {
          await localDataSource.removePendingOperation(operation.id);
        } else {
          // Si una operación falla, detenemos para reintentar luego
          _isSyncing = false;
          return false;
        }
      }

      // 2. Sincronizar operaciones de colmenas (beehives)
      final beehivesSynced = await _syncBeehiveOperations(token);

      // 3. Sincronizar la cola genérica (inventario, preguntas, etc.)
      final dispatcherSynced = await syncDispatcher.processAll(token);

      // 4. Sincronizar respuestas de monitoreo de voz (Maya Voz)
      final voiceSynced = await _syncVoiceAnswers();

      // Después de sincronizar, refrescamos el cache local desde el servidor
      if (pendingOps.isNotEmpty) {
        await _refreshLocalCache(token);
      }

      _isSyncing = false;
      return beehivesSynced && dispatcherSynced && voiceSynced;
    } catch (e) {
      debugPrint("SyncService error: $e");
      _isSyncing = false;
      return false;
    }
  }

  /// Envía al backend las respuestas de voz guardadas offline.
  /// Retorna true si todo se sincronizó (o si no había nada pendiente).
  Future<bool> _syncVoiceAnswers() async {
    try {
      final offlineData = await offlineStorage.getOfflineAnswers();
      if (offlineData.isEmpty) return true;

      bool allSynced = true;
      for (final data in offlineData) {
        final hiveId = data['hive_id']?.toString();
        final rawList = data['answers'] ?? data['respuestas'];
        if (hiveId == null || rawList == null) {
          debugPrint("SyncService: registro de voz inválido, se omite.");
          continue;
        }

        final respuestas = List<Map<String, dynamic>>.from(rawList);
        final result = await mayaRepository.guardarRespuestasVoz(hiveId, respuestas);
        result.fold(
          (failure) {
            allSynced = false;
            debugPrint("SyncService: falló envío de respuestas de voz: ${failure.message}");
          },
          (_) => debugPrint("SyncService: respuestas de voz de colmena $hiveId enviadas."),
        );

        if (!allSynced) break;
      }

      // Solo limpiar la cola si todo se envió correctamente
      if (allSynced) {
        await offlineStorage.clearOfflineAnswers();
        debugPrint("SyncService: cola de respuestas de voz vaciada.");
      }
      return allSynced;
    } catch (e) {
      debugPrint("SyncService: error al sincronizar respuestas de voz: $e");
      return false;
    }
  }

  /// Envía al backend las operaciones de colmenas guardadas offline.
  /// Retorna true si todo se sincronizó (o si no había nada pendiente).
  Future<bool> _syncBeehiveOperations(String token) async {
    try {
      final pendingOps = await beehiveLocalDataSource.getPendingOperations();
      if (pendingOps.isEmpty) return true;

      // Ordenar por fecha de creación para respetar el orden de los cambios.
      pendingOps.sort((a, b) => a.createdAt.compareTo(b.createdAt));

      for (final op in pendingOps) {
        final success = await _processBeehiveOperation(op, token);
        if (success) {
          await beehiveLocalDataSource.removePendingOperation(op.id);
        } else {
          // Detener para reintentar en la próxima sincronización.
          return false;
        }
      }
      return true;
    } catch (e) {
      debugPrint("SyncService: error al sincronizar colmenas: $e");
      return false;
    }
  }

  Future<bool> _processBeehiveOperation(
    PendingBeehiveOperation op,
    String token,
  ) async {
    try {
      final data = op.data;

      switch (op.type) {
        case BeehiveOperationType.create:
          final created = await beehiveRemoteDataSource.createBeehive(
            op.apiaryId,
            _asInt(data?['beehive_number']) ?? 0,
            data?['activity_level'] as String?,
            data?['bee_population'] as String?,
            _asInt(data?['food_frames']),
            _asInt(data?['brood_frames']),
            data?['hive_status'] as String?,
            data?['health_status'] as String?,
            data?['has_production_chamber'] as String?,
            data?['observations'] as String?,
            (data?['treatments'] as bool?) ?? false,
            token,
          );

          // Remapear el id temporal por el id real del servidor, tanto en el
          // cache como en cualquier operación pendiente que lo referencie.
          if (op.isTemporary && created.id.isNotEmpty) {
            await beehiveLocalDataSource.replaceBeehiveId(
              op.apiaryId,
              op.beehiveId,
              created.id,
            );
          }
          return true;

        case BeehiveOperationType.update:
          // Una colmena con id temporal aún no existe en el servidor; el
          // remapeo del create debería haberla convertido primero. Si sigue
          // siendo temporal, la omitimos para no fallar la cola completa.
          if (op.isTemporary) return true;

          await beehiveRemoteDataSource.updateBeehive(
            op.beehiveId,
            op.apiaryId,
            _asInt(data?['beehive_number']),
            data?['activity_level'] as String?,
            data?['bee_population'] as String?,
            _asInt(data?['food_frames']),
            _asInt(data?['brood_frames']),
            data?['hive_status'] as String?,
            data?['health_status'] as String?,
            data?['has_production_chamber'] as String?,
            data?['observations'] as String?,
            data?['treatments'] as bool?,
            token,
          );
          return true;

        case BeehiveOperationType.delete:
          if (op.isTemporary) return true;
          await beehiveRemoteDataSource.deleteBeehive(
            op.beehiveId,
            op.apiaryId,
            token,
          );
          return true;
      }
    } catch (e) {
      debugPrint("SyncService: falló operación de colmena ${op.id}: $e");
      return false;
    }
  }

  int? _asInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }

  Future<bool> _processOperation(
    PendingOperation operation,
    String token,
  ) async {
    try {
      switch (operation.type) {
        case OperationType.create:
          await remoteDataSource.createApiary(
            token,
            operation.userId,
            operation.data!['name'] as String,
            operation.data!['location'] as String?,
            operation.data!['beehives_count'] as int?,
          );
          return true;

        case OperationType.update:
          await remoteDataSource.updateApiary(
            token,
            operation.apiaryId,
            operation.userId,
            operation.data?['name'] as String?,
            operation.data?['location'] as String?,
            operation.data?['beehives_count'] as int?,
          );
          return true;

        case OperationType.delete:
          await remoteDataSource.deleteApiary(
            token,
            operation.apiaryId,
            operation.userId,
          );
          return true;
      }
    } catch (e) {
      return false;
    }
  }

  /// Refresca el cache local con los datos más recientes del servidor.
  Future<void> _refreshLocalCache(String token) async {
    try {
      final remoteApiaries = await remoteDataSource.getApiaries(token);
      await localDataSource.cacheApiaries(remoteApiaries);
    } catch (_) {
      // Si falla el refresh, no es crítico — el cache se actualizará
      // en la próxima consulta con conexión
    }
  }
}
