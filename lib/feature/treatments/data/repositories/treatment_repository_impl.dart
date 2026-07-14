import 'package:either_dart/either.dart';
import 'package:dio/dio.dart';
import '../../domain/entities/treatment.dart';
import '../../domain/repositories/treatment_repository.dart';
import '../datasources/treatment_remote_datasource.dart';

class TreatmentRepositoryImpl implements TreatmentRepository {
  final TreatmentRemoteDataSource remoteDataSource;

  TreatmentRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<String, List<Treatment>>> getTreatmentsByHive(String hiveId) async {
    try {
      final treatments = await remoteDataSource.getTreatmentsByHive(hiveId);
      return Right(treatments);
    } on DioException catch (e) {
      return Left(e.message ?? 'Error al obtener tratamientos');
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, Treatment>> createTreatment(Map<String, dynamic> treatmentData) async {
    try {
      final treatment = await remoteDataSource.createTreatment(treatmentData);
      return Right(treatment);
    } on DioException catch (e) {
      return Left(e.message ?? 'Error al crear tratamiento');
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, Followup>> createFollowup(Map<String, dynamic> followupData) async {
    try {
      final followup = await remoteDataSource.createFollowup(followupData);
      return Right(followup);
    } on DioException catch (e) {
      return Left(e.message ?? 'Error al crear seguimiento');
    } catch (e) {
      return Left(e.toString());
    }
  }
}
