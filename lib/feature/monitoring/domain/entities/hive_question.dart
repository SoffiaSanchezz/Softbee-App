import 'package:equatable/equatable.dart';
import 'question_model.dart';

class HiveQuestion extends Equatable {
  final String id;
  final String hiveId;
  final String apiaryQuestionId;
  final int displayOrder;
  final bool isActive;
  final Pregunta? apiaryQuestion;

  const HiveQuestion({
    required this.id,
    required this.hiveId,
    required this.apiaryQuestionId,
    required this.displayOrder,
    required this.isActive,
    this.apiaryQuestion,
  });

  factory HiveQuestion.fromJson(Map<String, dynamic> json) {
    return HiveQuestion(
      id: json['id']?.toString() ?? '',
      hiveId: json['hive_id']?.toString() ?? '',
      apiaryQuestionId: json['apiary_question_id']?.toString() ?? '',
      displayOrder: (json['display_order'] as num?)?.toInt() ?? 0,
      isActive: json['is_active'] ?? true,
      apiaryQuestion: (json['apiary_question'] != null || json['apiaryQuestion'] != null)
          ? Pregunta.fromJson(Map<String, dynamic>.from(json['apiary_question'] ?? json['apiaryQuestion']))
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'hive_id': hiveId,
      'apiary_question_id': apiaryQuestionId,
      'display_order': displayOrder,
      'is_active': isActive,
      if (apiaryQuestion != null) 'apiary_question': apiaryQuestion!.toJson(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        hiveId,
        apiaryQuestionId,
        displayOrder,
        isActive,
        apiaryQuestion,
      ];
}
