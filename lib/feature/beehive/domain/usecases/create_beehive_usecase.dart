import 'package:either_dart/either.dart';
import 'package:Softbee/core/error/failures.dart';
import 'package:Softbee/core/usecase/usecase.dart';
import 'package:Softbee/feature/beehive/domain/entities/beehive.dart';
import 'package:Softbee/feature/beehive/domain/repositories/beehive_repository.dart';

class CreateBeehiveParams {
  final String apiaryId;
  final int beehiveNumber;
  final String? activityLevel;
  final String? beePopulation;
  final int? foodFrames;
  final int? broodFrames;
  final String? hiveStatus;
  final String? healthStatus;
  final String? hasProductionChamber;
  final String? observations;

  CreateBeehiveParams({
    required this.apiaryId,
    required this.beehiveNumber,
    this.activityLevel,
    this.beePopulation,
    this.foodFrames,
    this.broodFrames,
    this.hiveStatus,
    this.healthStatus,
    this.hasProductionChamber,
    this.observations,
  });
}

class CreateBeehiveUseCase implements UseCase<Beehive, CreateBeehiveParams> {
  final BeehiveRepository repository;

  CreateBeehiveUseCase(this.repository);

  @override
  Future<Either<Failure, Beehive>> call(CreateBeehiveParams params) async {
    return await repository.createBeehive(
      params.apiaryId,
      params.beehiveNumber,
      params.activityLevel,
      params.beePopulation,
      params.foodFrames,
      params.broodFrames,
      params.hiveStatus,
      params.healthStatus,
      params.hasProductionChamber,
      params.observations,
    );
  }
}
