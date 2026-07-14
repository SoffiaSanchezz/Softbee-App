import 'package:either_dart/either.dart';
import 'package:Softbee/core/error/failures.dart';
import 'package:Softbee/core/usecase/usecase.dart';
import 'package:Softbee/feature/beehive/domain/entities/beehive.dart';
import 'package:Softbee/feature/beehive/domain/repositories/beehive_repository.dart';

class UpdateBeehiveParams {
  final String beehiveId;
  final String apiaryId; // Add apiaryId for authorization/context
  final int?
  beehiveNumber; // Beehive number might be updatable, if not, remove.
  final String? activityLevel;
  final String? beePopulation;
  final int? foodFrames;
  final int? broodFrames;
  final String? hiveStatus;
  final String? healthStatus;
  final String? hasProductionChamber;
  final String? observations;
  final bool? treatments;

  UpdateBeehiveParams({
    required this.beehiveId,
    required this.apiaryId,
    this.beehiveNumber,
    this.activityLevel,
    this.beePopulation,
    this.foodFrames,
    this.broodFrames,
    this.hiveStatus,
    this.healthStatus,
    this.hasProductionChamber,
    this.observations,
    this.treatments,
  });
}

class UpdateBeehiveUseCase implements UseCase<Beehive, UpdateBeehiveParams> {
  final BeehiveRepository repository;

  UpdateBeehiveUseCase(this.repository);

  @override
  Future<Either<Failure, Beehive>> call(UpdateBeehiveParams params) async {
    return await repository.updateBeehive(
      params.beehiveId,
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
      params.treatments,
    );
  }
}
