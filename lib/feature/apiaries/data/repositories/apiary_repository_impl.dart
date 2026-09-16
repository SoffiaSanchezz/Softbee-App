import 'package:Softbee/core/error/failures.dart';
import 'package:Softbee/core/network/network_info.dart';
import 'package:Softbee/feature/apiaries/data/datasources/apiary_local_datasource.dart';
import 'package:Softbee/feature/apiaries/data/datasources/apiary_remote_datasource.dart';
import 'package:Softbee/feature/apiaries/data/models/pending_operation.dart';
import 'package:Softbee/feature/apiaries/domain/entities/apiary.dart';
import 'package:Softbee/feature/apiaries/domain/repositories/apiary_repository.dart';
import 'package:Softbee/feature/auth/data/datasources/auth_local_datasource.dart';
import 'package:either_dart/either.dart';

class ApiaryRepositoryImpl implements ApiaryRepository {
  final ApiaryRemoteDataSource remoteDataSource;
  final AuthLocalDataSource authLocalDataSource;
  final ApiaryLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  ApiaryRepositoryImpl({
    required this.remoteDataSource,
    required this.authLocalDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<Apiary>>> getApiaries() async {
    if (await networkInfo.isConnected) {
      try {
        final token = await authLocalDataSource.getToken();
        final remoteApiaries = await remoteDataSource.getApiaries(token!);

        // Guardamos en local lo que vino del servidor
        await localDataSource.cacheApiaries(remoteApiaries);

        return Right(remoteApiaries);
      } catch (e) {
        // Si falla el servidor, intentamos devolver datos locales
        try {
          final localApiaries = await localDataSource.getLastApiaries();
          if (localApiaries.isNotEmpty) {
            return Right(localApiaries);
          }
        } catch (_) {}
        return Left(ServerFailure(e.toString()));
      }
    } else {
      // MODO OFFLINE
      try {
        final localApiaries = await localDataSource.getLastApiaries();
        return Right(localApiaries);
      } catch (e) {
        return Left(CacheFailure("No hay datos locales disponibles"));
      }
    }
  }

  @override
  Future<Either<Failure, Apiary>> createApiary(
    String userId,
    String name,
    String? location,
    int? beehivesCount,
  ) async {
    if (await networkInfo.isConnected) {
      // ONLINE: crear en servidor y guardar en cache
      try {
        final token = await authLocalDataSource.getToken();
        if (token == null) {
          return const Left(AuthFailure('No authentication token found.'));
        }
        final result = await remoteDataSource.createApiary(
          token,
          userId,
          name,
          location,
          beehivesCount,
        );

        // Guardamos el nuevo apiario en el cache local
        await localDataSource.saveApiary(result);

        return Right(result);
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    } else {
      // OFFLINE: crear localmente con ID temporal y encolar
      try {
        final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
        final localApiary = Apiary(
          id: tempId,
          userId: userId,
          name: name,
          location: location,
          beehivesCount: beehivesCount,
          createdAt: DateTime.now(),
        );

        // Guardar en cache local
        await localDataSource.saveApiary(localApiary);

        // Encolar operación pendiente
        final operation = PendingOperation(
          id: 'op_${DateTime.now().millisecondsSinceEpoch}',
          type: OperationType.create,
          apiaryId: tempId,
          userId: userId,
          data: {
            'name': name,
            'location': location,
            'beehives_count': beehivesCount,
          },
          createdAt: DateTime.now(),
        );
        await localDataSource.addPendingOperation(operation);

        return Right(localApiary);
      } catch (e) {
        return Left(CacheFailure('Error al guardar localmente: ${e.toString()}'));
      }
    }
  }

  @override
  Future<Either<Failure, Apiary>> updateApiary(
    String apiaryId,
    String userId,
    String? name,
    String? location,
    int? beehivesCount,
  ) async {
    if (await networkInfo.isConnected) {
      // ONLINE: actualizar en servidor y en cache
      try {
        final token = await authLocalDataSource.getToken();
        if (token == null) {
          return const Left(AuthFailure('No authentication token found.'));
        }
        final result = await remoteDataSource.updateApiary(
          token,
          apiaryId,
          userId,
          name,
          location,
          beehivesCount,
        );

        // Actualizar en cache local
        await localDataSource.updateLocalApiary(result);

        return Right(result);
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    } else {
      // OFFLINE: actualizar localmente y encolar
      try {
        // Obtener el apiario actual del cache para aplicar los cambios
        final apiaries = await localDataSource.getLastApiaries();
        final current = apiaries.firstWhere(
          (a) => a.id == apiaryId,
          orElse: () => throw Exception('Apiario no encontrado en cache'),
        );

        final updated = current.copyWith(
          name: name ?? current.name,
          location: location ?? current.location,
          beehivesCount: beehivesCount ?? current.beehivesCount,
        );

        // Actualizar en cache local
        await localDataSource.updateLocalApiary(updated);

        // Encolar operación pendiente
        final operation = PendingOperation(
          id: 'op_${DateTime.now().millisecondsSinceEpoch}',
          type: OperationType.update,
          apiaryId: apiaryId,
          userId: userId,
          data: {
            'name': name,
            'location': location,
            'beehives_count': beehivesCount,
          },
          createdAt: DateTime.now(),
        );
        await localDataSource.addPendingOperation(operation);

        return Right(updated);
      } catch (e) {
        return Left(CacheFailure('Error al actualizar localmente: ${e.toString()}'));
      }
    }
  }

  @override
  Future<Either<Failure, void>> deleteApiary(
    String apiaryId,
    String userId,
  ) async {
    if (await networkInfo.isConnected) {
      // ONLINE: eliminar en servidor y en cache
      try {
        final token = await authLocalDataSource.getToken();
        if (token == null) {
          return const Left(AuthFailure('No authentication token found.'));
        }
        await remoteDataSource.deleteApiary(token, apiaryId, userId);

        // Eliminar del cache local
        await localDataSource.deleteLocalApiary(apiaryId);

        return const Right(null);
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    } else {
      // OFFLINE: eliminar localmente y encolar
      try {
        // Eliminar del cache local
        await localDataSource.deleteLocalApiary(apiaryId);

        // Encolar operación pendiente (solo si no es un apiario temporal)
        if (!apiaryId.startsWith('temp_')) {
          final operation = PendingOperation(
            id: 'op_${DateTime.now().millisecondsSinceEpoch}',
            type: OperationType.delete,
            apiaryId: apiaryId,
            userId: userId,
            createdAt: DateTime.now(),
          );
          await localDataSource.addPendingOperation(operation);
        } else {
          // Si es temporal, simplemente eliminamos la operación de creación pendiente
          final pendingOps = await localDataSource.getPendingOperations();
          for (final op in pendingOps) {
            if (op.apiaryId == apiaryId && op.type == OperationType.create) {
              await localDataSource.removePendingOperation(op.id);
              break;
            }
          }
        }

        return const Right(null);
      } catch (e) {
        return Left(CacheFailure('Error al eliminar localmente: ${e.toString()}'));
      }
    }
  }
}
