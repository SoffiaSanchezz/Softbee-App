import 'package:Softbee/feature/apiaries/data/datasources/apiary_local_datasource.dart';
import 'package:Softbee/feature/apiaries/data/datasources/apiary_remote_datasource.dart';
import 'package:Softbee/feature/apiaries/data/models/pending_operation.dart';
import 'package:Softbee/feature/auth/data/datasources/auth_local_datasource.dart';

class SyncService {
  final ApiaryRemoteDataSource remoteDataSource;
  final ApiaryLocalDataSource localDataSource;
  final AuthLocalDataSource authLocalDataSource;

  bool _isSyncing = false;

  SyncService({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.authLocalDataSource,
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

      final pendingOps = await localDataSource.getPendingOperations();
      if (pendingOps.isEmpty) {
        _isSyncing = false;
        return true;
      }

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

      // Después de sincronizar, refrescamos el cache local desde el servidor
      await _refreshLocalCache(token);

      _isSyncing = false;
      return true;
    } catch (e) {
      _isSyncing = false;
      return false;
    }
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
