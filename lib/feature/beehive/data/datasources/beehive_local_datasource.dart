import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../../domain/entities/beehive.dart';

abstract class BeehiveLocalDataSource {
  Future<void> cacheBeehives(String apiaryId, List<Beehive> beehives);
  Future<List<Beehive>> getCachedBeehives(String apiaryId);
  Future<void> saveBeehive(String apiaryId, Beehive beehive);
  Future<void> updateLocalBeehive(String apiaryId, Beehive beehive);
  Future<void> deleteLocalBeehive(String apiaryId, String beehiveId);
  Future<void> clearCache();
}

class BeehiveLocalDataSourceImpl implements BeehiveLocalDataSource {
  static const String _boxName = 'beehive_box';

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
}
