import 'package:dio/dio.dart';
import 'package:Softbee/core/network/dio_client.dart';
import '../models/treatment_model.dart';

abstract class TreatmentRemoteDataSource {
  Future<List<TreatmentModel>> getTreatmentsByHive(String hiveId);
  Future<TreatmentModel> createTreatment(Map<String, dynamic> treatmentData);
  Future<FollowupModel> createFollowup(Map<String, dynamic> followupData);
}

class TreatmentRemoteDataSourceImpl implements TreatmentRemoteDataSource {
  final Dio _dio;

  TreatmentRemoteDataSourceImpl(this._dio);

  @override
  Future<List<TreatmentModel>> getTreatmentsByHive(String hiveId) async {
    try {
      print('DEBUG: Fetching treatments for hive: $hiveId');
      final response = await _dio.get('/api/v1/treatments/hive/$hiveId');
      print('DEBUG: Response status: ${response.statusCode}');
      print('DEBUG: Response data: ${response.data}');
      return (response.data as List)
          .map((t) => TreatmentModel.fromJson(t))
          .toList();
    } catch (e) {
      print('DEBUG: Error fetching treatments: $e');
      rethrow;
    }
  }

  @override
  Future<TreatmentModel> createTreatment(Map<String, dynamic> treatmentData) async {
    try {
      final response = await _dio.post('/api/v1/treatments', data: treatmentData);
      return TreatmentModel.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<FollowupModel> createFollowup(Map<String, dynamic> followupData) async {
    try {
      final response = await _dio.post('/api/v1/treatments/followup', data: followupData);
      return FollowupModel.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }
}
