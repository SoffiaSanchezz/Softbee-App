import 'package:Softbee/core/error/failures.dart';
import 'package:Softbee/core/usecase/usecase.dart';
import 'package:Softbee/feature/apiaries/domain/entities/apiary.dart';
import 'package:Softbee/feature/apiaries/domain/repositories/apiary_repository.dart';
import 'package:either_dart/either.dart';

class CreateApiaryParams {
  final String userId;
  final String name;
  final String? location;
  final int? beehivesCount;

  CreateApiaryParams({
    required this.userId,
    required this.name,
    this.location,
    this.beehivesCount,
  });
}

class CreateApiaryUseCase implements UseCase<Apiary, CreateApiaryParams> {
  final ApiaryRepository repository;

  CreateApiaryUseCase(this.repository);

  @override
  Future<Either<Failure, Apiary>> call(CreateApiaryParams params) async {
    return await repository.createApiary(
      params.userId,
      params.name,
      params.location,
      params.beehivesCount,
    );
  }
}
