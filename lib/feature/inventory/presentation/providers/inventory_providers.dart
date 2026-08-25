import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:Softbee/feature/inventory/data/datasources/inventory_local_datasource.dart';
import 'package:Softbee/feature/inventory/data/datasources/inventory_remote_datasource.dart';
import 'package:Softbee/feature/inventory/data/repositories/inventory_repository_impl.dart';
import 'package:Softbee/feature/inventory/domain/repositories/inventory_repository.dart';
import 'package:Softbee/feature/inventory/presentation/providers/inventory_controller.dart';
import 'package:Softbee/feature/inventory/presentation/providers/inventory_state.dart';
import 'package:Softbee/feature/auth/presentation/providers/auth_providers.dart';
import 'package:Softbee/feature/apiaries/presentation/providers/apiary_providers.dart';

// Providers for the Inventory feature

final inventoryLocalDataSourceProvider = Provider<InventoryLocalDataSource>((ref) {
  return InventoryLocalDataSourceImpl();
});

final inventoryRepositoryProvider = Provider<InventoryRepository>((ref) {
  final remoteDataSource = ref.read(inventoryRemoteDataSourceProvider);
  final localDataSource = ref.read(authLocalDataSourceProvider);
  return InventoryRepositoryImpl(
    remoteDataSource: remoteDataSource,
    localDataSource: localDataSource,
    inventoryLocalDataSource: ref.read(inventoryLocalDataSourceProvider),
    networkInfo: ref.read(networkInfoProvider),
  );
});

final inventoryControllerProvider =
    StateNotifierProvider.family<InventoryController, InventoryState, String>((
      ref,
      apiaryId,
    ) {
      final repository = ref.read(inventoryRepositoryProvider);
      final controller = InventoryController(repository);
      controller.loadInventoryItems(apiaryId: apiaryId);
      return controller;
    });
