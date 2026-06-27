import 'package:either_dart/either.dart';
import '../../../../core/error/failures.dart';
import '../entities/question_model.dart';

abstract class QuestionRepository {
  Future<Either<Failure, List<Pregunta>>> getPreguntas(String apiaryId);
  Future<Either<Failure, Pregunta>> createPregunta(Pregunta pregunta);
  Future<Either<Failure, Pregunta>> updatePregunta(Pregunta pregunta);
  Future<Either<Failure, void>> deletePregunta(String id);
  Future<Either<Failure, void>> reorderPreguntas(
    String apiaryId,
    List<String> order,
  );
  Future<Either<Failure, void>> loadDefaults(String apiaryId);
  Future<Either<Failure, List<Pregunta>>> getTemplates();
}
