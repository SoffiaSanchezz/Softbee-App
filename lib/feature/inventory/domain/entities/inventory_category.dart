import 'package:flutter/material.dart';

/// Registro de iconos permitidos para las categorías.
///
/// En Flutter Web (tree-shaking de iconos) no se pueden crear `IconData`
/// dinámicamente desde un codepoint arbitrario, por eso las categorías guardan
/// una clave (`iconKey`) que se resuelve contra este mapa de iconos constantes.
class CategoryIcons {
  CategoryIcons._();

  static const IconData fallback = Icons.category_rounded;

  static const Map<String, IconData> all = {
    'handyman': Icons.handyman_rounded,
    'build': Icons.build_rounded,
    'water_drop': Icons.water_drop_rounded,
    'hive': Icons.hive_rounded,
    'science': Icons.science_rounded,
    'medication': Icons.medication_rounded,
    'shield': Icons.shield_rounded,
    'masks': Icons.masks_rounded,
    'inventory': Icons.inventory_2_rounded,
    'warehouse': Icons.warehouse_rounded,
    'local_shipping': Icons.local_shipping_rounded,
    'settings': Icons.settings_rounded,
    'precision': Icons.precision_manufacturing_rounded,
    'agriculture': Icons.agriculture_rounded,
    'grass': Icons.grass_rounded,
    'bolt': Icons.bolt_rounded,
    'cleaning': Icons.cleaning_services_rounded,
    'category': Icons.category_rounded,
  };

  static IconData resolve(String? key) => all[key] ?? fallback;

  static List<String> get keys => all.keys.toList();
}

/// Paleta de colores disponible para las categorías (coherente con la app).
class CategoryColors {
  CategoryColors._();

  static const List<int> palette = [
    0xFFF5A623, // ámbar (identidad de la app)
    0xFFE8961A, // ámbar oscuro
    0xFF66BB6A, // verde
    0xFF42A5F5, // azul
    0xFFAB47BC, // púrpura
    0xFFEF5350, // rojo
    0xFF26A69A, // teal
    0xFF8D6E63, // marrón
    0xFF78909C, // gris azulado
    0xFFFFCA28, // amarillo
  ];
}

/// Entidad de categoría de inventario. El icono y el color son concerns de UI
/// y se resuelven a partir de `iconKey` y `colorValue`.
class InventoryCategory {
  final String id;
  final String name;
  final String iconKey;
  final int colorValue;

  const InventoryCategory({
    required this.id,
    required this.name,
    required this.iconKey,
    required this.colorValue,
  });

  IconData get icon => CategoryIcons.resolve(iconKey);
  Color get color => Color(colorValue);

  factory InventoryCategory.fromJson(Map<String, dynamic> json) {
    return InventoryCategory(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Sin nombre',
      iconKey: json['icon_key']?.toString() ?? 'category',
      colorValue: (json['color_value'] as num?)?.toInt() ?? 0xFFF5A623,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'icon_key': iconKey,
        'color_value': colorValue,
      };

  InventoryCategory copyWith({
    String? id,
    String? name,
    String? iconKey,
    int? colorValue,
  }) {
    return InventoryCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      iconKey: iconKey ?? this.iconKey,
      colorValue: colorValue ?? this.colorValue,
    );
  }

  /// Categorías por defecto (se siembran la primera vez).
  static List<InventoryCategory> defaults() => const [
        InventoryCategory(id: 'cat_herramientas', name: 'Herramientas', iconKey: 'handyman', colorValue: 0xFF8D6E63),
        InventoryCategory(id: 'cat_produccion', name: 'Producción', iconKey: 'water_drop', colorValue: 0xFFF5A623),
        InventoryCategory(id: 'cat_tratamientos', name: 'Tratamientos', iconKey: 'science', colorValue: 0xFF66BB6A),
        InventoryCategory(id: 'cat_proteccion', name: 'Protección Personal', iconKey: 'shield', colorValue: 0xFF42A5F5),
        InventoryCategory(id: 'cat_materiales', name: 'Materiales', iconKey: 'inventory', colorValue: 0xFF78909C),
        InventoryCategory(id: 'cat_colmenas', name: 'Colmenas', iconKey: 'hive', colorValue: 0xFFFFCA28),
        InventoryCategory(id: 'cat_transporte', name: 'Transporte', iconKey: 'local_shipping', colorValue: 0xFF26A69A),
        InventoryCategory(id: 'cat_equipos', name: 'Equipos', iconKey: 'settings', colorValue: 0xFFAB47BC),
        InventoryCategory(id: 'cat_otros', name: 'Otros', iconKey: 'category', colorValue: 0xFF9E9E9E),
      ];
}
