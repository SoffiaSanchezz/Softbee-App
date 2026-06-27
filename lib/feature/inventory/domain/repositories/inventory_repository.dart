import 'package:either_dart/either.dart';
import 'package:Softbee/core/error/failures.dart';
import 'package:Softbee/feature/inventory/data/models/inventory_item.dart';

abstract class InventoryRepository {
  Future<Either<Failure, List<InventoryItem>>> getInventoryItems({
    required String apiaryId,
  });
  Future<Either<Failure, InventoryItem>> createInventoryItem(
    InventoryItem item,
  );
  Future<Either<Failure, void>> updateInventoryItem(InventoryItem item);
  Future<Either<Failure, void>> deleteInventoryItem(String itemId);
  Future<Either<Failure, void>> adjustInventoryQuantity(
    String itemId,
    int amount,
  );
  Future<Either<Failure, List<InventoryItem>>> searchInventoryItems(
    String query, {
    required String apiaryId,
  });
  Future<Either<Failure, InventoryItem?>> getInventoryItem(String itemId);
  Future<Either<Failure, void>> recordInventoryExit({
    required String itemId,
    required int quantity,
    required String person,
  });
  Future<Either<Failure, Map<String, dynamic>>> getInventorySummary({
    required String apiaryId,
  });
  Future<Either<Failure, List<InventoryItem>>> getLowStockItems({
    required String apiaryId,
  });
}
