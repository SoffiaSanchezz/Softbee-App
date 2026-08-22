enum OperationType { create, update, delete }

class PendingOperation {
  final String id;
  final OperationType type;
  final String apiaryId;
  final String userId;
  final Map<String, dynamic>? data;
  final DateTime createdAt;

  PendingOperation({
    required this.id,
    required this.type,
    required this.apiaryId,
    required this.userId,
    this.data,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'apiary_id': apiaryId,
      'user_id': userId,
      'data': data,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory PendingOperation.fromJson(Map<String, dynamic> json) {
    return PendingOperation(
      id: json['id'],
      type: OperationType.values.byName(json['type']),
      apiaryId: json['apiary_id'],
      userId: json['user_id'],
      data: json['data'] != null
          ? Map<String, dynamic>.from(json['data'])
          : null,
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
