import 'package:equatable/equatable.dart';
import '../../domain/entities/hive_question.dart';
import '../../../beehive/domain/entities/beehive.dart';

enum MonitoringStep {
  initial,
  greeting,
  selectHive,
  loadingQuestions,
  askingQuestions,
  saving,
  askContinuation,
  finished,
  error
}

class VoiceMonitoringState extends Equatable {
  final MonitoringStep step;
  final List<Beehive> availableHives;
  final Beehive? selectedHive;
  final List<HiveQuestion> questions;
  final int currentQuestionIndex;
  final Map<String, String> answers; // hiveQuestionId -> answer text
  final bool isListening;
  final String lastRecognizedWords;
  final String? errorMessage;
  final bool isOffline;
  final bool hasOfflineData;

  bool get isLoading => step == MonitoringStep.initial || step == MonitoringStep.loadingQuestions || step == MonitoringStep.saving;

  const VoiceMonitoringState({
    this.step = MonitoringStep.initial,
    this.availableHives = const [],
    this.selectedHive,
    this.questions = const [],
    this.currentQuestionIndex = 0,
    this.answers = const {},
    this.isListening = false,
    this.lastRecognizedWords = '',
    this.errorMessage,
    this.isOffline = false,
    this.hasOfflineData = false,
  });

  VoiceMonitoringState copyWith({
    MonitoringStep? step,
    List<Beehive>? availableHives,
    Beehive? selectedHive,
    List<HiveQuestion>? questions,
    int? currentQuestionIndex,
    Map<String, String>? answers,
    bool? isListening,
    String? lastRecognizedWords,
    String? errorMessage,
    bool? isOffline,
    bool? hasOfflineData,
  }) {
    return VoiceMonitoringState(
      step: step ?? this.step,
      availableHives: availableHives ?? this.availableHives,
      selectedHive: selectedHive ?? this.selectedHive,
      questions: questions ?? this.questions,
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      answers: answers ?? this.answers,
      isListening: isListening ?? this.isListening,
      lastRecognizedWords: lastRecognizedWords ?? this.lastRecognizedWords,
      errorMessage: errorMessage,
      isOffline: isOffline ?? this.isOffline,
      hasOfflineData: hasOfflineData ?? this.hasOfflineData,
    );
  }

  @override
  List<Object?> get props => [
        step,
        availableHives,
        selectedHive,
        questions,
        currentQuestionIndex,
        answers,
        isListening,
        lastRecognizedWords,
        errorMessage,
        isOffline,
        hasOfflineData,
      ];
}
