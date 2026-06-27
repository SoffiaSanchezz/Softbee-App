import 'package:either_dart/either.dart';
import 'package:Softbee/core/error/failures.dart';
import 'package:Softbee/feature/auth/data/datasources/auth_local_datasource.dart';
import 'package:Softbee/feature/beehive/data/datasources/beehive_remote_datasource.dart';
import 'package:Softbee/feature/beehive/domain/entities/beehive.dart';
import 'package:Softbee/feature/beehive/domain/repositories/beehive_repository.dart';

class BeehiveRepositoryImpl implements BeehiveRepository {
  final BeehiveRemoteDataSource remoteDataSource;
  final AuthLocalDataSource localDataSource;

  BeehiveRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<Either<Failure, List<Beehive>>> getBeehivesByApiary(
    String apiaryId,
  ) async {
    try {
      final token = await localDataSource.getToken();
      if (token == null) {
        return const Left(
          AuthFailure('No se encontró el token de autenticación.'),
        );
      }
      final result = await remoteDataSource.getBeehivesByApiary(
        apiaryId,
        token,
      );
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
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
  ) async {
    try {
      final token = await localDataSource.getToken();
      if (token == null) {
        return const Left(
          AuthFailure('No se encontró el token de autenticación.'),
        );
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
        token,
      );
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
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
  ) async {
    try {
      final token = await localDataSource.getToken();
      if (token == null) {
        return const Left(
          AuthFailure('No se encontró el token de autenticación.'),
        );
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
        token,
      );
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteBeehive(
    String beehiveId,
    String apiaryId,
  ) async {
    try {
      final token = await localDataSource.getToken();
      if (token == null) {
        return const Left(
          AuthFailure('No se encontró el token de autenticación.'),
        );
      }
      await remoteDataSource.deleteBeehive(beehiveId, apiaryId, token);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
