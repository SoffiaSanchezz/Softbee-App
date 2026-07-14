import 'package:equatable/equatable.dart';
import '../../../monitoring/domain/entities/hive_answer.dart';

class MonitoringReport extends Equatable {
  final DateTime timestamp;
  final List<HiveAnswer> answers;
  final int totalScore;

  const MonitoringReport({
    required this.timestamp,
    required this.answers,
    required this.totalScore,
  });

  @override
  List<Object?> get props => [timestamp, answers, totalScore];

  factory MonitoringReport.fromAnswers(List<HiveAnswer> answers) {
    if (answers.isEmpty) {
      return MonitoringReport(
        timestamp: DateTime.now(),
        answers: const [],
        totalScore: 0,
      );
    }

    // Usamos el timestamp de la primera respuesta como referencia de la sesión
    final timestamp = answers.first.answeredAt ?? DateTime.now();
    final totalScore = answers.fold<int>(0, (sum, item) => sum + (item.score ?? 0));

    return MonitoringReport(
      timestamp: timestamp,
      answers: answers,
      totalScore: totalScore,
    );
  }
}
