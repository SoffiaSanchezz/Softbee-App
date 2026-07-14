import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../monitoring/presentation/providers/questions_providers.dart';
import '../../data/repositories/report_repository_impl.dart';
import '../../domain/entities/monitoring_report.dart';
import '../../domain/repositories/report_repository.dart';

final reportRepositoryProvider = Provider<ReportRepository>((ref) {
  final answerRepo = ref.read(answerRepositoryProvider);
  return ReportRepositoryImpl(answerRepo);
});

final reportsProvider = StateNotifierProvider.autoDispose.family<ReportsController, ReportsState, String>((ref, hiveId) {
  final repo = ref.read(reportRepositoryProvider);
  return ReportsController(repo, hiveId);
});

class ReportsState {
  final bool isLoading;
  final List<MonitoringReport> reports;
  final String? error;

  ReportsState({
    this.isLoading = false,
    this.reports = const [],
    this.error,
  });

  ReportsState copyWith({
    bool? isLoading,
    List<MonitoringReport>? reports,
    String? error,
  }) {
    return ReportsState(
      isLoading: isLoading ?? this.isLoading,
      reports: reports ?? this.reports,
      error: error,
    );
  }
}

class ReportsController extends StateNotifier<ReportsState> {
  final ReportRepository _repository;
  final String hiveId;

  ReportsController(this._repository, this.hiveId) : super(ReportsState()) {
    loadReports();
  }

  Future<void> loadReports() async {
    state = state.copyWith(isLoading: true, error: null);
    
    final result = await _repository.getReportsByHive(hiveId);
    
    result.fold(
      (failure) => state = state.copyWith(isLoading: false, error: failure.message),
      (reports) => state = state.copyWith(isLoading: false, reports: reports),
    );
  }
}
