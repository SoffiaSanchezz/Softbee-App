import 'package:either_dart/either.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/sync/pending_sync_operation.dart';
import '../../../../core/sync/sync_queue.dart';
import '../../../auth/data/datasources/auth_local_datasource.dart';
import '../../domain/entities/question_model.dart';
import '../../domain/entities/hive_question.dart';
import '../../domain/repositories/question_repository.dart';
import '../datasources/question_local_datasource.dart';
import '../datasources/question_remote_datasource.dart';
import '../sync/question_sync_handler.dart';

class QuestionRepositoryImpl implements QuestionRepository {
  final QuestionRemoteDataSource remoteDataSource;
  final AuthLocalDataSource localDataSource;
  final QuestionLocalDataSource questionLocalDataSource;
  final NetworkInfo networkInfo;
  final SyncQueue syncQueue;

  QuestionRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.questionLocalDataSource,
    required this.networkInfo,
    required this.syncQueue,
  });

  String _newOpId() => 'op_${DateTime.now().microsecondsSinceEpoch}';

  @override
  Future<Either<Failure, List<Pregunta>>> getPreguntas(String apiaryId) async {
    if (await networkInfo.isConnected) {
      try {
        final token = await localDataSource.getToken();
        if (token == null) return const Left(AuthFailure('No token found'));
        final result = await remoteDataSource.getPreguntas(apiaryId, token);

        // Cachear preguntas localmente
        await questionLocalDataSource.cachePreguntas(apiaryId, result);

        return Right(result);
      } catch (e) {
        // Fallback a datos locales
        try {
          final localPreguntas = await questionLocalDataSource.getCachedPreguntas(apiaryId);
          if (localPreguntas.isNotEmpty) {
            return Right(localPreguntas);
          }
        } catch (_) {}
        return Left(ServerFailure(e.toString()));
      }
    } else {
      // MODO OFFLINE
      try {
        final localPreguntas = await questionLocalDataSource.getCachedPreguntas(apiaryId);
        return Right(localPreguntas);
      } catch (e) {
        return Left(CacheFailure("No hay preguntas disponibles offline"));
      }
    }
  }

  @override
  Future<Either<Failure, List<HiveQuestion>>> getHiveQuestions(String hiveId) async {
    if (await networkInfo.isConnected) {
      try {
        final token = await localDataSource.getToken();
        if (token == null) return const Left(AuthFailure('No token found'));
        final result = await remoteDataSource.getHiveQuestions(hiveId, token);

        // Cachear preguntas de la colmena
        await questionLocalDataSource.cacheHiveQuestions(hiveId, result);

        return Right(result);
      } catch (e) {
        // Fallback a datos locales
        try {
          final localQuestions = await questionLocalDataSource.getCachedHiveQuestions(hiveId);
          if (localQuestions.isNotEmpty) {
            return Right(localQuestions);
          }
        } catch (_) {}
        return Left(ServerFailure(e.toString()));
      }
    } else {
      // MODO OFFLINE
      try {
        final localQuestions = await questionLocalDataSource.getCachedHiveQuestions(hiveId);
        return Right(localQuestions);
      } catch (e) {
        return Left(CacheFailure("No hay preguntas de colmena disponibles offline"));
      }
    }
  }

  @override
  Future<Either<Failure, Pregunta>> createPregunta(Pregunta pregunta) async {
    if (await networkInfo.isConnected) {
      try {
        final token = await localDataSource.getToken();
        if (token == null) return const Left(AuthFailure('No token found'));
        final result = await remoteDataSource.createPregunta(pregunta, token);

        // Guardar en cache local
        await questionLocalDataSource.savePregunta(result.apiarioId, result);

        return Right(result);
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    } else {
      // OFFLINE: guardar localmente con id temporal y encolar
      try {
        final apiaryId = pregunta.apiarioId;
        if (apiaryId.isEmpty) {
          return const Left(CacheFailure('Falta el apiario para guardar la pregunta offline'));
        }

        final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
        final localPregunta = pregunta.copyWith(id: tempId);
        await questionLocalDataSource.savePregunta(apiaryId, localPregunta);

        await syncQueue.add(
          PendingSyncOperation(
            id: _newOpId(),
            entity: kQuestionEntity,
            type: SyncOperationType.create,
            entityId: tempId,
            apiaryId: apiaryId,
            data: localPregunta.toJson(),
            createdAt: DateTime.now(),
          ),
        );

        return Right(localPregunta);
      } catch (e) {
        return Left(CacheFailure('Error al guardar pregunta localmente: ${e.toString()}'));
      }
    }
  }

  @override
  Future<Either<Failure, Pregunta>> updatePregunta(Pregunta pregunta) async {
    if (await networkInfo.isConnected) {
      try {
        final token = await localDataSource.getToken();
        if (token == null) return const Left(AuthFailure('No token found'));
        final result = await remoteDataSource.updatePregunta(pregunta, token);

        // Actualizar cache local
        await questionLocalDataSource.updateLocalPregunta(result.apiarioId, result);

        return Right(result);
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    } else {
      // OFFLINE: actualizar localmente y encolar
      try {
        final apiaryId = pregunta.apiarioId;
        if (apiaryId.isEmpty) {
          return const Left(CacheFailure('Falta el apiario para actualizar la pregunta offline'));
        }

        await questionLocalDataSource.updateLocalPregunta(apiaryId, pregunta);

        // Si la pregunta aún es temporal, fusionamos en su operación create.
        if (pregunta.id.startsWith('temp_')) {
          final ops = await syncQueue.getByEntity(kQuestionEntity);
          final createOps = ops.where(
            (op) =>
                op.entityId == pregunta.id &&
                op.type == SyncOperationType.create,
          );
          if (createOps.isNotEmpty) {
            final op = createOps.first;
            await syncQueue.remove(op.id);
            await syncQueue.add(op.copyWith(data: pregunta.toJson()));
            return Right(pregunta);
          }
        }

        await syncQueue.add(
          PendingSyncOperation(
            id: _newOpId(),
            entity: kQuestionEntity,
            type: SyncOperationType.update,
            entityId: pregunta.id,
            apiaryId: apiaryId,
            data: pregunta.toJson(),
            createdAt: DateTime.now(),
          ),
        );

        return Right(pregunta);
      } catch (e) {
        return Left(CacheFailure('Error al actualizar pregunta localmente: ${e.toString()}'));
      }
    }
  }

  @override
  Future<Either<Failure, void>> deletePregunta(String id, {String? apiaryId}) async {
    if (await networkInfo.isConnected) {
      try {
        final token = await localDataSource.getToken();
        if (token == null) return const Left(AuthFailure('No token found'));
        await remoteDataSource.deletePregunta(id, token);
        if (apiaryId != null) {
          await questionLocalDataSource.deleteLocalPregunta(apiaryId, id);
        }
        return const Right(null);
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    } else {
      // OFFLINE: eliminar del cache local y encolar
      try {
        if (apiaryId != null) {
          await questionLocalDataSource.deleteLocalPregunta(apiaryId, id);
        }

        if (id.startsWith('temp_')) {
          // Pregunta creada offline y no sincronizada: quitar sus operaciones.
          final ops = await syncQueue.getByEntity(kQuestionEntity);
          for (final op in ops) {
            if (op.entityId == id) {
              await syncQueue.remove(op.id);
            }
          }
        } else {
          await syncQueue.add(
            PendingSyncOperation(
              id: _newOpId(),
              entity: kQuestionEntity,
              type: SyncOperationType.delete,
              entityId: id,
              apiaryId: apiaryId,
              createdAt: DateTime.now(),
            ),
          );
        }

        return const Right(null);
      } catch (e) {
        return Left(CacheFailure('Error al eliminar pregunta localmente: ${e.toString()}'));
      }
    }
  }

  @override
  Future<Either<Failure, void>> reorderPreguntas(
    String apiaryId,
    List<String> order,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final token = await localDataSource.getToken();
        if (token == null) return const Left(AuthFailure('No token found'));
        await remoteDataSource.reorderPreguntas(apiaryId, order, token);
        return const Right(null);
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    } else {
      return Left(CacheFailure('No se puede reordenar sin conexión'));
    }
  }

  @override
  Future<Either<Failure, void>> loadDefaults(String apiaryId) async {
    if (await networkInfo.isConnected) {
      try {
        final token = await localDataSource.getToken();
        if (token == null) return const Left(AuthFailure('No token found'));
        await remoteDataSource.loadDefaults(apiaryId, token);
        return const Right(null);
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    } else {
      return Left(CacheFailure('No se puede cargar preguntas por defecto sin conexión'));
    }
  }

  @override
  Future<Either<Failure, List<Pregunta>>> getTemplates() async {
    if (await networkInfo.isConnected) {
      try {
        final token = await localDataSource.getToken();
        if (token == null) return const Left(AuthFailure('No token found'));
        final result = await remoteDataSource.getTemplates(token);

        // Cachear templates
        await questionLocalDataSource.cacheTemplates(result);

        return Right(result);
      } catch (e) {
        // Fallback a templates locales
        try {
          final localTemplates = await questionLocalDataSource.getCachedTemplates();
          if (localTemplates.isNotEmpty) {
            return Right(localTemplates);
          }
        } catch (_) {}
        return Left(ServerFailure(e.toString()));
      }
    } else {
      // MODO OFFLINE
      try {
        final localTemplates = await questionLocalDataSource.getCachedTemplates();
        return Right(localTemplates);
      } catch (e) {
        return Left(CacheFailure("No hay templates disponibles offline"));
      }
    }
  }

  @override
  Future<Either<Failure, HiveQuestion>> assignQuestionToHive(
    String hiveId,
    String apiaryQuestionId,
    int order,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final token = await localDataSource.getToken();
        if (token == null) return const Left(AuthFailure('No token found'));
        final result = await remoteDataSource.assignQuestionToHive(
          hiveId,
          apiaryQuestionId,
          order,
          token,
        );
        return Right(result);
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    } else {
      return Left(CacheFailure('No se puede asignar pregunta sin conexión'));
    }
  }

  @override
  Future<Either<Failure, void>> unassignQuestionFromHive(
    String hiveQuestionId,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final token = await localDataSource.getToken();
        if (token == null) return const Left(AuthFailure('No token found'));
        await remoteDataSource.unassignQuestionFromHive(hiveQuestionId, token);
        return const Right(null);
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    } else {
      return Left(CacheFailure('No se puede desasignar pregunta sin conexión'));
    }
  }
}
