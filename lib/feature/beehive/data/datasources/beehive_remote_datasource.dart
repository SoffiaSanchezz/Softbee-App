import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:Softbee/feature/auth/data/datasources/auth_local_datasource.dart';
import 'package:Softbee/feature/beehive/domain/entities/beehive.dart';

abstract class BeehiveRemoteDataSource {
  Future<List<Beehive>> getBeehivesByApiary(String apiaryId, String token);
  Future<Beehive> createBeehive(
    String apiaryId,
    int beehiveNumber,
    String? activityLevel,
    String? beePopulation,
    int? foodFrames,
    int? broodFrames,
    String? hiveStatus,
    String? healthStatus,
    String? hasProductionChamber,
    String? observations,
    bool treatments,
    String token,
  );
  Future<Beehive> updateBeehive(
    String beehiveId,
    String apiaryId,
    int? beehiveNumber,
    String? activityLevel,
    String? beePopulation,
    int? foodFrames,
    int? broodFrames,
    String? hiveStatus,
    String? healthStatus,
    String? hasProductionChamber,
    String? observations,
    bool? treatments,
    String token,
  );
  Future<void> deleteBeehive(String beehiveId, String apiaryId, String token);
}

class BeehiveRemoteDataSourceImpl implements BeehiveRemoteDataSource {
  final Dio httpClient;
  final AuthLocalDataSource localDataSource;

  BeehiveRemoteDataSourceImpl(this.httpClient, this.localDataSource);

  @override
  Future<List<Beehive>> getBeehivesByApiary(
    String apiaryId,
    String token,
  ) async {
    try {
      final response = await httpClient.get(
        '/api/v1/beehives/apiary/$apiaryId',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        final List<dynamic> beehivesJson = response.data is String
            ? json.decode(response.data) as List<dynamic>
            : response.data as List<dynamic>;
        return beehivesJson
            .map((item) => Beehive.fromJson(item as Map<String, dynamic>))
            .toList();
      } else {
        final data = response.data is String
            ? json.decode(response.data)
            : response.data;
        throw Exception(
          data['message'] ?? 'Error al obtener colmenas',
        );
      }
    } on DioException catch (e) {
      if (e.response != null) {
        final errData = e.response!.data is String
            ? json.decode(e.response!.data)
            : e.response!.data;
        throw Exception(
          errData['message'] ??
              'Error de red: ${e.response!.statusCode}',
        );
      } else {
        throw Exception('Error de conexión: ${e.message}');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Error inesperado: $e');
    }
  }

  @override
  Future<Beehive> createBeehive(
    String apiaryId,
    int beehiveNumber,
    String? activityLevel,
    String? beePopulation,
    int? foodFrames,
    int? broodFrames,
    String? hiveStatus,
    String? healthStatus,
    String? hasProductionChamber,
    String? observations,
    bool treatments,
    String token,
  ) async {
    try {
      final response = await httpClient.post(
        '/api/v1/beehives',
        data: {
          'apiary_id': apiaryId,
          'hive_number': beehiveNumber,
          'activity_level': activityLevel,
          'bee_population': beePopulation,
          'food_frames': foodFrames,
          'brood_frames': broodFrames,
          'hive_status': hiveStatus,
          'health_status': healthStatus,
          'has_production_chamber': hasProductionChamber,
          'observations': observations,
          'treatments': treatments,
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 201) {
        final Map<String, dynamic> data = response.data is String
            ? json.decode(response.data) as Map<String, dynamic>
            : response.data as Map<String, dynamic>;
        return Beehive.fromJson(data);
      } else {
        final data = response.data is String
            ? json.decode(response.data)
            : response.data;
        throw Exception(
          data['message'] ?? 'Error al crear la colmena',
        );
      }
    } on DioException catch (e) {
      if (e.response != null) {
        final errData = e.response!.data is String
            ? json.decode(e.response!.data)
            : e.response!.data;
        throw Exception(
          errData['message'] ??
              'Error de red: ${e.response!.statusCode}',
        );
      } else {
        throw Exception('Error de conexión: ${e.message}');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Error inesperado: $e');
    }
  }

  @override
  Future<Beehive> updateBeehive(
    String beehiveId,
    String apiaryId,
    int? beehiveNumber,
    String? activityLevel,
    String? beePopulation,
    int? foodFrames,
    int? broodFrames,
    String? hiveStatus,
    String? healthStatus,
    String? hasProductionChamber,
    String? observations,
    bool? treatments,
    String token,
  ) async {
    try {
      final response = await httpClient.put(
        '/api/v1/beehives/$beehiveId',
        data: {
          'apiary_id': apiaryId,
          if (beehiveNumber != null) 'hive_number': beehiveNumber,
          if (activityLevel != null) 'activity_level': activityLevel,
          if (beePopulation != null) 'bee_population': beePopulation,
          if (foodFrames != null) 'food_frames': foodFrames,
          if (broodFrames != null) 'brood_frames': broodFrames,
          if (hiveStatus != null) 'hive_status': hiveStatus,
          if (healthStatus != null) 'health_status': healthStatus,
          if (hasProductionChamber != null)
            'has_production_chamber': hasProductionChamber,
          if (observations != null) 'observations': observations,
          if (treatments != null) 'treatments': treatments,
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = response.data is String
            ? json.decode(response.data) as Map<String, dynamic>
            : response.data as Map<String, dynamic>;
        return Beehive.fromJson(data);
      } else {
        final data = response.data is String
            ? json.decode(response.data)
            : response.data;
        throw Exception(
          data['message'] ?? 'Error al actualizar la colmena',
        );
      }
    } on DioException catch (e) {
      if (e.response != null) {
        final errData = e.response!.data is String
            ? json.decode(e.response!.data)
            : e.response!.data;
        throw Exception(
          errData['message'] ??
              'Error de red: ${e.response!.statusCode}',
        );
      } else {
        throw Exception('Error de conexión: ${e.message}');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Error inesperado: $e');
    }
  }

  @override
  Future<void> deleteBeehive(
    String beehiveId,
    String apiaryId,
    String token,
  ) async {
    try {
      final response = await httpClient.delete(
        '/api/v1/beehives/$beehiveId',
        data: {'apiary_id': apiaryId},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode != 204) {
        final data = response.data is String
            ? json.decode(response.data)
            : response.data;
        throw Exception(
          data['message'] ?? 'Error al eliminar la colmena',
        );
      }
    } on DioException catch (e) {
      if (e.response != null) {
        final errData = e.response!.data is String
            ? json.decode(e.response!.data)
            : e.response!.data;
        throw Exception(
          errData['message'] ??
              'Error de red: ${e.response!.statusCode}',
        );
      } else {
        throw Exception('Error de conexión: ${e.message}');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Error inesperado: $e');
    }
  }
}
