import '../../domain/entities/chat_message.dart';

class MayaResponseModel {
  final String status;
  final String sessionId;
  final String responseText;
  final bool isFinished;

  MayaResponseModel({
    required this.status,
    required this.sessionId,
    required this.responseText,
    required this.isFinished,
  });

  factory MayaResponseModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    return MayaResponseModel(
      status: json['status'] ?? '',
      sessionId: json['session_id'] ?? '',
      responseText: data['response'] ?? '',
      isFinished: data['is_finished'] ?? false,
    );
  }

  ChatMessage toEntity() {
    return ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: responseText,
      role: MessageRole.assistant,
      timestamp: DateTime.now(),
    );
  }
}
