import 'package:dio/dio.dart';
import '../models/treatment_model.dart';

abstract class TreatmentRemoteDataSource {
  Future<List<TreatmentModel>> getTreatmentsByHive(String hiveId);
  Future<TreatmentModel> getTreatmentById(String id);
  Future<TreatmentModel> createTreatment(Map<String, dynamic> treatmentData);
  Future<TreatmentModel> updateTreatment(String id, Map<String, dynamic> treatmentData);
  Future<void> deleteTreatment(String id);
  Future<FollowupModel> createFollowup(Map<String, dynamic> followupData);
  Future<FollowupModel> updateFollowup(String followupId, Map<String, dynamic> followupData);
  Future<void> deleteFollowup(String followupId);
}

class TreatmentRemoteDataSourceImpl implements TreatmentRemoteDataSource {
  final Dio _dio;

  TreatmentRemoteDataSourceImpl(this._dio);

  @override
  Future<List<TreatmentModel>> getTreatmentsByHive(String hiveId) async {
    final response = await _dio.get('/api/v1/treatments/hive/$hiveId');
    return (response.data as List)
        .map((t) => TreatmentModel.fromJson(t))
        .toList();
  }

  @override
  Future<TreatmentModel> getTreatmentById(String id) async {
    final response = await _dio.get('/api/v1/treatments/$id');
    return TreatmentModel.fromJson(response.data);
  }

  @override
  Future<TreatmentModel> createTreatment(Map<String, dynamic> treatmentData) async {
    final response = await _dio.post('/api/v1/treatments', data: treatmentData);
    return TreatmentModel.fromJson(response.data);
  }

  @override
  Future<TreatmentModel> updateTreatment(String id, Map<String, dynamic> treatmentData) async {
    final response = await _dio.put('/api/v1/treatments/$id', data: treatmentData);
    return TreatmentModel.fromJson(response.data);
  }

  @override
  Future<void> deleteTreatment(String id) async {
    await _dio.delete('/api/v1/treatments/$id');
  }

  @override
  Future<FollowupModel> createFollowup(Map<String, dynamic> followupData) async {
    final response = await _dio.post('/api/v1/treatments/followup', data: followupData);
    return FollowupModel.fromJson(response.data);
  }

  @override
  Future<FollowupModel> updateFollowup(String followupId, Map<String, dynamic> followupData) async {
    final response = await _dio.put('/api/v1/treatments/followup/$followupId', data: followupData);
    return FollowupModel.fromJson(response.data);
  }

  @override
  Future<void> deleteFollowup(String followupId) async {
    await _dio.delete('/api/v1/treatments/followup/$followupId');
  }
}
