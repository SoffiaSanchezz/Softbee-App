import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/question_model.dart';
import '../../domain/entities/hive_question.dart';
import '../../domain/repositories/question_repository.dart';

class HiveQuestionSelection {
  final Pregunta pregunta;
  final bool isSelected;
  final bool isInherited; // Si viene activa del banco del apiario
  final String? hiveQuestionId;

  HiveQuestionSelection({
    required this.pregunta,
    required this.isSelected,
    this.isInherited = false,
    this.hiveQuestionId,
  });

  HiveQuestionSelection copyWith({
    Pregunta? pregunta,
    bool? isSelected,
    bool? isInherited,
    String? hiveQuestionId,
  }) {
    return HiveQuestionSelection(
      pregunta: pregunta ?? this.pregunta,
      isSelected: isSelected ?? this.isSelected,
      isInherited: isInherited ?? this.isInherited,
      hiveQuestionId: hiveQuestionId ?? this.hiveQuestionId,
    );
  }
}

class HiveQuestionsSelectionState {
  final List<HiveQuestionSelection> selections;
  final bool isLoading;
  final bool isProcessing;
  final String? error;

  HiveQuestionsSelectionState({
    this.selections = const [],
    this.isLoading = false,
    this.isProcessing = false,
    this.error,
  });

  HiveQuestionsSelectionState copyWith({
    List<HiveQuestionSelection>? selections,
    bool? isLoading,
    bool? isProcessing,
    String? error,
  }) {
    return HiveQuestionsSelectionState(
      selections: selections ?? this.selections,
      isLoading: isLoading ?? this.isLoading,
      isProcessing: isProcessing ?? this.isProcessing,
      error: error,
    );
  }
}

class HiveQuestionsSelectionController extends StateNotifier<HiveQuestionsSelectionState> {
  final QuestionRepository _repository;
  bool _mounted = true;

  HiveQuestionsSelectionController(this._repository) : super(HiveQuestionsSelectionState());

  @override
  void dispose() {
    _mounted = false;
    super.dispose();
  }

  Future<void> load(String apiaryId, String hiveId) async {
    state = state.copyWith(isLoading: true, error: null);
    
    final results = await Future.wait([
      _repository.getPreguntas(apiaryId),
      _repository.getHiveQuestions(hiveId),
    ]);

    if (!_mounted) return;

    final bankResult = results[0];
    final assignedResult = results[1];

    if (bankResult.isLeft) {
      state = state.copyWith(isLoading: false, error: bankResult.left.message);
      return;
    }
    if (assignedResult.isLeft) {
      state = state.copyWith(isLoading: false, error: assignedResult.left.message);
      return;
    }

    final bank = bankResult.right as List<Pregunta>;
    final assigned = assignedResult.right as List<HiveQuestion>;

    final selections = bank.map((p) {
      final match = assigned.where((a) => a.apiaryQuestionId == p.id);
      final bool isInherited = p.activa; 
      
      return HiveQuestionSelection(
        pregunta: p,
        isInherited: isInherited,
        isSelected: isInherited || match.isNotEmpty,
        hiveQuestionId: match.isNotEmpty ? match.first.id : null,
      );
    }).toList();
    
    if (_mounted) {
      state = state.copyWith(isLoading: false, selections: selections);
    }
  }

  Future<void> toggleQuestion(String hiveId, HiveQuestionSelection selection) async {
    state = state.copyWith(isProcessing: true, error: null);
    
    try {
      if (selection.isSelected) {
        // Queremos DESACTIVAR/DESASIGNAR
        if (selection.hiveQuestionId != null) {
          final result = await _repository.unassignQuestionFromHive(selection.hiveQuestionId!);
          if (!_mounted) return;
          if (result.isRight) {
            _updateLocalSelection(selection.pregunta.id, false, null);
          } else {
            state = state.copyWith(isProcessing: false, error: result.left.message);
          }
        } else {
          // Si no tiene hiveQuestionId pero está seleccionada (porque p.activa era true),
          // para "desactivarla" en este hive necesitamos que el backend soporte una relación inactiva
          // o simplemente ignoramos este caso si el backend no permite relaciones explicitamente inactivas.
          // Por ahora, si no hay ID, no podemos desasignar algo que no existe físicamente como relación.
          state = state.copyWith(isProcessing: false);
        }
      } else {
        // Queremos ACTIVAR/ASIGNAR
        final result = await _repository.assignQuestionToHive(
          hiveId, 
          selection.pregunta.id, 
          selection.pregunta.orden
        );
        if (!_mounted) return;
        if (result.isRight) {
          _updateLocalSelection(selection.pregunta.id, true, result.right.id);
        } else {
          state = state.copyWith(isProcessing: false, error: result.left.message);
        }
      }
    } catch (e) {
      if (_mounted) state = state.copyWith(error: e.toString());
    } finally {
      if (_mounted) state = state.copyWith(isProcessing: false);
    }
  }

  Future<void> selectAll(String hiveId, bool select) async {
    state = state.copyWith(isProcessing: true, error: null);
    
    try {
      if (select) {
        final toAssign = state.selections.where((s) => !s.isInherited && !s.isSelected).toList();
        for (var s in toAssign) {
          final result = await _repository.assignQuestionToHive(hiveId, s.pregunta.id, s.pregunta.orden);
          if (!_mounted) return;
          if (result.isRight) {
            _updateLocalSelection(s.pregunta.id, true, result.right.id);
          }
        }
      } else {
        final toUnassign = state.selections.where((s) => !s.isInherited && s.isSelected).toList();
        for (var s in toUnassign) {
          final result = await _repository.unassignQuestionFromHive(s.hiveQuestionId!);
          if (!_mounted) return;
          if (result.isRight) {
            _updateLocalSelection(s.pregunta.id, false, null);
          }
        }
      }
    } catch (e) {
      if (_mounted) state = state.copyWith(error: e.toString());
    } finally {
      if (_mounted) state = state.copyWith(isProcessing: false);
    }
  }

  void _updateLocalSelection(String preguntaId, bool isSelected, String? hiveQuestionId) {
    if (!_mounted) return;
    final newList = state.selections.map((s) {
      if (s.pregunta.id == preguntaId) {
        return s.copyWith(
          isSelected: isSelected,
          hiveQuestionId: hiveQuestionId,
        );
      }
      return s;
    }).toList();
    state = state.copyWith(selections: newList);
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}
