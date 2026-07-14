import 'package:either_dart/either.dart';
import '../../../../core/error/failures.dart';
import '../entities/hive_answer.dart';

abstract class AnswerRepository {
  Future<Either<Failure, HiveAnswer>> createAnswer(HiveAnswer answer);
  Future<Either<Failure, List<HiveAnswer>>> createAnswersBatch(List<HiveAnswer> answers);
  Future<Either<Failure, List<HiveAnswer>>> getAnswersByHive(String hiveId);
}
