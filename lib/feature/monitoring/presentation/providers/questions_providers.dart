import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/datasources/question_remote_datasource.dart';
import '../../data/repositories/question_repository_impl.dart';
import '../../domain/entities/question_model.dart';
import '../../domain/repositories/question_repository.dart';
import 'questions_controller.dart';

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

final questionsControllerProvider =
    StateNotifierProvider.autoDispose<QuestionsController, QuestionsState>((
      ref,
    ) {
      return QuestionsController(ref.read(questionRepositoryProvider));
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
