/// Tipo de operación pendiente de sincronizar.
enum SyncOperationType { create, update, delete }

/// Operación genérica pendiente de sincronizar con el servidor.
///
/// Es agnóstica a la feature: identifica la entidad afectada mediante
/// [entity] (por ejemplo 'inventory', 'question', 'answer', 'treatment') y
/// guarda los datos necesarios para reproducir la operación en [data].
///
/// El [SyncDispatcher] usa [entity] + [type] para enrutar cada operación al
/// data source remoto correspondiente cuando vuelve la conexión.
class PendingSyncOperation {
  final String id;

  /// Nombre de la entidad/feature (ej. 'inventory', 'question', 'answer').
  final String entity;

  final SyncOperationType type;

  /// Id local de la entidad. Para creaciones offline suele ser un id
  /// temporal (`temp_...`) que se remapea al id real tras sincronizar.
  final String entityId;

  /// Id del apiario asociado (cuando aplica), útil para actualizar el cache
  /// correcto tras la sincronización. Puede ser null.
  final String? apiaryId;

  /// Datos de la operación (payload). Null en algunos delete.
  final Map<String, dynamic>? data;

  final DateTime createdAt;

  PendingSyncOperation({
    required this.id,
    required this.entity,
    required this.type,
    required this.entityId,
    this.apiaryId,
    this.data,
    required this.createdAt,
  });

  bool get isTemporary => entityId.startsWith('temp_');

  PendingSyncOperation copyWith({
    String? id,
    String? entity,
    SyncOperationType? type,
    String? entityId,
    String? apiaryId,
    Map<String, dynamic>? data,
    DateTime? createdAt,
  }) {
    return PendingSyncOperation(
      id: id ?? this.id,
      entity: entity ?? this.entity,
      type: type ?? this.type,
      entityId: entityId ?? this.entityId,
      apiaryId: apiaryId ?? this.apiaryId,
      data: data ?? this.data,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'entity': entity,
      'type': type.name,
      'entity_id': entityId,
      'apiary_id': apiaryId,
      'data': data,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory PendingSyncOperation.fromJson(Map<String, dynamic> json) {
    return PendingSyncOperation(
      id: json['id'] as String,
      entity: json['entity'] as String,
      type: SyncOperationType.values.byName(json['type'] as String),
      entityId: json['entity_id'] as String,
      apiaryId: json['apiary_id'] as String?,
      data: json['data'] != null
          ? Map<String, dynamic>.from(json['data'] as Map)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
