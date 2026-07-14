import 'package:dio/dio.dart';
import '../../domain/entities/hive_answer.dart';

abstract class AnswerRemoteDataSource {
  Future<HiveAnswer> createAnswer(HiveAnswer answer, String token);
  Future<List<HiveAnswer>> createAnswersBatch(List<HiveAnswer> answers, String token);
  Future<List<HiveAnswer>> getAnswersByHive(String hiveId, String token);
}

class AnswerRemoteDataSourceImpl implements AnswerRemoteDataSource {
  final Dio httpClient;

  AnswerRemoteDataSourceImpl(this.httpClient);

  @override
  Future<HiveAnswer> createAnswer(HiveAnswer answer, String token) async {
    try {
      final response = await httpClient.post(
        '/api/v1/answers',
        data: answer.toJson(),
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return HiveAnswer.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Error guardando respuesta');
    }
  }

  @override
  Future<List<HiveAnswer>> createAnswersBatch(List<HiveAnswer> answers, String token) async {
    try {
      final response = await httpClient.post(
        '/api/v1/answers/batch',
        data: {'answers': answers.map((a) => a.toJson()).toList()},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      final List<dynamic> data = response.data['answers'] as List<dynamic>;
      return data.map((json) => HiveAnswer.fromJson(json)).toList();
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Error guardando lote de respuestas');
    }
  }

  @override
  Future<List<HiveAnswer>> getAnswersByHive(String hiveId, String token) async {
    try {
      final response = await httpClient.get(
        '/api/v1/answers/hive/$hiveId',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      final List<dynamic> data = response.data as List<dynamic>;
      return data.map((json) => HiveAnswer.fromJson(json)).toList();
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Error obteniendo respuestas de colmena');
    }
  }
}
