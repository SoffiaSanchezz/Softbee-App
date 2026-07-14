import 'package:either_dart/either.dart';
import '../../../../core/error/failures.dart';
import '../entities/monitoring_report.dart';

abstract class ReportRepository {
  Future<Either<Failure, List<MonitoringReport>>> getReportsByHive(String hiveId);
}
