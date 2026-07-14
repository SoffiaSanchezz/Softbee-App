import 'package:either_dart/either.dart';
import '../../../../core/error/failures.dart';
import '../../../auth/data/datasources/auth_local_datasource.dart';
import '../../domain/entities/hive_answer.dart';
import '../../domain/repositories/answer_repository.dart';
import '../datasources/answer_remote_datasource.dart';

class AnswerRepositoryImpl implements AnswerRepository {
  final AnswerRemoteDataSource remoteDataSource;
  final AuthLocalDataSource localDataSource;

  AnswerRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<Either<Failure, HiveAnswer>> createAnswer(HiveAnswer answer) async {
    try {
      final token = await localDataSource.getToken();
      if (token == null) return const Left(AuthFailure('No token found'));
      final result = await remoteDataSource.createAnswer(answer, token);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<HiveAnswer>>> createAnswersBatch(List<HiveAnswer> answers) async {
    try {
      final token = await localDataSource.getToken();
      if (token == null) return const Left(AuthFailure('No token found'));
      final result = await remoteDataSource.createAnswersBatch(answers, token);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<HiveAnswer>>> getAnswersByHive(String hiveId) async {
    try {
      final token = await localDataSource.getToken();
      if (token == null) return const Left(AuthFailure('No token found'));
      final result = await remoteDataSource.getAnswersByHive(hiveId, token);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
