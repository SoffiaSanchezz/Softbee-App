import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

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
    try {
      final response = await httpClient.post(
        '/api/v1/maya/iniciar-monitoreo',
        data: {'hive_id': hiveId},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      
      // LOG SOLICITADO
      if (kDebugMode) {
        print("Response iniciar monitoreo: ${response.data}");
      }
      
      return response.data;
    } on DioException catch (e) {
      throw Exception(e.response?.data['error'] ?? 'Error al iniciar monitoreo');
    }
  }

  @override
  Future<void> guardarRespuestasVoz(String hiveId, List<Map<String, dynamic>> respuestas, String token) async {
    try {
      await httpClient.post(
        '/api/v1/maya/guardar-respuestas',
        data: {
          'hive_id': hiveId,
          'answers': respuestas, // EL BACKEND ESPERA 'answers'
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
    } on DioException catch (e) {
      throw Exception(e.response?.data['error'] ?? 'Error al guardar respuestas');
    }
  }
}
