import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../../domain/entities/apiary.dart';
import '../models/pending_operation.dart';

abstract class ApiaryLocalDataSource {
  // Cache de apiarios
  Future<void> cacheApiaries(List<Apiary> apiaries);
  Future<List<Apiary>> getLastApiaries();

  // CRUD local
  Future<void> saveApiary(Apiary apiary);
  Future<void> updateLocalApiary(Apiary apiary);
  Future<void> deleteLocalApiary(String apiaryId);

  // Cola de operaciones pendientes
  Future<void> addPendingOperation(PendingOperation operation);
  Future<List<PendingOperation>> getPendingOperations();
  Future<void> removePendingOperation(String operationId);
  Future<void> clearPendingOperations();
}

class ApiaryLocalDataSourceImpl implements ApiaryLocalDataSource {
  static const String _apiaryBoxName = 'apiary_box';
  static const String _apiaryKey = 'cached_apiaries';
  static const String _pendingOpsBoxName = 'pending_operations_box';
  static const String _pendingOpsKey = 'pending_ops';

  // ===================== CACHE DE APIARIOS =====================

  @override
  Future<void> cacheApiaries(List<Apiary> apiaries) async {
    final box = await Hive.openBox(_apiaryBoxName);
    final List<String> jsonList =
        apiaries.map((a) => json.encode(a.toJson())).toList();
    await box.put(_apiaryKey, jsonList);
  }

  @override
  Future<List<Apiary>> getLastApiaries() async {
    final box = await Hive.openBox(_apiaryBoxName);
    final List<dynamic>? jsonList = box.get(_apiaryKey);

    if (jsonList != null) {
      return jsonList
          .map((item) => Apiary.fromJson(json.decode(item as String)))
          .toList();
    }
    return [];
  }

  // ===================== CRUD LOCAL =====================

  @override
  Future<void> saveApiary(Apiary apiary) async {
    final apiaries = await getLastApiaries();
    apiaries.add(apiary);
    await cacheApiaries(apiaries);
  }

  @override
  Future<void> updateLocalApiary(Apiary apiary) async {
    final apiaries = await getLastApiaries();
    final index = apiaries.indexWhere((a) => a.id == apiary.id);
    if (index != -1) {
      apiaries[index] = apiary;
    } else {
      apiaries.add(apiary);
    }
    await cacheApiaries(apiaries);
  }

  @override
  Future<void> deleteLocalApiary(String apiaryId) async {
    final apiaries = await getLastApiaries();
    apiaries.removeWhere((a) => a.id == apiaryId);
    await cacheApiaries(apiaries);
  }

  // ===================== COLA DE PENDIENTES =====================

  @override
  Future<void> addPendingOperation(PendingOperation operation) async {
    final ops = await getPendingOperations();
    ops.add(operation);
    await _savePendingOperations(ops);
  }

  @override
  Future<List<PendingOperation>> getPendingOperations() async {
    final box = await Hive.openBox(_pendingOpsBoxName);
    final List<dynamic>? jsonList = box.get(_pendingOpsKey);

    if (jsonList != null) {
      return jsonList
          .map((item) => PendingOperation.fromJson(json.decode(item as String)))
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

  Future<void> _savePendingOperations(List<PendingOperation> ops) async {
    final box = await Hive.openBox(_pendingOpsBoxName);
    final List<String> jsonList =
        ops.map((op) => json.encode(op.toJson())).toList();
    await box.put(_pendingOpsKey, jsonList);
  }
}
