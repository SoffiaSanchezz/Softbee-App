import 'package:either_dart/either.dart';
import 'package:dio/dio.dart';
import '../../domain/entities/treatment.dart';
import '../../domain/repositories/treatment_repository.dart';
import '../datasources/treatment_remote_datasource.dart';

class TreatmentRepositoryImpl implements TreatmentRepository {
  final TreatmentRemoteDataSource remoteDataSource;

  TreatmentRepositoryImpl({required this.remoteDataSource});

  String _mapDioError(DioException e, String fallback) {
    final data = e.response?.data;
    if (data is Map && data['message'] != null) {
      return data['message'].toString();
    }
    return e.message ?? fallback;
  }

  @override
  Future<Either<String, List<Treatment>>> getTreatmentsByHive(String hiveId) async {
    try {
      final treatments = await remoteDataSource.getTreatmentsByHive(hiveId);
      return Right(treatments);
    } on DioException catch (e) {
      return Left(_mapDioError(e, 'Error al obtener tratamientos'));
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, Treatment>> getTreatmentById(String id) async {
    try {
      final treatment = await remoteDataSource.getTreatmentById(id);
      return Right(treatment);
    } on DioException catch (e) {
      return Left(_mapDioError(e, 'Error al obtener el tratamiento'));
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
      return Left(_mapDioError(e, 'Error al crear tratamiento'));
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, Treatment>> updateTreatment(String id, Map<String, dynamic> treatmentData) async {
    try {
      final treatment = await remoteDataSource.updateTreatment(id, treatmentData);
      return Right(treatment);
    } on DioException catch (e) {
      return Left(_mapDioError(e, 'Error al actualizar tratamiento'));
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, bool>> deleteTreatment(String id) async {
    try {
      await remoteDataSource.deleteTreatment(id);
      return const Right(true);
    } on DioException catch (e) {
      return Left(_mapDioError(e, 'Error al eliminar tratamiento'));
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
      return Left(_mapDioError(e, 'Error al crear seguimiento'));
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, Followup>> updateFollowup(String followupId, Map<String, dynamic> followupData) async {
    try {
      final followup = await remoteDataSource.updateFollowup(followupId, followupData);
      return Right(followup);
    } on DioException catch (e) {
      return Left(_mapDioError(e, 'Error al actualizar seguimiento'));
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, bool>> deleteFollowup(String followupId) async {
    try {
      await remoteDataSource.deleteFollowup(followupId);
      return const Right(true);
    } on DioException catch (e) {
      return Left(_mapDioError(e, 'Error al eliminar seguimiento'));
    } catch (e) {
      return Left(e.toString());
    }
  }
}
