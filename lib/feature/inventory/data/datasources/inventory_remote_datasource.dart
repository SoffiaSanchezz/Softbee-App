import 'package:dio/dio.dart';
import 'package:Softbee/core/error/failures.dart';
import 'package:Softbee/feature/auth/data/datasources/auth_local_datasource.dart';
import 'package:Softbee/feature/inventory/data/models/inventory_item.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:Softbee/core/network/dio_client.dart';
import 'package:Softbee/feature/auth/presentation/providers/auth_providers.dart';

abstract class InventoryRemoteDataSource {
  Future<List<InventoryItem>> getInventoryItems({required String apiaryId});
  Future<InventoryItem> createInventoryItem(InventoryItem item);
  Future<void> updateInventoryItem(InventoryItem item);
  Future<void> deleteInventoryItem(String itemId);
  Future<void> adjustInventoryQuantity(String itemId, int amount);
  Future<List<InventoryItem>> searchInventoryItems(
    String query, {
    required String apiaryId,
  });
  Future<InventoryItem?> getInventoryItem(String itemId);
  Future<void> recordMovement({
    required String itemId,
    required String type,
    required int quantity,
    required String reason,
    String? notes,
  });
  Future<List<Map<String, dynamic>>> getMovements(String itemId);
  Future<void> recordInventoryExit({
    required String itemId,
    required int quantity,
    required String person,
  });
  Future<Map<String, dynamic>> getInventorySummary({required String apiaryId});
  Future<List<InventoryItem>> getLowStockItems({required String apiaryId});
}

class InventoryRemoteDataSourceImpl implements InventoryRemoteDataSource {
  final Dio _httpClient;
  final AuthLocalDataSource _localDataSource;

  InventoryRemoteDataSourceImpl(this._httpClient, this._localDataSource);

  Future<Options> _getAuthHeaders() async {
    final token = await _localDataSource.getToken();
    if (token == null) {
      throw const AuthFailure('No authentication token found.');
    }
    return Options(headers: {'Authorization': 'Bearer $token'});
  }

