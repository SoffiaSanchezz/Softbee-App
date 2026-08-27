import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class OfflineStorageService {
  static const String _offlineAnswersKey = 'offline_monitoring_answers';
  static const String _apiaryCacheKey = 'cached_apiary_data_';
  static const String _hiveMonitoringCacheKey = 'cached_hive_monitoring_';

  // --- ANSWERS (STORE-AND-FORWARD) ---
  
  Future<void> saveAnswersLocally(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> existingData = prefs.getStringList(_offlineAnswersKey) ?? [];
    existingData.add(json.encode(data));
    await prefs.setStringList(_offlineAnswersKey, existingData);
  }

  Future<List<Map<String, dynamic>>> getOfflineAnswers() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> existingData = prefs.getStringList(_offlineAnswersKey) ?? [];
    return existingData.map((e) => json.decode(e) as Map<String, dynamic>).toList();
  }

  Future<void> clearOfflineAnswers() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_offlineAnswersKey);
  }

  // --- CONTEXT CACHE (PARA MODO SIN SEÑAL) ---

  Future<void> cacheApiaryContext(String apiaryId, Map<String, dynamic> context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('${_apiaryCacheKey}$apiaryId', json.encode(context));
  }

  Future<Map<String, dynamic>?> getCachedApiaryContext(String apiaryId) async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString('${_apiaryCacheKey}$apiaryId');
    if (data == null) return null;
    return json.decode(data) as Map<String, dynamic>;
  }

  // --- CONTEXTO DE MONITOREO POR COLMENA (PREGUNTAS PARA MAYA OFFLINE) ---

  /// Guarda la respuesta de `iniciar-monitoreo` de una colmena para que Maya
  /// pueda cargar sus preguntas sin conexión.
  Future<void> cacheHiveMonitoring(
    String hiveId,
    Map<String, dynamic> context,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '$_hiveMonitoringCacheKey$hiveId',
      json.encode(context),
    );
  }

  /// Devuelve el contexto de monitoreo cacheado de una colmena, o null si no
  /// se ha precargado con conexión previamente.
  Future<Map<String, dynamic>?> getCachedHiveMonitoring(String hiveId) async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString('$_hiveMonitoringCacheKey$hiveId');
    if (data == null) return null;
    return json.decode(data) as Map<String, dynamic>;
  }
}
