import 'package:either_dart/either.dart';
import '../entities/treatment.dart';
import '../repositories/treatment_repository.dart';

class GetTreatmentById {
  final TreatmentRepository repository;

  GetTreatmentById(this.repository);

  Future<Either<String, Treatment>> execute(String id) {
    return repository.getTreatmentById(id);
  }
}
