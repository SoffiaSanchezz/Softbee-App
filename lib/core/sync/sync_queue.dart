import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'pending_sync_operation.dart';

/// Cola persistente y genérica de operaciones pendientes de sincronizar.
///
/// Todas las features encolan aquí sus operaciones offline. Se almacena en
/// una única box de Hive, ordenada por fecha de creación al leer.
abstract class SyncQueue {
  Future<void> add(PendingSyncOperation operation);
  Future<List<PendingSyncOperation>> getAll();

  /// Operaciones de una entidad concreta (ej. 'inventory').
  Future<List<PendingSyncOperation>> getByEntity(String entity);

  Future<void> remove(String operationId);
  Future<void> clear();

  /// Reemplaza un id temporal por el id real en toda la cola. Útil cuando una
  /// creación offline se sincroniza y el servidor devuelve el id definitivo,
  /// para que operaciones posteriores (update/delete) apunten al id correcto.
  Future<void> replaceEntityId(String tempId, String realId);
}

class SyncQueueImpl implements SyncQueue {
  static const String _boxName = 'sync_queue_box';
  static const String _key = 'pending_operations';

  Future<Box> _openBox() async => Hive.openBox(_boxName);

  @override
  Future<void> add(PendingSyncOperation operation) async {
    final ops = await getAll();
    ops.add(operation);
    await _save(ops);
  }

  @override
  Future<List<PendingSyncOperation>> getAll() async {
    final box = await _openBox();
    final List<dynamic>? jsonList = box.get(_key);
    if (jsonList == null) return [];
    final ops = jsonList
        .map((item) =>
            PendingSyncOperation.fromJson(json.decode(item as String)))
        .toList();
    ops.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return ops;
  }

  @override
  Future<List<PendingSyncOperation>> getByEntity(String entity) async {
    final ops = await getAll();
    return ops.where((op) => op.entity == entity).toList();
  }

  @override
  Future<void> remove(String operationId) async {
    final ops = await getAll();
    ops.removeWhere((op) => op.id == operationId);
    await _save(ops);
  }

  @override
  Future<void> clear() async {
    final box = await _openBox();
    await box.delete(_key);
  }

  @override
  Future<void> replaceEntityId(String tempId, String realId) async {
    final ops = await getAll();
    bool changed = false;
    for (var i = 0; i < ops.length; i++) {
      if (ops[i].entityId == tempId) {
        ops[i] = ops[i].copyWith(entityId: realId);
        changed = true;
      }
    }
    if (changed) await _save(ops);
  }

  Future<void> _save(List<PendingSyncOperation> ops) async {
    final box = await _openBox();
    final List<String> jsonList =
        ops.map((op) => json.encode(op.toJson())).toList();
    await box.put(_key, jsonList);
  }
}
