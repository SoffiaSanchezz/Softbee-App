import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Muestra el header Authorization sin volcar el JWT completo.
String _maskAuthHeader(String? token) {
  if (token == null) return 'Authorization AUSENTE (token null)';
  if (token.isEmpty) return 'Authorization con token VACÍO';
  final len = token.length;
  final preview =
      len <= 12 ? token : '${token.substring(0, 6)}...${token.substring(len - 4)}';
  return 'Authorization: Bearer $preview (len=$len)';
}

abstract class MayaRemoteDataSource {
  Future<Map<String, dynamic>> askMaya({
    required String prompt,
    String? sessionId,
    String agentId = 'general',
    String provider = 'gemini',
    Map<String, dynamic>? context,
    String? token,
  });

  Future<Map<String, dynamic>> iniciarMonitoreoVoz(String hiveId, String token);
  Future<void> guardarRespuestasVoz(String hiveId, List<Map<String, dynamic>> respuestas, String token);
}

class MayaRemoteDataSourceImpl implements MayaRemoteDataSource {
  final Dio httpClient;

  MayaRemoteDataSourceImpl(this.httpClient);

  @override
  Future<Map<String, dynamic>> askMaya({
    required String prompt,
    String? sessionId,
    String agentId = 'general',
    String provider = 'gemini',
    Map<String, dynamic>? context,
    String? token,
  }) async {
    try {
      final response = await httpClient.post(
        '/api/v1/ai/ask',
        data: {
          'prompt': prompt,
          if (sessionId != null) 'session_id': sessionId,
          'agent_id': agentId,
          'provider': provider,
          if (context != null) 'context': context,
        },
        options: Options(
          headers: {
            if (token != null) 'Authorization': 'Bearer $token',
          },
        ),
      );

      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['error'] ?? 'Error comunicándose con Maya',
      );
    }
  }

  @override
  Future<Map<String, dynamic>> iniciarMonitoreoVoz(String hiveId, String token) async {
    final url = '/api/v1/maya/iniciar-monitoreo';
    debugPrint("[Maya][DS] POST ${httpClient.options.baseUrl}$url");
    debugPrint("[Maya][DS] ${_maskAuthHeader(token)}");
    debugPrint("[Maya][DS] body -> {hive_id: $hiveId}");

    try {
      final response = await httpClient.post(
        url,
        data: {'hive_id': hiveId},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      debugPrint("[Maya][DS] status=${response.statusCode}");
      if (kDebugMode) {
        print("Response iniciar monitoreo: ${response.data}");
      }

      return response.data;
    } on DioException catch (e) {
      // Log detallado del error para diagnosticar el 401
      debugPrint("[Maya][DS] DioException type=${e.type}");
      debugPrint("[Maya][DS] status=${e.response?.statusCode}");
      debugPrint("[Maya][DS] response body=${e.response?.data}");
      debugPrint("[Maya][DS] request headers=${e.requestOptions.headers}");
      throw Exception(
        (e.response?.data is Map ? e.response?.data['error'] : null) ??
            'Error al iniciar monitoreo (status ${e.response?.statusCode})',
      );
    }
  }

  @override
  Future<void> guardarRespuestasVoz(String hiveId, List<Map<String, dynamic>> respuestas, String token) async {
    final url = '/api/v1/maya/guardar-respuestas';
    debugPrint("[Maya][DS] POST ${httpClient.options.baseUrl}$url");
    debugPrint("[Maya][DS] ${_maskAuthHeader(token)}");
    debugPrint("[Maya][DS] body -> {hive_id: $hiveId, answers: ${respuestas.length} items}");

    try {
      final response = await httpClient.post(
        url,
        data: {
          'hive_id': hiveId,
          'answers': respuestas, // EL BACKEND ESPERA 'answers'
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      debugPrint("[Maya][DS] guardar-respuestas status=${response.statusCode}");
    } on DioException catch (e) {
      debugPrint("[Maya][DS] guardar-respuestas DioException type=${e.type}");
      debugPrint("[Maya][DS] guardar-respuestas status=${e.response?.statusCode}");
      debugPrint("[Maya][DS] guardar-respuestas response body=${e.response?.data}");
      debugPrint("[Maya][DS] guardar-respuestas request headers=${e.requestOptions.headers}");
      throw Exception(
        (e.response?.data is Map ? e.response?.data['error'] : null) ??
            'Error al guardar respuestas (status ${e.response?.statusCode})',
      );
    }
  }
}
