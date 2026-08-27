import 'package:flutter/foundation.dart';
import 'entity_sync_handler.dart';
import 'sync_queue.dart';

/// Recorre la cola genérica de operaciones pendientes y delega cada una en el
/// [EntitySyncHandler] correspondiente. Es agnóstico a las features: solo
/// conoce la cola y el mapa de handlers registrados.
class SyncDispatcher {
  final SyncQueue queue;

  /// Handlers indexados por nombre de entidad.
  final Map<String, EntitySyncHandler> _handlers;

  SyncDispatcher({
    required this.queue,
    required List<EntitySyncHandler> handlers,
  }) : _handlers = {for (final h in handlers) h.entity: h};

  /// Procesa todas las operaciones pendientes en orden cronológico.
  /// Retorna true si todas se procesaron correctamente.
  Future<bool> processAll(String token) async {
    final ops = await queue.getAll();
    if (ops.isEmpty) return true;

    bool allSynced = true;

    for (final op in ops) {
      final handler = _handlers[op.entity];
      if (handler == null) {
        // No hay handler registrado para esta entidad: la dejamos en cola
        // (podría registrarse en una versión futura) pero no bloqueamos el
        // resto de la sincronización.
        debugPrint("SyncDispatcher: sin handler para entidad '${op.entity}', se omite.");
        continue;
      }

      try {
        final result = await handler.process(op, token);
        if (result.success) {
          // Remapear id temporal -> id real en el resto de la cola.
          if (op.isTemporary &&
              result.realId != null &&
              result.realId!.isNotEmpty) {
            await queue.replaceEntityId(op.entityId, result.realId!);
          }
          await queue.remove(op.id);
        } else {
          allSynced = false;
        }
      } catch (e) {
        debugPrint("SyncDispatcher: falló operación ${op.id} (${op.entity}): $e");
        allSynced = false;
      }
    }

    return allSynced;
  }
}
