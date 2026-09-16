import 'package:either_dart/either.dart';
import 'package:Softbee/core/error/failures.dart';
import 'package:Softbee/core/network/network_info.dart';
import 'package:Softbee/feature/auth/data/datasources/auth_local_datasource.dart';
import 'package:Softbee/feature/beehive/data/datasources/beehive_local_datasource.dart';
import 'package:Softbee/feature/beehive/data/datasources/beehive_remote_datasource.dart';
import 'package:Softbee/feature/beehive/data/models/pending_beehive_operation.dart';
import 'package:Softbee/feature/beehive/domain/entities/beehive.dart';
import 'package:Softbee/feature/beehive/domain/repositories/beehive_repository.dart';

class BeehiveRepositoryImpl implements BeehiveRepository {
  final BeehiveRemoteDataSource remoteDataSource;
  final AuthLocalDataSource localDataSource;
  final BeehiveLocalDataSource beehiveLocalDataSource;
  final NetworkInfo networkInfo;

  BeehiveRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.beehiveLocalDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<Beehive>>> getBeehivesByApiary(
    String apiaryId,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final token = await localDataSource.getToken();
        if (token == null) {
          return const Left(AuthFailure('No se encontró el token de autenticación.'));
        }
        final remoteBeehives = await remoteDataSource.getBeehivesByApiary(apiaryId, token);

        // Cachear en local lo que vino del servidor
        await beehiveLocalDataSource.cacheBeehives(apiaryId, remoteBeehives);

        return Right(remoteBeehives);
      } catch (e) {
        // Si falla el servidor, intentar devolver datos locales
        try {
          final localBeehives = await beehiveLocalDataSource.getCachedBeehives(apiaryId);
          if (localBeehives.isNotEmpty) {
            return Right(localBeehives);
          }
        } catch (_) {}
        return Left(ServerFailure(e.toString()));
      }
    } else {
      // MODO OFFLINE
      try {
        final localBeehives = await beehiveLocalDataSource.getCachedBeehives(apiaryId);
        return Right(localBeehives);
      } catch (e) {
        return Left(CacheFailure("No hay datos de colmenas disponibles offline"));
      }
    }
  }

  @override
  Future<Either<Failure, Beehive>> createBeehive(
    String apiaryId,
    int beehiveNumber,
    String? activityLevel,
    String? beePopulation,
    int? foodFrames,
    int? broodFrames,
    String? hiveStatus,
    String? healthStatus,
    String? hasProductionChamber,
    String? observations,
    bool treatments,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final token = await localDataSource.getToken();
        if (token == null) {
          return const Left(AuthFailure('No se encontró el token de autenticación.'));
        }
        final result = await remoteDataSource.createBeehive(
          apiaryId,
          beehiveNumber,
          activityLevel,
          beePopulation,
          foodFrames,
          broodFrames,
          hiveStatus,
          healthStatus,
          hasProductionChamber,
          observations,
          treatments,
          token,
        );

        // Guardar en cache local
        await beehiveLocalDataSource.saveBeehive(apiaryId, result);

        return Right(result);
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    } else {
      // OFFLINE: guardar localmente con ID temporal
      try {
        final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
        final localBeehive = Beehive(
          id: tempId,
          apiaryId: apiaryId,
          beehiveNumber: beehiveNumber,
          activityLevel: activityLevel,
          beePopulation: beePopulation,
          foodFrames: foodFrames,
          broodFrames: broodFrames,
          hiveStatus: hiveStatus,
          healthStatus: healthStatus,
          hasProductionChamber: hasProductionChamber,
          observations: observations,
          treatments: treatments,
          createdAt: DateTime.now(),
        );

        // Guardar en cache local
        await beehiveLocalDataSource.saveBeehive(apiaryId, localBeehive);

        // Encolar operación pendiente para sincronizar al reconectar
        await beehiveLocalDataSource.addPendingOperation(
          PendingBeehiveOperation(
            id: 'op_${DateTime.now().millisecondsSinceEpoch}',
            type: BeehiveOperationType.create,
            beehiveId: tempId,
            apiaryId: apiaryId,
            data: {
              'beehive_number': beehiveNumber,
              'activity_level': activityLevel,
              'bee_population': beePopulation,
              'food_frames': foodFrames,
              'brood_frames': broodFrames,
              'hive_status': hiveStatus,
              'health_status': healthStatus,
              'has_production_chamber': hasProductionChamber,
              'observations': observations,
              'treatments': treatments,
            },
            createdAt: DateTime.now(),
          ),
        );

        return Right(localBeehive);
      } catch (e) {
        return Left(CacheFailure('Error al guardar colmena localmente: ${e.toString()}'));
      }
    }
  }

  @override
  Future<Either<Failure, Beehive>> updateBeehive(
    String beehiveId,
    String apiaryId,
    int? beehiveNumber,
    String? activityLevel,
    String? beePopulation,
    int? foodFrames,
    int? broodFrames,
    String? hiveStatus,
    String? healthStatus,
    String? hasProductionChamber,
    String? observations,
    bool? treatments,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final token = await localDataSource.getToken();
        if (token == null) {
          return const Left(AuthFailure('No se encontró el token de autenticación.'));
        }
        final result = await remoteDataSource.updateBeehive(
          beehiveId,
          apiaryId,
          beehiveNumber,
          activityLevel,
          beePopulation,
          foodFrames,
          broodFrames,
          hiveStatus,
          healthStatus,
          hasProductionChamber,
          observations,
          treatments,
          token,
        );

        // Actualizar cache local
        await beehiveLocalDataSource.updateLocalBeehive(apiaryId, result);

        return Right(result);
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    } else {
      // OFFLINE: actualizar localmente
      try {
        final beehives = await beehiveLocalDataSource.getCachedBeehives(apiaryId);
        final current = beehives.firstWhere(
          (b) => b.id == beehiveId,
          orElse: () => throw Exception('Colmena no encontrada en cache'),
        );

        final updated = current.copyWith(
          beehiveNumber: beehiveNumber ?? current.beehiveNumber,
          activityLevel: activityLevel ?? current.activityLevel,
          beePopulation: beePopulation ?? current.beePopulation,
          foodFrames: foodFrames ?? current.foodFrames,
          broodFrames: broodFrames ?? current.broodFrames,
          hiveStatus: hiveStatus ?? current.hiveStatus,
          healthStatus: healthStatus ?? current.healthStatus,
          hasProductionChamber: hasProductionChamber ?? current.hasProductionChamber,
          observations: observations ?? current.observations,
          treatments: treatments ?? current.treatments,
          updatedAt: DateTime.now(),
        );

        await beehiveLocalDataSource.updateLocalBeehive(apiaryId, updated);

        // Encolar operación pendiente. Si la colmena aún es temporal (creada
        // offline y no sincronizada), actualizamos la operación de creación
        // en cola en lugar de encolar un update aparte.
        if (beehiveId.startsWith('temp_')) {
          final pendingOps = await beehiveLocalDataSource.getPendingOperations();
          final createOp = pendingOps.where(
            (op) =>
                op.beehiveId == beehiveId &&
                op.type == BeehiveOperationType.create,
          );
          if (createOp.isNotEmpty) {
            final op = createOp.first;
            final mergedData = Map<String, dynamic>.from(op.data ?? {});
            mergedData['beehive_number'] = updated.beehiveNumber;
            mergedData['activity_level'] = updated.activityLevel;
            mergedData['bee_population'] = updated.beePopulation;
            mergedData['food_frames'] = updated.foodFrames;
            mergedData['brood_frames'] = updated.broodFrames;
            mergedData['hive_status'] = updated.hiveStatus;
            mergedData['health_status'] = updated.healthStatus;
            mergedData['has_production_chamber'] = updated.hasProductionChamber;
            mergedData['observations'] = updated.observations;
            mergedData['treatments'] = updated.treatments;

            await beehiveLocalDataSource.removePendingOperation(op.id);
            await beehiveLocalDataSource.addPendingOperation(
              op.copyWith(data: mergedData),
            );
            return Right(updated);
          }
        }

        await beehiveLocalDataSource.addPendingOperation(
          PendingBeehiveOperation(
            id: 'op_${DateTime.now().millisecondsSinceEpoch}',
            type: BeehiveOperationType.update,
            beehiveId: beehiveId,
            apiaryId: apiaryId,
            data: {
              'beehive_number': beehiveNumber,
              'activity_level': activityLevel,
              'bee_population': beePopulation,
              'food_frames': foodFrames,
              'brood_frames': broodFrames,
              'hive_status': hiveStatus,
              'health_status': healthStatus,
              'has_production_chamber': hasProductionChamber,
              'observations': observations,
              'treatments': treatments,
            },
            createdAt: DateTime.now(),
          ),
        );

        return Right(updated);
      } catch (e) {
        return Left(CacheFailure('Error al actualizar colmena localmente: ${e.toString()}'));
      }
    }
  }

  @override
  Future<Either<Failure, void>> deleteBeehive(
    String beehiveId,
    String apiaryId,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final token = await localDataSource.getToken();
        if (token == null) {
          return const Left(AuthFailure('No se encontró el token de autenticación.'));
        }
        await remoteDataSource.deleteBeehive(beehiveId, apiaryId, token);

        // Eliminar del cache local
        await beehiveLocalDataSource.deleteLocalBeehive(apiaryId, beehiveId);

        return const Right(null);
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    } else {
      // OFFLINE: eliminar localmente y encolar
      try {
        await beehiveLocalDataSource.deleteLocalBeehive(apiaryId, beehiveId);

        if (beehiveId.startsWith('temp_')) {
          // Colmena creada offline y aún no sincronizada: basta con eliminar
          // sus operaciones pendientes (create/update) para que nunca se suba.
          final pendingOps = await beehiveLocalDataSource.getPendingOperations();
          for (final op in pendingOps) {
            if (op.beehiveId == beehiveId) {
              await beehiveLocalDataSource.removePendingOperation(op.id);
            }
          }
        } else {
          // Colmena que existe en el servidor: encolar la eliminación.
          await beehiveLocalDataSource.addPendingOperation(
            PendingBeehiveOperation(
              id: 'op_${DateTime.now().millisecondsSinceEpoch}',
              type: BeehiveOperationType.delete,
              beehiveId: beehiveId,
              apiaryId: apiaryId,
              createdAt: DateTime.now(),
            ),
          );
        }

        return const Right(null);
      } catch (e) {
        return Left(CacheFailure('Error al eliminar colmena localmente: ${e.toString()}'));
      }
    }
  }
}
