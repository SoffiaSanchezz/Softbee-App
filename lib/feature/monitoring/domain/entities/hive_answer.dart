import 'package:equatable/equatable.dart';
import 'package:Softbee/core/utils/date_parser.dart';
import 'hive_question.dart';

class HiveAnswer extends Equatable {
  final String id;
  final String hiveQuestionId;
  final String answer;
  final int score;
  final String? answeredBy;
  final DateTime? answeredAt;
  final HiveQuestion? hiveQuestion; // Relación opcional para mostrar texto

  const HiveAnswer({
    required this.id,
    required this.hiveQuestionId,
    required this.answer,
    this.score = 0,
    this.answeredBy,
    this.answeredAt,
    this.hiveQuestion,
  });

  factory HiveAnswer.fromJson(Map<String, dynamic> json) {
    return HiveAnswer(
      id: json['id']?.toString() ?? '',
      hiveQuestionId: json['hive_question_id']?.toString() ?? '',
      answer: json['answer']?.toString() ?? '',
      score: (json['score'] as num?)?.toInt() ?? 0,
      answeredBy: json['answered_by']?.toString(),
      answeredAt: DateParser.parseBackendDate(json['answered_at']),
      hiveQuestion: json['hive_question'] != null 
          ? HiveQuestion.fromJson(json['hive_question']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'hive_question_id': hiveQuestionId,
      'answer': answer,
      'score': score,
      if (answeredBy != null) 'answered_by': answeredBy,
      if (answeredAt != null) 'answered_at': answeredAt!.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        hiveQuestionId,
        answer,
        score,
        answeredBy,
        answeredAt,
      ];
}
