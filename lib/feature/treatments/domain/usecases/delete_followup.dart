import 'package:either_dart/either.dart';
import '../repositories/treatment_repository.dart';

class DeleteFollowup {
  final TreatmentRepository repository;

  DeleteFollowup(this.repository);

  Future<Either<String, bool>> execute(String followupId) {
    return repository.deleteFollowup(followupId);
  }
}
