import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/question_model.dart';
import '../../domain/repositories/question_repository.dart';
import 'questions_providers.dart';

class QuestionsController extends StateNotifier<QuestionsState> {
  final QuestionRepository _repository;

  QuestionsController(this._repository) : super(QuestionsState());

  Future<void> fetchPreguntas(String apiaryId) async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _repository.getPreguntas(apiaryId);
    result.fold(
      (failure) =>
          state = state.copyWith(isLoading: false, error: failure.message),
      (preguntas) =>
          state = state.copyWith(isLoading: false, preguntas: preguntas),
    );
  }

  Future<void> createPregunta(Pregunta pregunta) async {
    final result = await _repository.createPregunta(pregunta);
    result.fold(
      (failure) => state = state.copyWith(error: failure.message),
      (_) => fetchPreguntas(pregunta.apiarioId),
    );
  }

  Future<void> updatePregunta(Pregunta pregunta) async {
    final result = await _repository.updatePregunta(pregunta);
    result.fold(
      (failure) => state = state.copyWith(error: failure.message),
      (_) => fetchPreguntas(pregunta.apiarioId),
    );
  }

  Future<void> deletePregunta(String id, String apiaryId) async {
    final result = await _repository.deletePregunta(id);
    result.fold(
      (failure) => state = state.copyWith(error: failure.message),
      (_) => fetchPreguntas(apiaryId),
    );
  }

  Future<void> reorderPreguntas(String apiaryId, List<String> order) async {
    final result = await _repository.reorderPreguntas(apiaryId, order);
    result.fold(
      (failure) => state = state.copyWith(error: failure.message),
      (_) => fetchPreguntas(apiaryId),
    );
  }

  Future<void> loadDefaults(String apiaryId) async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _repository.loadDefaults(apiaryId);
    result.fold(
      (failure) =>
          state = state.copyWith(isLoading: false, error: failure.message),
      (_) => fetchPreguntas(apiaryId),
    );
  }

  Future<void> fetchTemplates() async {
    final result = await _repository.getTemplates();
    result.fold((failure) {
      // No sobrescribimos el error principal para no bloquear la vista del apiario
      print('Error cargando plantillas: ${failure.message}');
    }, (templates) => state = state.copyWith(templates: templates));
  }
}
