import 'package:either_dart/either.dart';
import '../entities/treatment.dart';
import '../repositories/treatment_repository.dart';

class UpdateTreatment {
  final TreatmentRepository repository;

  UpdateTreatment(this.repository);

  Future<Either<String, Treatment>> execute(String id, Map<String, dynamic> treatmentData) {
    return repository.updateTreatment(id, treatmentData);
  }
}
