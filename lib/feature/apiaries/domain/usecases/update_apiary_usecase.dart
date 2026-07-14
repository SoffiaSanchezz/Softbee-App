import 'package:Softbee/core/error/failures.dart';
import 'package:Softbee/core/usecase/usecase.dart';
import 'package:Softbee/feature/apiaries/domain/entities/apiary.dart';
import 'package:Softbee/feature/apiaries/domain/repositories/apiary_repository.dart';
import 'package:either_dart/either.dart';

class UpdateApiaryParams {
  final String apiaryId;
  final String userId;
  final String? name;
  final String? location;
  final int? beehivesCount;

  UpdateApiaryParams({
    required this.apiaryId,
    required this.userId,
    this.name,
    this.location,
    this.beehivesCount,
  });
}

class UpdateApiaryUseCase implements UseCase<Apiary, UpdateApiaryParams> {
  final ApiaryRepository repository;

  UpdateApiaryUseCase(this.repository);

  @override
  Future<Either<Failure, Apiary>> call(UpdateApiaryParams params) async {
    return await repository.updateApiary(
      params.apiaryId,
      params.userId,
      params.name,
      params.location,
      params.beehivesCount,
    );
  }
}
