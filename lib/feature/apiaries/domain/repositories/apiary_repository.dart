import 'package:Softbee/core/error/failures.dart';
import 'package:Softbee/feature/apiaries/domain/entities/apiary.dart';
import 'package:either_dart/either.dart';

abstract class ApiaryRepository {
  Future<Either<Failure, List<Apiary>>> getApiaries();
  Future<Either<Failure, Apiary>> createApiary(
    String userId,
    String name,
    String? location,
    int? beehivesCount,
  );
  Future<Either<Failure, Apiary>> updateApiary(
    String apiaryId,
    String userId,
    String? name,
    String? location,
    int? beehivesCount,
  );
  Future<Either<Failure, void>> deleteApiary(String apiaryId, String userId);
}
