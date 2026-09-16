import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../../domain/entities/question_model.dart';
import '../../domain/entities/hive_question.dart';

abstract class QuestionLocalDataSource {
  // Preguntas del apiario
  Future<void> cachePreguntas(String apiaryId, List<Pregunta> preguntas);
  Future<List<Pregunta>> getCachedPreguntas(String apiaryId);

  // CRUD local de preguntas del apiario (para operar offline)
  Future<void> savePregunta(String apiaryId, Pregunta pregunta);
  Future<void> updateLocalPregunta(String apiaryId, Pregunta pregunta);
  Future<void> deleteLocalPregunta(String apiaryId, String preguntaId);
  Future<void> replacePreguntaId(String apiaryId, String tempId, Pregunta real);

  // Preguntas asignadas a colmenas
  Future<void> cacheHiveQuestions(String hiveId, List<HiveQuestion> questions);
  Future<List<HiveQuestion>> getCachedHiveQuestions(String hiveId);

  // Templates / banco de preguntas
  Future<void> cacheTemplates(List<Pregunta> templates);
  Future<List<Pregunta>> getCachedTemplates();

  Future<void> clearCache();
}

class QuestionLocalDataSourceImpl implements QuestionLocalDataSource {
  static const String _boxName = 'question_box';

  Future<Box> _openBox() async {
    return await Hive.openBox(_boxName);
  }

  String _keyForApiaryQuestions(String apiaryId) => 'preguntas_$apiaryId';
  String _keyForHiveQuestions(String hiveId) => 'hive_questions_$hiveId';
  static const String _templatesKey = 'question_templates';

  // ===================== PREGUNTAS DEL APIARIO =====================

  @override
  Future<void> cachePreguntas(String apiaryId, List<Pregunta> preguntas) async {
    final box = await _openBox();
    final List<String> jsonList =
        preguntas.map((p) => json.encode(p.toJson())).toList();
    await box.put(_keyForApiaryQuestions(apiaryId), jsonList);
  }

  @override
  Future<List<Pregunta>> getCachedPreguntas(String apiaryId) async {
    final box = await _openBox();
    final List<dynamic>? jsonList = box.get(_keyForApiaryQuestions(apiaryId));

    if (jsonList != null) {
      return jsonList
          .map((item) => Pregunta.fromJson(json.decode(item as String)))
          .toList();
    }
    return [];
  }

  // ===================== CRUD LOCAL DE PREGUNTAS =====================

  @override
  Future<void> savePregunta(String apiaryId, Pregunta pregunta) async {
    final preguntas = await getCachedPreguntas(apiaryId);
    preguntas.add(pregunta);
    await cachePreguntas(apiaryId, preguntas);
  }

  @override
  Future<void> updateLocalPregunta(String apiaryId, Pregunta pregunta) async {
    final preguntas = await getCachedPreguntas(apiaryId);
    final index = preguntas.indexWhere((p) => p.id == pregunta.id);
    if (index != -1) {
      preguntas[index] = pregunta;
    } else {
      preguntas.add(pregunta);
    }
    await cachePreguntas(apiaryId, preguntas);
  }

  @override
  Future<void> deleteLocalPregunta(String apiaryId, String preguntaId) async {
    final preguntas = await getCachedPreguntas(apiaryId);
    preguntas.removeWhere((p) => p.id == preguntaId);
    await cachePreguntas(apiaryId, preguntas);
  }

  @override
  Future<void> replacePreguntaId(
    String apiaryId,
    String tempId,
    Pregunta real,
  ) async {
    final preguntas = await getCachedPreguntas(apiaryId);
    final index = preguntas.indexWhere((p) => p.id == tempId);
    if (index != -1) {
      preguntas[index] = real;
      await cachePreguntas(apiaryId, preguntas);
    }
  }

  // ===================== PREGUNTAS DE COLMENA =====================

  @override
  Future<void> cacheHiveQuestions(String hiveId, List<HiveQuestion> questions) async {
    final box = await _openBox();
    final List<String> jsonList =
        questions.map((q) => json.encode(q.toJson())).toList();
    await box.put(_keyForHiveQuestions(hiveId), jsonList);
  }

  @override
  Future<List<HiveQuestion>> getCachedHiveQuestions(String hiveId) async {
    final box = await _openBox();
    final List<dynamic>? jsonList = box.get(_keyForHiveQuestions(hiveId));

    if (jsonList != null) {
      return jsonList
          .map((item) => HiveQuestion.fromJson(json.decode(item as String)))
          .toList();
    }
    return [];
  }

  // ===================== TEMPLATES =====================

  @override
  Future<void> cacheTemplates(List<Pregunta> templates) async {
    final box = await _openBox();
    final List<String> jsonList =
        templates.map((t) => json.encode(t.toJson())).toList();
    await box.put(_templatesKey, jsonList);
  }

  @override
  Future<List<Pregunta>> getCachedTemplates() async {
    final box = await _openBox();
    final List<dynamic>? jsonList = box.get(_templatesKey);

    if (jsonList != null) {
      return jsonList
          .map((item) => Pregunta.fromJson(json.decode(item as String)))
          .toList();
    }
    return [];
  }

  // ===================== CLEAR =====================

  @override
  Future<void> clearCache() async {
    final box = await _openBox();
    await box.clear();
  }
}
