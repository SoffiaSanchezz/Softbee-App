import 'package:dio/dio.dart';
import 'package:Softbee/core/error/failures.dart';
import 'package:Softbee/feature/auth/data/datasources/auth_local_datasource.dart';
import 'package:Softbee/feature/inventory/data/models/inventory_item.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:Softbee/core/network/dio_client.dart';
import 'package:Softbee/feature/auth/presentation/providers/auth_providers.dart'; // Import for authLocalDataSourceProvider

// Abstract class for Inventory Remote Data Source
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
  Future<void> recordInventoryExit({
    required String itemId,
    required int quantity,
    required String person,
  });
  Future<Map<String, dynamic>> getInventorySummary({required String apiaryId});
  Future<List<InventoryItem>> getLowStockItems({required String apiaryId});
}

// Implementation of Inventory Remote Data Source
class InventoryRemoteDataSourceImpl implements InventoryRemoteDataSource {
  final Dio _httpClient;
  final AuthLocalDataSource _localDataSource; // To get the authentication token

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
        '/apiaries/${item.apiaryId}/inventory',
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
        throw ServerFailure(
          'Failed to adjust quantity: ${response.statusCode}',
        );
      }
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
    try {
      final response = await _httpClient.get(
        '/apiaries/$apiaryId/inventory/search',
        queryParameters: {'query': query},
        options: await _getAuthHeaders(),
      );
      if (response.statusCode == 200) {
        final List<dynamic> jsonList = response.data;
        return jsonList.map((json) => InventoryItem.fromJson(json)).toList();
      } else {
        throw ServerFailure(
          'Failed to search inventory items: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      throw ServerFailure('Dio error: ${e.message}');
    } catch (e) {
      throw ServerFailure('Unknown error: ${e.toString()}');
    }
    // Backend doesn't have a search endpoint, we will filter locally in the controller
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
        '/api/v1/inventory/$itemId', // Note: backend get_inventories is by apiary_id, might need check
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
    try {
      // Assuming a separate endpoint for recording exit, if not, adjust quantity directly
      // For now, it adjusts quantity and doesn't explicitly send 'person' to the backend
      // as the original service didn't either.
      await adjustInventoryQuantity(itemId, -quantity);
    } on DioException catch (e) {
      throw ServerFailure('Dio error: ${e.message}');
    } catch (e) {
      throw ServerFailure('Unknown error: ${e.toString()}');
    }
    await adjustInventoryQuantity(itemId, -quantity);
  }

  @override
  Future<Map<String, dynamic>> getInventorySummary({
    required String apiaryId,
  }) async {
    try {
      final response = await _httpClient.get(
        '/apiaries/$apiaryId/inventory/summary',
        options: await _getAuthHeaders(),
      );
      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw ServerFailure(
          'Failed to get inventory summary: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      throw ServerFailure('Dio error: ${e.message}');
    } catch (e) {
      throw ServerFailure('Unknown error: ${e.toString()}');
    }
  }

  @override
  Future<List<InventoryItem>> getLowStockItems({required String apiaryId}) async {
    try {
      final response = await _httpClient.get(
        '/apiaries/$apiaryId/inventory/low-stock',
        options: await _getAuthHeaders(),
      );
      if (response.statusCode == 200) {
        final List<dynamic> jsonList = response.data;
        return jsonList.map((json) => InventoryItem.fromJson(json)).toList();
      } else {
        throw ServerFailure(
          'Failed to get low stock items: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      throw ServerFailure('Dio error: ${e.message}');
    } catch (e) {
      throw ServerFailure('Unknown error: ${e.toString()}');
    }
    // Backend summary is global per user (/api/v1/inventory/summary/<user_id>)
    // For specific apiary summary, we can calculate it from the items list to avoid 404
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
    // Filter locally to avoid 404
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
