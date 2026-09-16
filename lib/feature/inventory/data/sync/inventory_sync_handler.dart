import 'package:Softbee/core/sync/entity_sync_handler.dart';
import 'package:Softbee/core/sync/pending_sync_operation.dart';
import 'package:Softbee/feature/inventory/data/datasources/inventory_local_datasource.dart';
import 'package:Softbee/feature/inventory/data/datasources/inventory_remote_datasource.dart';
import 'package:Softbee/feature/inventory/data/models/inventory_item.dart';

/// Nombre de entidad usado en la cola de sincronización para inventario.
const String kInventoryEntity = 'inventory';

/// Sube al servidor las operaciones de inventario que se hicieron offline.
class InventorySyncHandler implements EntitySyncHandler {
  final InventoryRemoteDataSource remoteDataSource;
  final InventoryLocalDataSource localDataSource;

  InventorySyncHandler({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  String get entity => kInventoryEntity;

  @override
  Future<SyncHandlerResult> process(
    PendingSyncOperation op,
    String token,
  ) async {
    final data = op.data;
    final apiaryId = op.apiaryId ?? data?['apiary_id']?.toString() ?? '';

    switch (op.type) {
      case SyncOperationType.create:
        final item = InventoryItem.fromJson(data!);
        final created = await remoteDataSource.createInventoryItem(item);

        // Remapear id temporal -> id real en el cache local.
        if (op.isTemporary && created.id.isNotEmpty && apiaryId.isNotEmpty) {
          await localDataSource.deleteLocalItem(apiaryId, op.entityId);
          await localDataSource.saveItem(apiaryId, created);
        }
        return SyncHandlerResult.created(created.id);

      case SyncOperationType.update:
        // No se puede actualizar en el servidor algo que aún no existe allí.
        if (op.isTemporary) return const SyncHandlerResult.ok();
        final item = InventoryItem.fromJson(data!);
        await remoteDataSource.updateInventoryItem(item);
        return const SyncHandlerResult.ok();

      case SyncOperationType.delete:
        if (op.isTemporary) return const SyncHandlerResult.ok();
        await remoteDataSource.deleteInventoryItem(op.entityId);
        return const SyncHandlerResult.ok();
    }
  }
}
