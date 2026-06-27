import 'package:either_dart/either.dart';
import 'package:Softbee/core/error/failures.dart';
import 'package:Softbee/feature/inventory/data/datasources/inventory_remote_datasource.dart';
import 'package:Softbee/feature/inventory/data/models/inventory_item.dart';
import 'package:Softbee/feature/inventory/domain/repositories/inventory_repository.dart';
import 'package:Softbee/feature/auth/data/datasources/auth_local_datasource.dart'; // Import to get token

class InventoryRepositoryImpl implements InventoryRepository {
  final InventoryRemoteDataSource remoteDataSource;
  final AuthLocalDataSource localDataSource; // To get the authentication token

  InventoryRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  // The token retrieval is now handled by the remoteDataSource internally,
  // so the repository methods no longer need to retrieve and pass the token.

  @override
  Future<Either<Failure, List<InventoryItem>>> getInventoryItems({
    required String apiaryId,
  }) async {
    try {
      final result = await remoteDataSource.getInventoryItems(
        apiaryId: apiaryId,
      );
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, InventoryItem>> createInventoryItem(
    InventoryItem item,
  ) async {
    try {
      final result = await remoteDataSource.createInventoryItem(item);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateInventoryItem(InventoryItem item) async {
    try {
      await remoteDataSource.updateInventoryItem(item);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteInventoryItem(String itemId) async {
    try {
      await remoteDataSource.deleteInventoryItem(itemId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> adjustInventoryQuantity(
    String itemId,
    int amount,
  ) async {
    try {
      await remoteDataSource.adjustInventoryQuantity(itemId, amount);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<InventoryItem>>> searchInventoryItems(
    String query, {
    required String apiaryId,
  }) async {
    try {
      final result = await remoteDataSource.searchInventoryItems(
        query,
        apiaryId: apiaryId,
      );
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, InventoryItem?>> getInventoryItem(
    String itemId,
  ) async {
    try {
      final result = await remoteDataSource.getInventoryItem(itemId);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> recordInventoryExit({
    required String itemId,
    required int quantity,
    required String person,
  }) async {
    try {
      await remoteDataSource.recordInventoryExit(
        itemId: itemId,
        quantity: quantity,
        person: person,
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getInventorySummary({
    required String apiaryId,
  }) async {
    try {
      final result = await remoteDataSource.getInventorySummary(
        apiaryId: apiaryId,
      );
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<InventoryItem>>> getLowStockItems({
    required String apiaryId,
  }) async {
    try {
      final result = await remoteDataSource.getLowStockItems(
        apiaryId: apiaryId,
      );
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
