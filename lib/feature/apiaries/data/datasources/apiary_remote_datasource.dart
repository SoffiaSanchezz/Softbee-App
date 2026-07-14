import 'package:Softbee/feature/apiaries/domain/entities/apiary.dart';
import 'package:Softbee/feature/auth/data/datasources/auth_local_datasource.dart';
import 'package:dio/dio.dart';

abstract class ApiaryRemoteDataSource {
  Future<List<Apiary>> getApiaries(String token);
  Future<Apiary> createApiary(
    String token,
    String userId,
    String name,
    String? location,
    int? beehivesCount,
  );
  Future<Apiary> updateApiary(
    String token,
    String apiaryId,
    String userId,
    String? name,
    String? location,
    int? beehivesCount,
  );
  Future<void> deleteApiary(String token, String apiaryId, String userId);
}

class ApiaryRemoteDataSourceImpl implements ApiaryRemoteDataSource {
  final Dio httpClient;
  final AuthLocalDataSource localDataSource;

  ApiaryRemoteDataSourceImpl(this.httpClient, this.localDataSource);

  @override
  Future<List<Apiary>> getApiaries(String token) async {
    try {
      final response = await httpClient.get(
        '/api/v1/apiaries',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        final List<dynamic> apiariesJson = response.data;
        return apiariesJson.map((json) => Apiary.fromJson(json)).toList();
      } else {
        throw Exception(
          response.data['message'] ?? 'Error al obtener apiarios',
        );
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(
          e.response!.data['message'] ??
              'Error de red: ${e.response!.statusCode}',
        );
      } else {
        throw Exception('Error de conexión: ${e.message}');
      }
    } catch (e) {
      throw Exception('Error inesperado: $e');
    }
  }

  @override
  Future<Apiary> createApiary(
    String token,
    String userId,
    String name,
    String? location,
    int? beehivesCount,
  ) async {
    try {
      final response = await httpClient.post(
        '/api/v1/apiaries',
        data: {
          'user_id': userId,
          'name': name,
          'location': location,
          'beehives_count': beehivesCount,
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 201) {
        return Apiary.fromJson(response.data);
      } else {
        throw Exception(response.data['message'] ?? 'Error al crear apiario');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(
          e.response!.data['message'] ??
              'Error de red: ${e.response!.statusCode}',
        );
      } else {
        throw Exception('Error de conexión: ${e.message}');
      }
    } catch (e) {
      throw Exception('Error inesperado: $e');
    }
  }

  @override
  Future<Apiary> updateApiary(
    String token,
    String apiaryId,
    String userId,
    String? name,
    String? location,
    int? beehivesCount,
  ) async {
    try {
      final response = await httpClient.put(
        '/api/v1/apiaries/$apiaryId',
        data: {
          'user_id': userId, // Ensure user_id is sent for authorization
          if (name != null) 'name': name,
          if (location != null) 'location': location,
          if (beehivesCount != null) 'beehives_count': beehivesCount,
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        return Apiary.fromJson(response.data);
      } else {
        throw Exception(
          response.data['message'] ?? 'Error al actualizar apiario',
        );
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(
          e.response!.data['message'] ??
              'Error de red: ${e.response!.statusCode}',
        );
      } else {
        throw Exception('Error de conexión: ${e.message}');
      }
    } catch (e) {
      throw Exception('Error inesperado: $e');
    }
  }

  @override
  Future<void> deleteApiary(
    String token,
    String apiaryId,
    String userId,
  ) async {
    try {
      final response = await httpClient.delete(
        '/api/v1/apiaries/$apiaryId',
        data: {'user_id': userId}, // Send user_id in body for authorization
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode != 204) {
        throw Exception(
          response.data['message'] ?? 'Error al eliminar apiario',
        );
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(
          e.response!.data['message'] ??
              'Error de red: ${e.response!.statusCode}',
        );
      } else {
        throw Exception('Error de conexión: ${e.message}');
      }
    } catch (e) {
      throw Exception('Error inesperado: $e');
    }
  }
}
