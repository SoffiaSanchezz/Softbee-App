import 'package:either_dart/either.dart';
import 'package:Softbee/core/error/failures.dart';
import 'package:Softbee/core/network/network_info.dart';
import 'package:Softbee/feature/inventory/data/datasources/inventory_local_datasource.dart';
import 'package:Softbee/feature/inventory/data/datasources/inventory_remote_datasource.dart';
import 'package:Softbee/feature/inventory/data/models/inventory_item.dart';
import 'package:Softbee/feature/inventory/domain/repositories/inventory_repository.dart';
import 'package:Softbee/feature/auth/data/datasources/auth_local_datasource.dart';

class InventoryRepositoryImpl implements InventoryRepository {
  final InventoryRemoteDataSource remoteDataSource;
  final AuthLocalDataSource localDataSource;
  final InventoryLocalDataSource inventoryLocalDataSource;
  final NetworkInfo networkInfo;

  InventoryRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.inventoryLocalDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<InventoryItem>>> getInventoryItems({
    required String apiaryId,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.getInventoryItems(apiaryId: apiaryId);

        // Cachear en local
        await inventoryLocalDataSource.cacheInventoryItems(apiaryId, result);

        return Right(result);
      } catch (e) {
        // Fallback a datos locales si falla el servidor
        try {
          final localItems = await inventoryLocalDataSource.getCachedInventoryItems(apiaryId);
          if (localItems.isNotEmpty) {
            return Right(localItems);
          }
        } catch (_) {}
        return Left(ServerFailure(e.toString()));
      }
    } else {
      // MODO OFFLINE
      try {
        final localItems = await inventoryLocalDataSource.getCachedInventoryItems(apiaryId);
        return Right(localItems);
      } catch (e) {
        return Left(CacheFailure("No hay datos de inventario disponibles offline"));
      }
    }
  }

  @override
  Future<Either<Failure, InventoryItem>> createInventoryItem(
    InventoryItem item,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.createInventoryItem(item);

        // Guardar en cache local
        await inventoryLocalDataSource.saveItem(item.apiaryId, result);

        return Right(result);
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    } else {
      // OFFLINE: guardar localmente con ID temporal
      try {
        final tempItem = item.copyWith(
          id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await inventoryLocalDataSource.saveItem(item.apiaryId, tempItem);
        return Right(tempItem);
      } catch (e) {
        return Left(CacheFailure('Error al guardar item localmente: ${e.toString()}'));
      }
    }
  }

  @override
  Future<Either<Failure, void>> updateInventoryItem(InventoryItem item) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.updateInventoryItem(item);

        // Actualizar cache local
        await inventoryLocalDataSource.updateLocalItem(item.apiaryId, item);

        return const Right(null);
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    } else {
      // OFFLINE: actualizar localmente
      try {
        final updated = item.copyWith(updatedAt: DateTime.now());
        await inventoryLocalDataSource.updateLocalItem(item.apiaryId, updated);
        return const Right(null);
      } catch (e) {
        return Left(CacheFailure('Error al actualizar item localmente: ${e.toString()}'));
      }
    }
  }

  @override
  Future<Either<Failure, void>> deleteInventoryItem(String itemId) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.deleteInventoryItem(itemId);
        return const Right(null);
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    } else {
      return Left(CacheFailure('No se puede eliminar sin conexión'));
    }
  }

  @override
  Future<Either<Failure, void>> adjustInventoryQuantity(
    String itemId,
    int amount,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.adjustInventoryQuantity(itemId, amount);
        return const Right(null);
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    } else {
      return Left(CacheFailure('No se puede ajustar cantidad sin conexión'));
    }
  }

  @override
  Future<Either<Failure, List<InventoryItem>>> searchInventoryItems(
    String query, {
    required String apiaryId,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.searchInventoryItems(query, apiaryId: apiaryId);
        return Right(result);
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    } else {
      // OFFLINE: buscar en cache local
      try {
        final localItems = await inventoryLocalDataSource.getCachedInventoryItems(apiaryId);
        final filtered = localItems.where((item) {
          final lowerQuery = query.toLowerCase();
          return item.itemName.toLowerCase().contains(lowerQuery) ||
              item.category.toLowerCase().contains(lowerQuery) ||
              (item.description?.toLowerCase().contains(lowerQuery) ?? false);
        }).toList();
        return Right(filtered);
      } catch (e) {
        return Left(CacheFailure("No hay datos de inventario disponibles offline"));
      }
    }
  }

  @override
  Future<Either<Failure, InventoryItem?>> getInventoryItem(
    String itemId,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.getInventoryItem(itemId);
        return Right(result);
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    } else {
      return Left(CacheFailure('No se puede obtener detalle sin conexión'));
    }
  }

  @override
  Future<Either<Failure, void>> recordMovement({
    required String itemId,
    required String type,
    required int quantity,
    required String reason,
    String? notes,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.recordMovement(
          itemId: itemId,
          type: type,
          quantity: quantity,
          reason: reason,
          notes: notes,
        );
        return const Right(null);
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    } else {
      return Left(CacheFailure('No se puede registrar movimiento sin conexión'));
    }
  }

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> getMovements(String itemId) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.getMovements(itemId);
        return Right(result);
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    } else {
      return Left(CacheFailure('No hay movimientos disponibles offline'));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getInventorySummary({
    required String apiaryId,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.getInventorySummary(apiaryId: apiaryId);
        return Right(result);
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    } else {
      // OFFLINE: generar resumen desde cache
      try {
        final localItems = await inventoryLocalDataSource.getCachedInventoryItems(apiaryId);
        final summary = {
          'total_items': localItems.length,
          'low_stock_count': localItems.where((i) => i.isLowStock).length,
          'expired_count': localItems.where((i) => i.isExpired).length,
          'offline': true,
        };
        return Right(summary);
      } catch (e) {
        return Left(CacheFailure("No hay datos de inventario disponibles offline"));
      }
    }
  }

  @override
  Future<Either<Failure, List<InventoryItem>>> getLowStockItems({
    required String apiaryId,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.getLowStockItems(apiaryId: apiaryId);
        return Right(result);
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    } else {
      // OFFLINE: filtrar desde cache local
      try {
        final localItems = await inventoryLocalDataSource.getCachedInventoryItems(apiaryId);
        final lowStock = localItems.where((i) => i.isLowStock).toList();
        return Right(lowStock);
      } catch (e) {
        return Left(CacheFailure("No hay datos de inventario disponibles offline"));
      }
    }
  }
}
