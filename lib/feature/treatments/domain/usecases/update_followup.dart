import 'package:either_dart/either.dart';
import '../entities/treatment.dart';
import '../repositories/treatment_repository.dart';

class UpdateFollowup {
  final TreatmentRepository repository;

  UpdateFollowup(this.repository);

  Future<Either<String, Followup>> execute(String followupId, Map<String, dynamic> followupData) {
    return repository.updateFollowup(followupId, followupData);
  }
}
