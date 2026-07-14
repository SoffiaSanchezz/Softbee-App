import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/apiary_insights_service.dart';

class AdvancedInsightsState {
  final bool isLoading;
  final bool isAiLoading;
  final Map<String, dynamic>? generalStats;
  final List<dynamic>? healthTrends;
  final List<dynamic>? treatmentDist;
  final List<dynamic>? inventoryLevels;
  final Map<String, dynamic>? aiAnalysis;
  final String? error;

  AdvancedInsightsState({
    this.isLoading = false,
    this.isAiLoading = false,
    this.generalStats,
    this.healthTrends,
    this.treatmentDist,
    this.inventoryLevels,
    this.aiAnalysis,
    this.error,
  });

  AdvancedInsightsState copyWith({
    bool? isLoading,
    bool? isAiLoading,
    Map<String, dynamic>? generalStats,
    List<dynamic>? healthTrends,
    List<dynamic>? treatmentDist,
    List<dynamic>? inventoryLevels,
    Map<String, dynamic>? aiAnalysis,
    String? error,
  }) {
    return AdvancedInsightsState(
      isLoading: isLoading ?? this.isLoading,
      isAiLoading: isAiLoading ?? this.isAiLoading,
      generalStats: generalStats ?? this.generalStats,
      healthTrends: healthTrends ?? this.healthTrends,
      treatmentDist: treatmentDist ?? this.treatmentDist,
      inventoryLevels: inventoryLevels ?? this.inventoryLevels,
      aiAnalysis: aiAnalysis ?? this.aiAnalysis,
      error: error,
    );
  }
}

class InsightsController extends StateNotifier<AdvancedInsightsState> {
  final ApiaryInsightsService _service;

  InsightsController(this._service) : super(AdvancedInsightsState());

  Future<void> refreshAll(String apiaryId) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final results = await Future.wait([
        _service.getGeneralStats(apiaryId),
        _service.getHealthTrends(apiaryId),
        _service.getTreatmentDistribution(apiaryId),
        _service.getInventoryLevels(apiaryId),
      ]);

      state = state.copyWith(
        isLoading: false,
        generalStats: results[0] as Map<String, dynamic>,
        healthTrends: results[1] as List<dynamic>,
        treatmentDist: results[2] as List<dynamic>,
        inventoryLevels: results[3] as List<dynamic>,
      );

      // Disparar IA
      _runAiAnalysis(apiaryId);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> _runAiAnalysis(String apiaryId) async {
    state = state.copyWith(isAiLoading: true);
    try {
      final aiRes = await _service.analyzeWithMaya(
        apiaryId: apiaryId,
        contextData: {
          'stats': state.generalStats,
          'treatments': state.treatmentDist,
          'inventory': state.inventoryLevels,
        },
      );
      state = state.copyWith(isAiLoading: false, aiAnalysis: aiRes);
    } catch (e) {
      state = state.copyWith(isAiLoading: false);
    }
  }
}

final insightsControllerProvider = StateNotifierProvider.autoDispose<InsightsController, AdvancedInsightsState>((ref) {
  return InsightsController(ref.read(apiaryInsightsServiceProvider));
});
