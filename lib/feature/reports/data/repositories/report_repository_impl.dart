import 'package:either_dart/either.dart';
import '../../../../core/error/failures.dart';
import '../../../monitoring/domain/repositories/answer_repository.dart';
import '../../domain/entities/monitoring_report.dart';
import '../../domain/repositories/report_repository.dart';

class ReportRepositoryImpl implements ReportRepository {
  final AnswerRepository _answerRepository;

  ReportRepositoryImpl(this._answerRepository);

  @override
  Future<Either<Failure, List<MonitoringReport>>> getReportsByHive(String hiveId) async {
    final result = await _answerRepository.getAnswersByHive(hiveId);
    
    return result.fold(
      (failure) => Left(failure),
      (answers) {
        // Agrupar respuestas por answeredAt
        final Map<String, List<dynamic>> groups = {};
        
        for (var ans in answers) {
          if (ans.answeredAt == null) continue;
          
          final at = ans.answeredAt!;
          final key = "${at.year}-${at.month}-${at.day} ${at.hour}:${at.minute}";
          
          if (!groups.containsKey(key)) {
            groups[key] = [];
          }
          groups[key]!.add(ans);
        }
        
        final reports = groups.values.map((groupAnswers) {
          return MonitoringReport.fromAnswers(List.from(groupAnswers));
        }).toList();
        
        reports.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        
        return Right(reports);
      },
    );
  }
}
