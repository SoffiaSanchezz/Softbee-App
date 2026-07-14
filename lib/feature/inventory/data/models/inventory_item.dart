import 'package:intl/intl.dart';

class InventoryItem {
  final String id;
  final String itemName;
  final String category;
  final int quantity;
  final String unit;
  final String apiaryId;
  final String? description;
  final int minimumStock;
  
  // Campos Profesionales
  final String? batchNumber;
  final DateTime? expiryDate;
  final DateTime? purchaseDate;
  final String? supplier;
  final String? storageLocation;
  
  final DateTime createdAt;
  final DateTime updatedAt;

  InventoryItem({
    required this.id,
    required this.itemName,
    this.category = 'General',
    required this.quantity,
    required this.unit,
    required this.apiaryId,
    this.description,
    this.minimumStock = 0,
    this.batchNumber,
    this.expiryDate,
    this.purchaseDate,
    this.supplier,
    this.storageLocation,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isLowStock => quantity <= minimumStock;
  bool get isExpired => expiryDate != null && expiryDate!.isBefore(DateTime.now());
  bool get isAboutToExpire => expiryDate != null && 
      expiryDate!.isBefore(DateTime.now().add(const Duration(days: 30))) && !isExpired;

  /// Parsea una fecha desde el formato RFC 1123 (HTTP) o ISO 8601
  static DateTime _parseDate(dynamic dateValue) {
    if (dateValue == null) return DateTime.now();
    final dateStr = dateValue.toString();
    
    // 1. Intentar parseo estándar (ISO 8601)
    final parsed = DateTime.tryParse(dateStr);
    if (parsed != null) return parsed;

    // 2. Intentar parseo RFC 1123 (Fri, 06 Mar 2026 05:21:43 GMT)
    try {
      // Usamos en_US porque los nombres de días/meses suelen venir en inglés desde la API
      return DateFormat("EEE, dd MMM yyyy HH:mm:ss 'GMT'", 'en_US').parse(dateStr);
    } catch (_) {
      // 3. Fallback a la fecha actual si todo falla para evitar que la app se rompa
      return DateTime.now();
    }
  }

  factory InventoryItem.fromJson(Map<String, dynamic> json) {
    return InventoryItem(
      id: json['id']?.toString() ?? '',
      itemName: json['name']?.toString() ?? '',
      category: json['category']?.toString() ?? 'General',
      quantity: json['quantity'] as int? ?? 0,
      unit: json['unit']?.toString() ?? 'unit',
      apiaryId: json['apiary_id']?.toString() ?? '',
      description: json['description'],
      minimumStock: json['minimum_stock'] as int? ?? 0,
      batchNumber: json['batch_number'],
      expiryDate: json['expiry_date'] != null ? _parseDate(json['expiry_date']) : null,
      purchaseDate: json['purchase_date'] != null ? _parseDate(json['purchase_date']) : null,
      supplier: json['supplier'],
      storageLocation: json['storage_location'],
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': itemName,
      'category': category,
      'quantity': quantity,
      'unit': unit,
      'apiary_id': apiaryId,
      'description': description,
      'minimum_stock': minimumStock,
      'batch_number': batchNumber,
      'expiry_date': expiryDate?.toIso8601String().split('T')[0],
      'purchase_date': purchaseDate?.toIso8601String().split('T')[0],
      'supplier': supplier,
      'storage_location': storageLocation,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toCreateJson() {
    return {
      'apiary_id': apiaryId,
      'name': itemName,
      'category': category,
      'quantity': quantity,
      'unit': unit,
      'description': description,
      'minimum_stock': minimumStock,
      'batch_number': batchNumber,
      'expiry_date': expiryDate?.toIso8601String().split('T')[0],
      'purchase_date': purchaseDate?.toIso8601String().split('T')[0],
      'supplier': supplier,
      'storage_location': storageLocation,
    };
  }

  Map<String, dynamic> toUpdateJson() {
    final json = toCreateJson();
    json.remove('apiary_id');
    return json;
  }

  InventoryItem copyWith({
    String? id,
    String? itemName,
    String? category,
    int? quantity,
    String? unit,
    String? apiaryId,
    String? description,
    int? minimumStock,
    String? batchNumber,
    DateTime? expiryDate,
    DateTime? purchaseDate,
    String? supplier,
    String? storageLocation,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return InventoryItem(
      id: id ?? this.id,
      itemName: itemName ?? this.itemName,
      category: category ?? this.category,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      apiaryId: apiaryId ?? this.apiaryId,
      description: description ?? this.description,
      minimumStock: minimumStock ?? this.minimumStock,
      batchNumber: batchNumber ?? this.batchNumber,
      expiryDate: expiryDate ?? this.expiryDate,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      supplier: supplier ?? this.supplier,
      storageLocation: storageLocation ?? this.storageLocation,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
