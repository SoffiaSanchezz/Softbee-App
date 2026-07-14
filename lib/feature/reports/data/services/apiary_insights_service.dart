import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/data/datasources/auth_local_datasource.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

class ApiaryInsightsService {
  final Dio _dio;
  final AuthLocalDataSource _localDataSource;

  ApiaryInsightsService(this._dio, this._localDataSource);

  Future<Options> _getOptions() async {
    final token = await _localDataSource.getToken();
    return Options(headers: {'Authorization': 'Bearer $token'});
  }

  // 1. Estadísticas Generales
  Future<Map<String, dynamic>> getGeneralStats(String apiaryId) async {
    final response = await _dio.get('/api/v1/statistics/apiary/$apiaryId', options: await _getOptions());
    return response.data;
  }

  // 2. Tendencias de Salud por Colmena
  Future<List<dynamic>> getHealthTrends(String apiaryId) async {
    final response = await _dio.get('/api/v1/statistics/apiary/$apiaryId/health-trends', options: await _getOptions());
    return response.data;
  }

  // 3. Distribución de Tratamientos (Pie Chart)
  Future<List<dynamic>> getTreatmentDistribution(String apiaryId) async {
    final response = await _dio.get('/api/v1/statistics/apiary/$apiaryId/treatment-distribution', options: await _getOptions());
    return response.data;
  }

  // 4. Niveles de Inventario (Bar Chart)
  Future<List<dynamic>> getInventoryLevels(String apiaryId) async {
    final response = await _dio.get('/api/v1/statistics/apiary/$apiaryId/inventory-levels', options: await _getOptions());
    return response.data;
  }

  // 5. Análisis de IA Maya
  Future<Map<String, dynamic>> analyzeWithMaya({
    required String apiaryId,
    required Map<String, dynamic> contextData,
  }) async {
    final response = await _dio.post(
      '/api/v1/ai/ask',
      data: {
        'prompt': "Actúa como un experto apicultor. Analiza estos datos: $contextData. Dame un resumen ejecutivo del estado del apiario y 3 acciones prioritarias.",
        'agent_id': 'experto_apiarios',
        'provider': 'gemini',
        'context': {'apiary_id': apiaryId}
      },
      options: await _getOptions(),
    );
    
    final content = response.data['data']['response'] as String;
    String status = 'regular';
    if (content.toLowerCase().contains('saludable') || content.toLowerCase().contains('excelente')) status = 'saludable';
    if (content.toLowerCase().contains('alerta') || content.toLowerCase().contains('urgente') || content.toLowerCase().contains('tratamiento')) status = 'alerta';

    return {'status': status, 'response': content};
  }
}

final apiaryInsightsServiceProvider = Provider((ref) => ApiaryInsightsService(
  ref.read(dioClientProvider),
  ref.read(authLocalDataSourceProvider),
));
