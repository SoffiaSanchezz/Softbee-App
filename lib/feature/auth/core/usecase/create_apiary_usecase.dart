// lib/feature/auth/core/usecase/create_apiary_usecase.dart
import 'package:either_dart/either.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/auth_repository.dart';

class CreateApiaryParams {
  final String userId;
  final String apiaryName;
  final String location;
  final int beehivesCount;
  final String token;

  CreateApiaryParams({
    required this.userId,
    required this.apiaryName,
    required this.location,
    required this.beehivesCount,
    required this.token,
  });
}

class CreateApiaryUseCase implements UseCase<void, CreateApiaryParams> {
  final AuthRepository repository;

  CreateApiaryUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(CreateApiaryParams params) async {
    return await repository.createApiary(
      params.userId,
      params.apiaryName,
      params.location,
      params.beehivesCount,
      params.token,
    );
  }
}
