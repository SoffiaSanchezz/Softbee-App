import 'package:either_dart/either.dart';
import '../repositories/treatment_repository.dart';

class DeleteTreatment {
  final TreatmentRepository repository;

  DeleteTreatment(this.repository);

  Future<Either<String, bool>> execute(String id) {
    return repository.deleteTreatment(id);
  }
}
