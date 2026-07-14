import 'package:either_dart/either.dart';
import '../entities/treatment.dart';
import '../repositories/treatment_repository.dart';

class GetTreatmentsByHive {
  final TreatmentRepository repository;

  GetTreatmentsByHive(this.repository);

  Future<Either<String, List<Treatment>>> execute(String hiveId) {
    return repository.getTreatmentsByHive(hiveId);
  }
}
