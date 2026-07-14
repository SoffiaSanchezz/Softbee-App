import 'package:dio/dio.dart';
import '../../domain/entities/question_model.dart';
import '../../domain/entities/hive_question.dart';

abstract class QuestionRemoteDataSource {
  Future<List<Pregunta>> getPreguntas(String apiaryId, String token);
  Future<List<HiveQuestion>> getHiveQuestions(String hiveId, String token);
  Future<Pregunta> createPregunta(Pregunta pregunta, String token);
  Future<Pregunta> updatePregunta(Pregunta pregunta, String token);
  Future<void> deletePregunta(String id, String token);
  Future<void> reorderPreguntas(
    String apiaryId,
    List<String> order,
    String token,
  );
  Future<void> loadDefaults(String apiaryId, String token);
  Future<List<Pregunta>> getTemplates(String token);
  Future<HiveQuestion> assignQuestionToHive(
    String hiveId,
    String apiaryQuestionId,
    int order,
    String token,
  );
  Future<void> unassignQuestionFromHive(String hiveQuestionId, String token);
}

class QuestionRemoteDataSourceImpl implements QuestionRemoteDataSource {
  final Dio httpClient;

  QuestionRemoteDataSourceImpl(this.httpClient);

  @override
  Future<List<Pregunta>> getPreguntas(String apiaryId, String token) async {
    try {
      final response = await httpClient.get(
        '/api/v1/questions/apiary/$apiaryId',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      final List<dynamic> data = response.data as List<dynamic>;
      return data
          .map<Pregunta>(
            (json) => Pregunta.fromJson(Map<String, dynamic>.from(json)),
          )
          .toList();
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Error obteniendo preguntas',
      );
    }
  }

  @override
  Future<List<HiveQuestion>> getHiveQuestions(String hiveId, String token) async {
    try {
      final response = await httpClient.get(
        '/api/v1/questions/hive/$hiveId',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      final List<dynamic> data = response.data as List<dynamic>;
      return data
          .map<HiveQuestion>(
            (json) => HiveQuestion.fromJson(Map<String, dynamic>.from(json)),
          )
          .toList();
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Error obteniendo preguntas de colmena',
      );
    }
  }

  @override
  Future<List<Pregunta>> getTemplates(String token) async {
    try {
      final response = await httpClient.get(
        '/api/v1/questions/templates',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      final List<dynamic> data = response.data as List<dynamic>;

      return data
          .map<Pregunta>(
            (json) => Pregunta.fromJson(Map<String, dynamic>.from(json)),
          )
          .toList();
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Error obteniendo banco de preguntas',
      );
    }
  }

  @override
  Future<void> loadDefaults(String apiaryId, String token) async {
    try {
      await httpClient.post(
        '/api/v1/questions/load_defaults/$apiaryId',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Error cargando banco de preguntas',
      );
    }
  }

  @override
  Future<Pregunta> createPregunta(Pregunta pregunta, String token) async {
    try {
      final response = await httpClient.post(
        '/api/v1/questions',
        data: pregunta.toJson(),
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return Pregunta.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Error creando pregunta');
    }
  }

  @override
  Future<Pregunta> updatePregunta(Pregunta pregunta, String token) async {
    try {
      final response = await httpClient.put(
        '/api/v1/questions/${pregunta.id}',
        data: pregunta.toJson(),
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return Pregunta.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Error actualizando pregunta',
      );
    }
  }

  @override
  Future<void> deletePregunta(String id, String token) async {
    try {
      await httpClient.delete(
        '/api/v1/questions/$id',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Error eliminando pregunta',
      );
    }
  }

  @override
  Future<void> reorderPreguntas(
    String apiaryId,
    List<String> order,
    String token,
  ) async {
    try {
      await httpClient.put(
        '/api/v1/questions/apiary/$apiaryId/reorder',
        data: {'order': order},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Error reordenando preguntas',
      );
    }
  }

  @override
  Future<HiveQuestion> assignQuestionToHive(
    String hiveId,
    String apiaryQuestionId,
    int order,
    String token,
  ) async {
    try {
      final response = await httpClient.post(
        '/api/v1/questions/hive',
        data: {
          'hive_id': hiveId,
          'apiary_question_id': apiaryQuestionId,
          'display_order': order,
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return HiveQuestion.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Error asignando pregunta a colmena',
      );
    }
  }

  @override
  Future<void> unassignQuestionFromHive(
    String hiveQuestionId,
    String token,
  ) async {
    try {
      await httpClient.delete(
        '/api/v1/questions/hive/$hiveQuestionId',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Error desasignando pregunta',
      );
    }
  }
}
