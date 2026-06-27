import 'package:either_dart/either.dart';
import 'package:Softbee/core/error/failures.dart';
import 'package:Softbee/feature/beehive/domain/entities/beehive.dart';

abstract class BeehiveRepository {
  Future<Either<Failure, List<Beehive>>> getBeehivesByApiary(String apiaryId);
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
  );
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
  );
  Future<Either<Failure, void>> deleteBeehive(
    String beehiveId,
    String apiaryId,
  );
}
