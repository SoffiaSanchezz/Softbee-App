import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:Softbee/core/error/failures.dart';
import 'package:Softbee/feature/inventory/data/models/inventory_item.dart';
import 'package:Softbee/feature/inventory/domain/repositories/inventory_repository.dart';
import 'package:Softbee/feature/inventory/presentation/providers/inventory_state.dart';
import 'package:Softbee/feature/inventory/presentation/providers/inventory_providers.dart'; // Import for inventoryRepositoryProvider

class InventoryController extends StateNotifier<InventoryState> {
  final InventoryRepository _repository;

  InventoryController(this._repository) : super(const InventoryState());

  Future<void> loadInventoryItems({required String apiaryId}) async {
    print('loadInventoryItems called for apiaryId: $apiaryId');
    state = state.copyWith(isLoading: true, errorMessage: null);
    final result = await _repository.getInventoryItems(apiaryId: apiaryId);

    result.fold(
      (failure) => state = state.copyWith(
        errorMessage: _mapFailureToMessage(failure),
        isLoading: false,
      ),
      (items) {
        // Calculate summary and low stock locally to avoid 404s from non-existent endpoints
        int totalQuantity = 0;
        final lowStockItems = <InventoryItem>[];

        for (var item in items) {
          totalQuantity += item.quantity;
          if (item.quantity < 4) {
            lowStockItems.add(item);
          }
        }

        final summary = {
          'total_items': items.length,
          'total_quantity': totalQuantity,
          'low_stock_items': lowStockItems.length,
          'in_stock_items': items.where((i) => i.quantity > 0).length,
          'out_of_stock_items': items.where((i) => i.quantity <= 0).length,
          'updated_at': DateTime.now().toIso8601String(),
        };

        state = state.copyWith(
          inventoryItems: items,
          inventorySummary: summary,
          lowStockItems: lowStockItems,
          isLoading: false,
          errorMessage: null,
        );
      },
    );
  }

  Future<String?> guardarInsumo(
    InventoryItem item, {
    required String apiaryId, // Changed to String
  }) async {
    // Determine if it's an update or create operation
    if (item.id.isNotEmpty) {
      // Update existing item
      final result = await _repository.updateInventoryItem(item);
      return result.fold((failure) => _mapFailureToMessage(failure), (_) async {
        await loadInventoryItems(apiaryId: apiaryId); // Await the reload
        return null;
      });
    } else {
      // Create new item
      final newItem = item.copyWith(
        apiaryId: apiaryId,
      ); // Ensure apiaryId is set for new items
      final result = await _repository.createInventoryItem(newItem);
      return result.fold((failure) => _mapFailureToMessage(failure), (_) {
        loadInventoryItems(
          apiaryId: apiaryId,
        ); // Reload inventory after creation
        return null;
      });
    }
  }

  Future<String?> eliminarInsumo(
    String itemId, {
    required String apiaryId,
  }) async {
    // Changed to String
    final result = await _repository.deleteInventoryItem(itemId);
    return result.fold((failure) => _mapFailureToMessage(failure), (_) {
      loadInventoryItems(apiaryId: apiaryId); // Reload inventory after deletion
      return null;
    });
  }

  Future<String?> registrarMovimiento({
    required String itemId,
    required String type,
    required int quantity,
    required String reason,
    String? notes,
    required String apiaryId,
  }) async {
    final result = await _repository.recordMovement(
      itemId: itemId,
      type: type,
      quantity: quantity,
      reason: reason,
      notes: notes,
    );
    return result.fold(
      (failure) => _mapFailureToMessage(failure),
      (_) async {
        await loadInventoryItems(apiaryId: apiaryId);
        return null;
      },
    );
  }

  Future<List<Map<String, dynamic>>> obtenerHistorial(String itemId) async {
    final result = await _repository.getMovements(itemId);
    return result.fold(
      (failure) => [],
      (movements) => movements,
    );
  }

  void setEditingItem(InventoryItem? item) {
    state = state.copyWith(isEditing: item != null, editingItem: item);
  }

  String _mapFailureToMessage(Failure failure) {
    if (failure is ServerFailure) {
      return failure.message;
    } else if (failure is CacheFailure) {
      return 'Cache error: ${failure.message}';
    } else if (failure is AuthFailure) {
      return 'Authentication error: ${failure.message}';
    }
    return 'Unexpected Error';
  }
}

// Update inventory_providers.dart with this provider
final inventoryControllerProvider =
    StateNotifierProvider.family<InventoryController, InventoryState, String>((
      // Changed to String
      ref,
      apiaryId,
    ) {
      final repository = ref.read(inventoryRepositoryProvider);
      final controller = InventoryController(repository);
      controller.loadInventoryItems(
        apiaryId: apiaryId,
      ); // Load items immediately
      return controller;
    });
