import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/inventory_item.dart';

abstract class InventoryLocalDataSource {
  Future<void> cacheInventoryItems(String apiaryId, List<InventoryItem> items);
  Future<List<InventoryItem>> getCachedInventoryItems(String apiaryId);
  Future<void> saveItem(String apiaryId, InventoryItem item);
  Future<void> updateLocalItem(String apiaryId, InventoryItem item);
  Future<void> deleteLocalItem(String apiaryId, String itemId);
  Future<void> clearCache();
}

class InventoryLocalDataSourceImpl implements InventoryLocalDataSource {
  static const String _boxName = 'inventory_box';

  Future<Box> _openBox() async {
    return await Hive.openBox(_boxName);
  }

  String _keyForApiary(String apiaryId) => 'inventory_$apiaryId';

  @override
  Future<void> cacheInventoryItems(String apiaryId, List<InventoryItem> items) async {
    final box = await _openBox();
    final List<String> jsonList =
        items.map((item) => json.encode(item.toJson())).toList();
    await box.put(_keyForApiary(apiaryId), jsonList);
  }

  @override
  Future<List<InventoryItem>> getCachedInventoryItems(String apiaryId) async {
    final box = await _openBox();
    final List<dynamic>? jsonList = box.get(_keyForApiary(apiaryId));

    if (jsonList != null) {
      return jsonList
          .map((item) => InventoryItem.fromJson(json.decode(item as String)))
          .toList();
    }
    return [];
  }

  @override
  Future<void> saveItem(String apiaryId, InventoryItem item) async {
    final items = await getCachedInventoryItems(apiaryId);
    items.add(item);
    await cacheInventoryItems(apiaryId, items);
  }

  @override
  Future<void> updateLocalItem(String apiaryId, InventoryItem item) async {
    final items = await getCachedInventoryItems(apiaryId);
    final index = items.indexWhere((i) => i.id == item.id);
    if (index != -1) {
      items[index] = item;
    } else {
      items.add(item);
    }
    await cacheInventoryItems(apiaryId, items);
  }

  @override
  Future<void> deleteLocalItem(String apiaryId, String itemId) async {
    final items = await getCachedInventoryItems(apiaryId);
    items.removeWhere((i) => i.id == itemId);
    await cacheInventoryItems(apiaryId, items);
  }

  @override
  Future<void> clearCache() async {
    final box = await _openBox();
    await box.clear();
  }
}
