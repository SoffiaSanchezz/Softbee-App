import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/datasources/question_remote_datasource.dart';
import '../../data/repositories/question_repository_impl.dart';
import '../../domain/entities/question_model.dart';
import '../../domain/repositories/question_repository.dart';
import '../../data/datasources/answer_remote_datasource.dart';
import '../../data/repositories/answer_repository_impl.dart';
import '../../domain/repositories/answer_repository.dart';
import 'questions_controller.dart';
import 'hive_questions_selection_controller.dart';

final questionRemoteDataSourceProvider = Provider<QuestionRemoteDataSource>((
  ref,
) {
  return QuestionRemoteDataSourceImpl(ref.read(dioClientProvider));
});

final questionRepositoryProvider = Provider<QuestionRepository>((ref) {
  return QuestionRepositoryImpl(
    remoteDataSource: ref.read(questionRemoteDataSourceProvider),
    localDataSource: ref.read(authLocalDataSourceProvider),
  );
});

final answerRemoteDataSourceProvider = Provider<AnswerRemoteDataSource>((ref) {
  return AnswerRemoteDataSourceImpl(ref.read(dioClientProvider));
});

final answerRepositoryProvider = Provider<AnswerRepository>((ref) {
  return AnswerRepositoryImpl(
    remoteDataSource: ref.read(answerRemoteDataSourceProvider),
    localDataSource: ref.read(authLocalDataSourceProvider),
  );
});

final questionsControllerProvider =
    StateNotifierProvider.autoDispose<QuestionsController, QuestionsState>((
      ref,
    ) {
      return QuestionsController(ref.read(questionRepositoryProvider));
    });

final hiveQuestionsSelectionProvider =
    StateNotifierProvider.autoDispose.family<HiveQuestionsSelectionController, HiveQuestionsSelectionState, String>((
      ref,
      hiveId,
    ) {
      return HiveQuestionsSelectionController(ref.read(questionRepositoryProvider));
    });

class QuestionsState {
  final bool isLoading;
  final List<Pregunta> preguntas;
  final List<Pregunta> templates;
  final String? error;

  QuestionsState({
    this.isLoading = false,
    this.preguntas = const [],
    this.templates = const [],
    this.error,
  });

  QuestionsState copyWith({
    bool? isLoading,
    List<Pregunta>? preguntas,
    List<Pregunta>? templates,
    String? error,
  }) {
    return QuestionsState(
      isLoading: isLoading ?? this.isLoading,
      preguntas: preguntas ?? this.preguntas,
      templates: templates ?? this.templates,
      error: error,
    );
  }
}
