import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/inventory_category.dart';

/// Persistencia local de las categorías de inventario.
///
/// El icono y el color son puramente de presentación, por lo que se guardan en
/// el dispositivo (shared_preferences) en lugar del backend. La primera vez se
/// siembran las categorías por defecto.
class CategoryLocalDataSource {
  static const String _key = 'inventory_categories_v1';

  Future<List<InventoryCategory>> getCategories() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);

    if (raw == null || raw.isEmpty) {
      final defaults = InventoryCategory.defaults();
      await saveCategories(defaults);
      return defaults;
    }

    try {
      final List<dynamic> list = json.decode(raw) as List<dynamic>;
      final categories = list
          .map((e) => InventoryCategory.fromJson(e as Map<String, dynamic>))
          .toList();
      return categories.isEmpty ? InventoryCategory.defaults() : categories;
    } catch (_) {
      // Si los datos están corruptos, se regeneran los valores por defecto.
      final defaults = InventoryCategory.defaults();
      await saveCategories(defaults);
      return defaults;
    }
  }

  Future<void> saveCategories(List<InventoryCategory> categories) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = json.encode(categories.map((c) => c.toJson()).toList());
    await prefs.setString(_key, raw);
  }
}
