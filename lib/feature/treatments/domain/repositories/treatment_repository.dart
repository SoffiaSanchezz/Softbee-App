import 'package:either_dart/either.dart';
import '../entities/treatment.dart';

abstract class TreatmentRepository {
  Future<Either<String, List<Treatment>>> getTreatmentsByHive(String hiveId);
  Future<Either<String, Treatment>> createTreatment(Map<String, dynamic> treatmentData);
  Future<Either<String, Followup>> createFollowup(Map<String, dynamic> followupData);
}
