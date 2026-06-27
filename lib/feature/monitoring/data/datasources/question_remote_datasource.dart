import 'package:dio/dio.dart';
import '../../domain/entities/question_model.dart';

abstract class QuestionRemoteDataSource {
  Future<List<Pregunta>> getPreguntas(String apiaryId, String token);
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
  Future<List<Pregunta>> getTemplates(String token) async {
    try {
      final response = await httpClient.get(
        '/api/v1/questions/templates',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      final List<dynamic> data = response.data as List<dynamic>;

      final List<Pregunta> templates = [];
      for (var json in data) {
        try {
          final Map<String, dynamic> mapped = Map<String, dynamic>.from(json);
          templates.add(
            Pregunta(
              id: '', // No tiene ID real hasta crearse
              apiarioId: '',
              texto: mapped['pregunta'] ?? mapped['question_text'] ?? '',
              tipoRespuesta:
                  mapped['tipo'] ?? mapped['question_type'] ?? 'texto',
              categoria: mapped['categoria'] ?? mapped['category'],
              obligatoria:
                  mapped['obligatoria'] ?? mapped['is_required'] ?? false,
              opciones: mapped['opciones'] != null
                  ? List<String>.from(mapped['opciones'])
                  : (mapped['options'] != null
                        ? List<String>.from(mapped['options'])
                        : null),
              min:
                  (mapped['min'] as num?)?.toInt() ??
                  (mapped['min_value'] as num?)?.toInt(),
              max:
                  (mapped['max'] as num?)?.toInt() ??
                  (mapped['max_value'] as num?)?.toInt(),
              orden: 0,
            ),
          );
        } catch (e) {
          print('Error mapeando plantilla individual: $e');
        }
      }
      return templates;
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
}
