enum BeehiveOperationType { create, update, delete }

/// Representa una operación de colmena (beehive) pendiente de sincronizar
/// con el servidor. Se encola cuando el usuario opera sin conexión y se
/// procesa cuando vuelve el internet.
class PendingBeehiveOperation {
  final String id;
  final BeehiveOperationType type;

  /// Id de la colmena. Para operaciones `create` realizadas offline es un
  /// id temporal (`temp_...`) que luego se remapea al id real del servidor.
  final String beehiveId;
  final String apiaryId;

  /// Datos de la colmena para create/update. Null en delete.
  final Map<String, dynamic>? data;
  final DateTime createdAt;

  PendingBeehiveOperation({
    required this.id,
    required this.type,
    required this.beehiveId,
    required this.apiaryId,
    this.data,
    required this.createdAt,
  });

  bool get isTemporary => beehiveId.startsWith('temp_');

  PendingBeehiveOperation copyWith({
    String? id,
    BeehiveOperationType? type,
    String? beehiveId,
    String? apiaryId,
    Map<String, dynamic>? data,
    DateTime? createdAt,
  }) {
    return PendingBeehiveOperation(
      id: id ?? this.id,
      type: type ?? this.type,
      beehiveId: beehiveId ?? this.beehiveId,
      apiaryId: apiaryId ?? this.apiaryId,
      data: data ?? this.data,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'beehive_id': beehiveId,
      'apiary_id': apiaryId,
      'data': data,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory PendingBeehiveOperation.fromJson(Map<String, dynamic> json) {
    return PendingBeehiveOperation(
      id: json['id'] as String,
      type: BeehiveOperationType.values.byName(json['type'] as String),
      beehiveId: json['beehive_id'] as String,
      apiaryId: json['apiary_id'] as String,
      data: json['data'] != null
          ? Map<String, dynamic>.from(json['data'] as Map)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
