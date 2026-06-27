import 'package:either_dart/either.dart';
import '../../../../core/error/failures.dart';
import '../../../auth/data/datasources/auth_local_datasource.dart';
import '../../domain/entities/question_model.dart';
import '../../domain/repositories/question_repository.dart';
import '../datasources/question_remote_datasource.dart';

class QuestionRepositoryImpl implements QuestionRepository {
  final QuestionRemoteDataSource remoteDataSource;
  final AuthLocalDataSource localDataSource;

  QuestionRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<Either<Failure, List<Pregunta>>> getPreguntas(String apiaryId) async {
    try {
      final token = await localDataSource.getToken();
      if (token == null) return const Left(AuthFailure('No token found'));
      final result = await remoteDataSource.getPreguntas(apiaryId, token);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Pregunta>> createPregunta(Pregunta pregunta) async {
    try {
      final token = await localDataSource.getToken();
      if (token == null) return const Left(AuthFailure('No token found'));
      final result = await remoteDataSource.createPregunta(pregunta, token);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Pregunta>> updatePregunta(Pregunta pregunta) async {
    try {
      final token = await localDataSource.getToken();
      if (token == null) return const Left(AuthFailure('No token found'));
      final result = await remoteDataSource.updatePregunta(pregunta, token);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deletePregunta(String id) async {
    try {
      final token = await localDataSource.getToken();
      if (token == null) return const Left(AuthFailure('No token found'));
      await remoteDataSource.deletePregunta(id, token);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> reorderPreguntas(
    String apiaryId,
    List<String> order,
  ) async {
    try {
      final token = await localDataSource.getToken();
      if (token == null) return const Left(AuthFailure('No token found'));
      await remoteDataSource.reorderPreguntas(apiaryId, order, token);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> loadDefaults(String apiaryId) async {
    try {
      final token = await localDataSource.getToken();
      if (token == null) return const Left(AuthFailure('No token found'));
      await remoteDataSource.loadDefaults(apiaryId, token);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Pregunta>>> getTemplates() async {
    try {
      final token = await localDataSource.getToken();
      if (token == null) return const Left(AuthFailure('No token found'));
      final result = await remoteDataSource.getTemplates(token);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
