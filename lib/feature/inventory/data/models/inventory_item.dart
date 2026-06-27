class InventoryItem {
  final String id; // Changed from int to String
  final String itemName;
  final int quantity;
  final String unit;
  final String apiaryId;
  final String? description;
  final int minimumStock;
  final DateTime createdAt;
  final DateTime updatedAt;

  InventoryItem({
    required this.id,
    required this.itemName,
    required this.quantity,
    required this.unit,
    required this.apiaryId,
    this.description,
    this.minimumStock = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory InventoryItem.fromJson(Map<String, dynamic> json) {
    return InventoryItem(
      id: json['id']?.toString() ?? '',
      itemName: json['name']?.toString() ?? '',
      quantity: json['quantity'] as int? ?? 0,
      unit: json['unit']?.toString() ?? 'unit',
      apiaryId: json['apiary_id']?.toString() ?? '',
      description: json['description'],
      minimumStock: json['minimum_stock'] as int? ?? 0,
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt:
          DateTime.tryParse(json['updated_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': itemName,
      'quantity': quantity,
      'unit': unit,
      'apiary_id': apiaryId,
      'description': description,
      'minimum_stock': minimumStock,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toCreateJson() {
    return {
      'apiary_id': apiaryId,
      'name': itemName,
      'quantity': quantity,
      'unit': unit,
      'description': description,
      'minimum_stock': minimumStock,
    };
  }

  Map<String, dynamic> toUpdateJson() {
    return {
      'name': itemName,
      'quantity': quantity,
      'unit': unit,
      'description': description,
      'minimum_stock': minimumStock,
    };
  }

  InventoryItem copyWith({
    String? id,
    String? itemName,
    int? quantity,
    String? unit,
    String? apiaryId,
    String? description,
    int? minimumStock,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return InventoryItem(
      id: id ?? this.id,
      itemName: itemName ?? this.itemName,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      apiaryId: apiaryId ?? this.apiaryId,
      description: description ?? this.description,
      minimumStock: minimumStock ?? this.minimumStock,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Convertir a Map para compatibilidad con tu código existente
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': itemName,
      'cantidad': quantity.toString(),
      'unidad': unit,
      'apiary_id': apiaryId,
    };
  }

  // Crear desde Map para compatibilidad con tu código existente
  factory InventoryItem.fromMap(Map<String, dynamic> map) {
    return InventoryItem(
      id: map['id']?.toString() ?? '', // Changed to String
      itemName: map['nombre']?.toString() ?? '',
      quantity: int.tryParse(map['cantidad']?.toString() ?? '0') ?? 0,
      unit: map['unidad']?.toString() ?? 'unit',
      apiaryId: map['apiary_id']?.toString() ?? '',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
}
