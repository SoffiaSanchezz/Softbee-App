import 'package:either_dart/either.dart';
import '../entities/treatment.dart';
import '../repositories/treatment_repository.dart';

class CreateFollowup {
  final TreatmentRepository repository;

  CreateFollowup(this.repository);

  Future<Either<String, Followup>> execute(Map<String, dynamic> followupData) {
    return repository.createFollowup(followupData);
  }
}
