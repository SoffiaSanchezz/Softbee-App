import 'pending_sync_operation.dart';

/// Resultado del procesamiento de una operación pendiente.
class SyncHandlerResult {
  /// true si la operación se procesó (o se puede descartar de forma segura).
  final bool success;

  /// Si la operación era una creación con id temporal y el servidor devolvió
  /// un id real, aquí va ese id para remapear la cola y el cache.
  final String? realId;

  const SyncHandlerResult({required this.success, this.realId});

  const SyncHandlerResult.ok() : success = true, realId = null;
  const SyncHandlerResult.failed() : success = false, realId = null;
  const SyncHandlerResult.created(this.realId) : success = true;
}

/// Contrato que cada feature implementa para saber cómo enviar al servidor
/// una operación pendiente de su entidad. El [SyncDispatcher] delega en el
/// handler cuyo [entity] coincide con el de la operación.
abstract class EntitySyncHandler {
  /// Nombre de la entidad que maneja este handler (ej. 'inventory').
  String get entity;

  /// Procesa una operación pendiente contra el backend.
  /// Debe lanzar o devolver `SyncHandlerResult.failed()` si falla, para que
  /// la operación permanezca en la cola y se reintente luego.
  Future<SyncHandlerResult> process(PendingSyncOperation operation, String token);
}
