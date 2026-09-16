import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../../domain/entities/beehive.dart';
import '../models/pending_beehive_operation.dart';

abstract class BeehiveLocalDataSource {
  Future<void> cacheBeehives(String apiaryId, List<Beehive> beehives);
  Future<List<Beehive>> getCachedBeehives(String apiaryId);
  Future<void> saveBeehive(String apiaryId, Beehive beehive);
  Future<void> updateLocalBeehive(String apiaryId, Beehive beehive);
  Future<void> deleteLocalBeehive(String apiaryId, String beehiveId);
  Future<void> clearCache();

  // Cola de operaciones pendientes de sincronizar
  Future<void> addPendingOperation(PendingBeehiveOperation operation);
  Future<List<PendingBeehiveOperation>> getPendingOperations();
  Future<void> removePendingOperation(String operationId);
  Future<void> clearPendingOperations();

  /// Reemplaza el id temporal de una colmena por el id real devuelto por el
  /// servidor, tanto en el cache local como en las operaciones pendientes.
  Future<void> replaceBeehiveId(
    String apiaryId,
    String tempId,
    String realId,
  );
}

class BeehiveLocalDataSourceImpl implements BeehiveLocalDataSource {
  static const String _boxName = 'beehive_box';
  static const String _pendingOpsBoxName = 'beehive_pending_operations_box';
  static const String _pendingOpsKey = 'beehive_pending_ops';

  Future<Box> _openBox() async {
    return await Hive.openBox(_boxName);
  }

  /// Clave por apiario para guardar cada set de colmenas separado
  String _keyForApiary(String apiaryId) => 'beehives_$apiaryId';

  @override
  Future<void> cacheBeehives(String apiaryId, List<Beehive> beehives) async {
    final box = await _openBox();
    final List<String> jsonList =
        beehives.map((b) => json.encode(b.toJson())).toList();
    await box.put(_keyForApiary(apiaryId), jsonList);
  }

  @override
  Future<List<Beehive>> getCachedBeehives(String apiaryId) async {
    final box = await _openBox();
    final List<dynamic>? jsonList = box.get(_keyForApiary(apiaryId));

    if (jsonList != null) {
      return jsonList
          .map((item) => Beehive.fromJson(json.decode(item as String)))
          .toList();
    }
    return [];
  }

  @override
  Future<void> saveBeehive(String apiaryId, Beehive beehive) async {
    final beehives = await getCachedBeehives(apiaryId);
    beehives.add(beehive);
    await cacheBeehives(apiaryId, beehives);
  }

  @override
  Future<void> updateLocalBeehive(String apiaryId, Beehive beehive) async {
    final beehives = await getCachedBeehives(apiaryId);
    final index = beehives.indexWhere((b) => b.id == beehive.id);
    if (index != -1) {
      beehives[index] = beehive;
    } else {
      beehives.add(beehive);
    }
    await cacheBeehives(apiaryId, beehives);
  }

  @override
  Future<void> deleteLocalBeehive(String apiaryId, String beehiveId) async {
    final beehives = await getCachedBeehives(apiaryId);
    beehives.removeWhere((b) => b.id == beehiveId);
    await cacheBeehives(apiaryId, beehives);
  }

  @override
  Future<void> clearCache() async {
    final box = await _openBox();
    await box.clear();
  }

  // ===================== COLA DE PENDIENTES =====================

  @override
  Future<void> addPendingOperation(PendingBeehiveOperation operation) async {
    final ops = await getPendingOperations();
    ops.add(operation);
    await _savePendingOperations(ops);
  }

  @override
  Future<List<PendingBeehiveOperation>> getPendingOperations() async {
    final box = await Hive.openBox(_pendingOpsBoxName);
    final List<dynamic>? jsonList = box.get(_pendingOpsKey);

    if (jsonList != null) {
      return jsonList
          .map((item) =>
              PendingBeehiveOperation.fromJson(json.decode(item as String)))
          .toList();
    }
    return [];
  }

  @override
  Future<void> removePendingOperation(String operationId) async {
    final ops = await getPendingOperations();
    ops.removeWhere((op) => op.id == operationId);
    await _savePendingOperations(ops);
  }

  @override
  Future<void> clearPendingOperations() async {
    final box = await Hive.openBox(_pendingOpsBoxName);
    await box.delete(_pendingOpsKey);
  }

  Future<void> _savePendingOperations(
    List<PendingBeehiveOperation> ops,
  ) async {
    final box = await Hive.openBox(_pendingOpsBoxName);
    final List<String> jsonList =
        ops.map((op) => json.encode(op.toJson())).toList();
    await box.put(_pendingOpsKey, jsonList);
  }

  @override
  Future<void> replaceBeehiveId(
    String apiaryId,
    String tempId,
    String realId,
  ) async {
    // 1. Actualizar el cache de colmenas
    final beehives = await getCachedBeehives(apiaryId);
    final index = beehives.indexWhere((b) => b.id == tempId);
    if (index != -1) {
      beehives[index] = beehives[index].copyWith(id: realId);
      await cacheBeehives(apiaryId, beehives);
    }

    // 2. Actualizar operaciones pendientes que referencian el id temporal
    final ops = await getPendingOperations();
    bool changed = false;
    for (var i = 0; i < ops.length; i++) {
      if (ops[i].beehiveId == tempId) {
        ops[i] = ops[i].copyWith(beehiveId: realId);
        changed = true;
      }
    }
    if (changed) {
      await _savePendingOperations(ops);
    }
  }
}
