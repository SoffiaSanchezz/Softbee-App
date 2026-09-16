import 'package:either_dart/either.dart';
import '../entities/treatment.dart';

abstract class TreatmentRepository {
  Future<Either<String, List<Treatment>>> getTreatmentsByHive(String hiveId);
  Future<Either<String, Treatment>> getTreatmentById(String id);
  Future<Either<String, Treatment>> createTreatment(Map<String, dynamic> treatmentData);
  Future<Either<String, Treatment>> updateTreatment(String id, Map<String, dynamic> treatmentData);
  Future<Either<String, bool>> deleteTreatment(String id);
  Future<Either<String, Followup>> createFollowup(Map<String, dynamic> followupData);
  Future<Either<String, Followup>> updateFollowup(String followupId, Map<String, dynamic> followupData);
  Future<Either<String, bool>> deleteFollowup(String followupId);
}