  @override
  Future<List<InventoryItem>> getInventoryItems({
    required String apiaryId,
  }) async {
    try {
      final response = await _httpClient.get(
        '/api/v1/inventory/$apiaryId',
        options: await _getAuthHeaders(),
      );
      if (response.statusCode == 200) {
        final List<dynamic> jsonList = response.data;
        return jsonList.map((json) => InventoryItem.fromJson(json)).toList();
      } else {
        throw ServerFailure(
          'Failed to get inventory items: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      throw ServerFailure('Dio error: ${e.message}');
    } catch (e) {
      throw ServerFailure('Unknown error: ${e.toString()}');
    }
  }

  @override
  Future<InventoryItem> createInventoryItem(InventoryItem item) async {
    try {
      final response = await _httpClient.post(
        '/api/v1/inventory/',
        data: item.toCreateJson(),
        options: await _getAuthHeaders(),
      );
      if (response.statusCode == 201) {
        return InventoryItem.fromJson(response.data);
      } else {
        throw ServerFailure('Failed to create item: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw ServerFailure('Dio error: ${e.message}');
    } catch (e) {
      throw ServerFailure('Unknown error: ${e.toString()}');
    }
  }

  @override
  Future<void> updateInventoryItem(InventoryItem item) async {
    try {
      final response = await _httpClient.put(
        '/api/v1/inventory/${item.id}',
        data: item.toUpdateJson(),
        options: await _getAuthHeaders(),
      );
      if (response.statusCode != 200) {
        throw ServerFailure('Failed to update item: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw ServerFailure('Dio error: ${e.message}');
    } catch (e) {
      throw ServerFailure('Unknown error: ${e.toString()}');
    }
  }

  @override
  Future<void> deleteInventoryItem(String itemId) async {
    try {
      final response = await _httpClient.delete(
        '/api/v1/inventory/$itemId',
        options: await _getAuthHeaders(),
      );
      if (response.statusCode != 200 && response.statusCode != 204) {
        throw ServerFailure('Failed to delete item: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw ServerFailure('Dio error: ${e.message}');
    } catch (e) {
      throw ServerFailure('Unknown error: ${e.toString()}');
    }
  }

  @override
  Future<void> adjustInventoryQuantity(String itemId, int amount) async {
    try {
      final response = await _httpClient.put(
        '/api/v1/inventory/$itemId/adjust',
        data: {'adjustment_amount': amount},
        options: await _getAuthHeaders(),
      );
      if (response.statusCode != 200) {
        throw ServerFailure('Failed to adjust quantity');
      }
    } on DioException catch (e) {
      throw ServerFailure('Dio error: ${e.message}');
    } catch (e) {
      throw ServerFailure('Unknown error: ${e.toString()}');
    }
  }

  @override
  Future<void> recordMovement({
    required String itemId,
    required String type,
    required int quantity,
    required String reason,
    String? notes,
  }) async {
    try {
      final response = await _httpClient.post(
        '/api/v1/inventory/movement',
        data: {
          'inventory_id': itemId,
          'movement_type': type,
          'quantity': quantity,
          'reason': reason,
          'notes': notes,
        },
        options: await _getAuthHeaders(),
      );
      if (response.statusCode != 201) {
        throw ServerFailure('No se pudo registrar el movimiento');
      }
    } on DioException catch (e) {
      // Extraemos el mensaje específico enviado por el Backend
      final backendMessage = e.response?.data?['message']?.toString();
      throw ServerFailure(backendMessage ?? 'Error en el servidor: ${e.message}');
    } catch (e) {
      throw ServerFailure('Error desconocido: ${e.toString()}');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getMovements(String itemId) async {
    try {
      final response = await _httpClient.get(
        '/api/v1/inventory/$itemId/movements',
        options: await _getAuthHeaders(),
      );
      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(response.data);
      }
      return [];
    } on DioException catch (e) {
      throw ServerFailure('Dio error: ${e.message}');
    } catch (e) {
      throw ServerFailure('Unknown error: ${e.toString()}');
    }
  }

  @override
  Future<List<InventoryItem>> searchInventoryItems(
    String query, {
    required String apiaryId,
  }) async {
    final allItems = await getInventoryItems(apiaryId: apiaryId);
    return allItems
        .where(
          (item) => item.itemName.toLowerCase().contains(query.toLowerCase()),
        )
        .toList();
  }

  @override
  Future<InventoryItem?> getInventoryItem(String itemId) async {
    try {
      final response = await _httpClient.get(
        '/api/v1/inventory/$itemId',
        options: await _getAuthHeaders(),
      );
      if (response.statusCode == 200) {
        return InventoryItem.fromJson(response.data);
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw ServerFailure(
          'Failed to get inventory item: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      throw ServerFailure('Dio error: ${e.message}');
    } catch (e) {
      throw ServerFailure('Unknown error: ${e.toString()}');
    }
  }

  @override
  Future<void> recordInventoryExit({
    required String itemId,
    required int quantity,
    required String person,
  }) async {
    await recordMovement(
      itemId: itemId,
      type: 'exit',
      quantity: quantity,
      reason: 'Salida registrada por $person',
    );
    await adjustInventoryQuantity(itemId, -quantity);
  }

  @override
  Future<Map<String, dynamic>> getInventorySummary({
    required String apiaryId,
  }) async {
    final items = await getInventoryItems(apiaryId: apiaryId);
    int totalQuantity = 0;
    int lowStockCount = 0;
    for (var item in items) {
      totalQuantity += item.quantity;
      if (item.quantity <= item.minimumStock) lowStockCount++;
    }

    return {
      'total_items': items.length,
      'total_quantity': totalQuantity,
      'low_stock_items': lowStockCount,
      'in_stock_items': items.where((i) => i.quantity > 0).length,
      'out_of_stock_items': items.where((i) => i.quantity <= 0).length,
    };
  }

  @override
  Future<List<InventoryItem>> getLowStockItems({
    required String apiaryId,
  }) async {
    final allItems = await getInventoryItems(apiaryId: apiaryId);
    return allItems
        .where((item) => item.quantity <= item.minimumStock)
        .toList();
  }
}

final inventoryRemoteDataSourceProvider = Provider<InventoryRemoteDataSource>((
  ref,
) {
  final dio = ref.read(dioClientProvider);
  final authLocalDataSource = ref.read(authLocalDataSourceProvider);
  return InventoryRemoteDataSourceImpl(dio, authLocalDataSource);
});
