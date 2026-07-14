import 'package:either_dart/either.dart';
import '../entities/treatment.dart';
import '../repositories/treatment_repository.dart';

class CreateTreatment {
  final TreatmentRepository repository;

  CreateTreatment(this.repository);

  Future<Either<String, Treatment>> execute(Map<String, dynamic> treatmentData) {
    return repository.createTreatment(treatmentData);
  }
}
