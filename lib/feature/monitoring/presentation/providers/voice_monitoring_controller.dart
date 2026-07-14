import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:audioplayers/audioplayers.dart';
import 'voice_monitoring_state.dart';
import '../../domain/entities/hive_answer.dart';
import '../../domain/entities/hive_question.dart';
import '../../domain/repositories/question_repository.dart';
import '../../domain/repositories/answer_repository.dart';
import '../../../beehive/domain/repositories/beehive_repository.dart';
import '../../../beehive/domain/entities/beehive.dart';
import '../../../../core/services/offline_storage_service.dart';
import 'questions_providers.dart';
import '../../../beehive/presentation/providers/beehive_providers.dart';
import '../../../maya/domain/repositories/maya_repository.dart';
import '../../../maya/presentation/providers/maya_providers.dart';
import '../../domain/entities/question_model.dart';

final offlineStorageServiceProvider = Provider((ref) => OfflineStorageService());

final voiceMonitoringControllerProvider =
    StateNotifierProvider.autoDispose<VoiceMonitoringController, VoiceMonitoringState>((ref) {
  ref.keepAlive();
  final questionRepo = ref.read(questionRepositoryProvider);
  final answerRepo = ref.read(answerRepositoryProvider);
  final beehiveRepo = ref.read(beehiveRepositoryProvider);
  final mayaRepo = ref.read(mayaRepositoryProvider);
  final offlineStorage = ref.read(offlineStorageServiceProvider);
  return VoiceMonitoringController(
    questionRepo: questionRepo,
    answerRepo: answerRepo,
    beehiveRepo: beehiveRepo,
    mayaRepo: mayaRepo,
    offlineStorage: offlineStorage,
  );
});

class VoiceMonitoringController extends StateNotifier<VoiceMonitoringState> {
  final QuestionRepository questionRepo;
  final AnswerRepository answerRepo;
  final BeehiveRepository beehiveRepo;
  final MayaRepository mayaRepo;
  final OfflineStorageService offlineStorage;

  late stt.SpeechToText _speech;
  late FlutterTts _flutterTts;
  late AudioPlayer _audioPlayer;
  bool _speechInitialized = false;
  bool _isSpeaking = false;
  bool _isDisposed = false;
  Timer? _ttsFallbackTimer;
  Timer? _listeningTimer;

  static const int _silenceTimeoutSeconds = 7;

  VoiceMonitoringController({
    required this.questionRepo,
    required this.answerRepo,
    required this.beehiveRepo,
    required this.mayaRepo,
    required this.offlineStorage,
  }) : super(const VoiceMonitoringState()) {
    _speech = stt.SpeechToText();
    _audioPlayer = AudioPlayer();
    _initTts();
  }

  void _initTts() {
    _flutterTts = FlutterTts();
    _flutterTts.setLanguage("es-ES");
    _flutterTts.setPitch(1.1);
    _flutterTts.setSpeechRate(0.5);
    _flutterTts.awaitSpeakCompletion(false);
    
    _flutterTts.setCompletionHandler(() {
      if (_isDisposed) return;
      _isSpeaking = false;
      _handleStepTransition();
    });

    _flutterTts.setErrorHandler((msg) {
      if (_isDisposed) return;
      _isSpeaking = false;
      _handleStepTransition();
    });
  }

  void _handleStepTransition() {
    if (_isDisposed) return;
    _ttsFallbackTimer?.cancel();
    _listeningTimer?.cancel();

    Future.delayed(const Duration(milliseconds: 500), () {
      if (_isDisposed) return;

      switch (state.step) {
        case MonitoringStep.greeting:
          _askForHive();
          break;
        case MonitoringStep.selectHive:
        case MonitoringStep.askingQuestions:
        case MonitoringStep.askContinuation:
          _playBeepAndListen();
          break;
        case MonitoringStep.error:
          // Opcionalmente, reintentar o preguntar algo
          break;
        default:
          break;
      }
    });
  }

  Future<void> _playBeepAndListen() async {
    try {
      // En Web, la ruta a veces requiere el prefijo 'assets/' explícito dependiendo de audioplayers
      await _audioPlayer.play(AssetSource('audio/beep.mp3'));
    } catch (e) {
      debugPrint("Maya Flow: Audio error (ignoring): $e");
    }
    startListening();
  }

  Future<void> initMonitoring(String apiaryId) async {
    if (_isDisposed) return;
    state = state.copyWith(
      step: MonitoringStep.initial,
      availableHives: const [],
      selectedHive: null,
      questions: const [],
      currentQuestionIndex: 0,
      answers: const {},
      lastRecognizedWords: '',
      errorMessage: null,
      isOffline: false,
    );
    
    final hivesResult = await beehiveRepo.getBeehivesByApiary(apiaryId);
    hivesResult.fold(
      (failure) {
        state = state.copyWith(step: MonitoringStep.error, errorMessage: failure.message);
        _speak("Hubo un error al cargar tus colmenas. Por favor revisa tu conexión.");
      },
      (hives) {
        state = state.copyWith(availableHives: hives);
        if (hives.isEmpty) {
          _speak("No tienes colmenas en este apiario. Crea una primero.");
          state = state.copyWith(step: MonitoringStep.finished);
        } else {
          _startGreeting();
        }
      },
    );
  }

  void _startGreeting() {
    state = state.copyWith(step: MonitoringStep.greeting);
    _speak("Hola apicultor. Soy Maya. ¿Con qué colmena quieres iniciar?");
  }

  void _askForHive() {
    state = state.copyWith(step: MonitoringStep.selectHive);
    final hiveNumbers = state.availableHives.map((h) => h.beehiveNumber.toString()).join(", ");
    _speak("Dime el número de la colmena. Las disponibles son: $hiveNumbers.");
  }

  Future<void> _speak(String text) async {
    if (_isDisposed) return;
    if (text.trim().isEmpty) {
      _isSpeaking = false;
      _handleStepTransition();
      return;
    }
    debugPrint("Maya dice: $text");
    _isSpeaking = true;
    
    if (_speech.isListening) await _speech.stop();
    state = state.copyWith(isListening: false);

    _ttsFallbackTimer?.cancel();
    _ttsFallbackTimer = Timer(Duration(milliseconds: (text.length * 100).clamp(3500, 15000)), () {
      if (_isSpeaking && !_isDisposed) {
        _isSpeaking = false;
        _handleStepTransition();
      }
    });

    try {
      unawaited(_flutterTts.speak(text).catchError((e) {
        if (_isDisposed) return;
        _isSpeaking = false;
        _handleStepTransition();
      }));
    } catch (e) {
      _isSpeaking = false;
      _handleStepTransition();
    }
  }

  Future<void> startListening() async {
    if (state.isListening || _isSpeaking || _isDisposed) return;

    if (!_speechInitialized) {
      _speechInitialized = await _speech.initialize(
        onStatus: (val) {
          if (val == 'notListening' || val == 'done') {
            _listeningTimer?.cancel();
            if (!_isDisposed) state = state.copyWith(isListening: false);
          }
        },
        onError: (val) {
          _listeningTimer?.cancel();
          if (!_isDisposed) state = state.copyWith(isListening: false);
        },
      );
    }

    if (_speechInitialized) {
      state = state.copyWith(isListening: true, lastRecognizedWords: "");

      _listeningTimer?.cancel();
      _listeningTimer = Timer(const Duration(seconds: _silenceTimeoutSeconds), () {
        if (_isDisposed) return;
        if (state.isListening && state.lastRecognizedWords.trim().isEmpty) {
          _handleNoAudio();
        }
      });

      await _speech.listen(
        onResult: (val) {
          if (!_isDisposed) {
            state = state.copyWith(lastRecognizedWords: val.recognizedWords);
            if (val.finalResult) {
              _listeningTimer?.cancel();
              stopListening();
              _processInput(val.recognizedWords);
            }
          }
        },
        localeId: "es-ES",
        listenFor: const Duration(seconds: 5),
      );
    }
  }

  void _handleNoAudio() {
    if (_isDisposed) return;
    stopListening();
    _speak("No logré escucharte, intenta nuevamente.");
  }

  void _processInput(String input) {
    final cleaned = input.trim();
    if (cleaned.isEmpty) {
      _handleNoAudio();
      return;
    }
    debugPrint("Usuario dijo: $cleaned");

    if (state.step == MonitoringStep.selectHive) {
      _handleHiveSelection(cleaned.toLowerCase());
    } else if (state.step == MonitoringStep.askingQuestions) {
      _handleAnswer(cleaned.toLowerCase());
    } else if (state.step == MonitoringStep.askContinuation) {
      _handleContinuation(cleaned.toLowerCase());
    }
  }

  void _handleHiveSelection(String input) {
    final number = _extractNumber(input);
    if (number != null) {
      final hive = state.availableHives.firstWhere(
        (h) => h.beehiveNumber == number,
        orElse: () => const Beehive(id: '', apiaryId: ''),
      );

      if (hive.id.isNotEmpty) {
        state = state.copyWith(selectedHive: hive, step: MonitoringStep.loadingQuestions);
        _speak("Colmena $number seleccionada. Cargando preguntas.");
        _loadHiveQuestions(hive.id);
      } else {
        _speak("No encontré la colmena $number. Por favor repítela.");
      }
    } else {
      _speak("No entendí. Dime el número de la colmena.");
    }
  }

  void _loadHiveQuestions(String hiveId) async {
    final result = await mayaRepo.iniciarMonitoreoVoz(hiveId);
    result.fold(
      (failure) {
        if (!_isDisposed) {
          // Limpiar el mensaje de error para los logs
          final cleanError = failure.message.replaceAll('Exception:', '').trim();
          debugPrint("Maya Voz Error Backend: $cleanError");
          
          state = state.copyWith(
            step: MonitoringStep.error, 
            errorMessage: "Error al obtener preguntas"
          );

          // MENSAJE DE VOZ SOLICITADO
          _speak("Hubo un problema al obtener las preguntas. Por favor intenta nuevamente.");
          
          state = state.copyWith(step: MonitoringStep.askContinuation);
        }
      },
      (data) {
        final List<dynamic> pList = data['preguntas'] ?? [];
        final questions = pList.map((p) {
          final String texto = (p['texto'] ?? p['question_text'] ?? p['question'] ?? '').toString().trim();
          if (texto.isEmpty) return null;

          final List<String>? opciones = p['opciones'] != null
              ? List<String>.from(p['opciones'])
                  .map((o) => o.toString().trim())
                  .where((o) => o.isNotEmpty && o != '{}')
                  .toList()
              : null;

          return HiveQuestion(
            id: p['id']?.toString() ?? '',
            hiveId: hiveId,
            apiaryQuestionId: '',
            displayOrder: 0,
            isActive: true,
            apiaryQuestion: Pregunta(
              id: p['id']?.toString() ?? '',
              apiarioId: '',
              texto: texto,
              tipoRespuesta: p['tipo']?.toString() ?? 'texto',
              obligatoria: p['obligatoria'] ?? false,
              orden: 0,
              opciones: opciones,
              min: (p['min'] as num?)?.toInt(),
              max: (p['max'] as num?)?.toInt(),
            ),
          );
        }).whereType<HiveQuestion>().toList();

        debugPrint("Maya Voz: Preguntas recibidas de la DB: ${questions.length}");
        for(var q in questions) {
          debugPrint(" - [${q.apiaryQuestion?.tipoRespuesta}] ${q.apiaryQuestion?.texto}");
        }

        if (questions.isEmpty) {
          debugPrint("Maya Voz: La lista de preguntas está vacía.");
          _speak("No hay preguntas activas para esta colmena en la base de datos. ¿Deseas monitorear otra?");
          state = state.copyWith(step: MonitoringStep.askContinuation);
        } else {
          state = state.copyWith(
            questions: questions,
            currentQuestionIndex: 0,
            step: MonitoringStep.askingQuestions,
            answers: {},
          );
          _askCurrentQuestion();
        }
      },
    );
  }

  void _askCurrentQuestion() {
    int index = state.currentQuestionIndex;
    if (index >= state.questions.length) {
      _finishMonitoring();
      return;
    }

    final q = state.questions[index].apiaryQuestion!;
    String textoVoz = q.texto.trim();

    // Lógica mejorada para leer opciones según el tipo de respuesta
    if (q.tipoRespuesta.toLowerCase() == 'opciones' || q.tipoRespuesta.toLowerCase() == 'seleccion') {
      final opcionesTexto = _formatOptionsForSpeech(q.opciones ?? []);
      if (opcionesTexto.isNotEmpty) {
        textoVoz += ". Las opciones son: $opcionesTexto.";
      }
    } else if (q.tipoRespuesta.toLowerCase() == 'bool' || q.tipoRespuesta.toLowerCase() == 'si_no') {
      textoVoz += ". Las opciones son sí o no.";
    } else if (q.tipoRespuesta.toLowerCase() == 'numero' || q.tipoRespuesta.toLowerCase() == 'cantidad') {
      textoVoz += ". Por favor, dime un número.";
      if (q.min != null && q.max != null) {
        textoVoz += " Entre ${q.min} y ${q.max}.";
      }
    }

    _speak(textoVoz);
  }

  void _handleAnswer(String input) {
    if (state.currentQuestionIndex >= state.questions.length) return;
    
    final question = state.questions[state.currentQuestionIndex];
    final q = question.apiaryQuestion!;
    String processed = input;
    bool valid = true;

    final opciones = q.opciones?.map((o) => o.trim()).where((o) => o.isNotEmpty).toList() ?? [];

    if (q.tipoRespuesta == 'opciones' && opciones.isNotEmpty) {
      final numero = _extractNumber(input);
      if (numero != null && numero > 0 && numero <= opciones.length) {
        processed = opciones[numero - 1];
      } else {
        final match = opciones.firstWhere(
          (o) => input.toLowerCase().contains(o.toLowerCase()),
          orElse: () => "",
        );
        if (match.isNotEmpty) {
          processed = match;
        } else {
          valid = false;
        }
      }
    } else if (q.tipoRespuesta == 'numero') {
      final numero = _extractNumber(input);
      final minOk = q.min == null || (numero != null && numero >= q.min!);
      final maxOk = q.max == null || (numero != null && numero <= q.max!);
      if (numero != null && minOk && maxOk) {
        processed = numero.toString();
      } else {
        valid = false;
      }
    }

    if (!valid) {
      _speak("Respuesta no válida, por favor repítela.");
      return;
    }

    final updatedAnswers = Map<String, String>.from(state.answers)..[question.id] = processed;
    state = state.copyWith(
      answers: updatedAnswers,
      currentQuestionIndex: state.currentQuestionIndex + 1,
    );
    
    _askCurrentQuestion();
  }

  void _finishMonitoring() {
    _saveAllAnswers();
  }

  void _handleContinuation(String input) {
    final lower = input.toLowerCase();
    if (lower.contains("si") || lower.contains("otra") || lower.contains("continuar") || lower.contains("vale")) {
      state = state.copyWith(
        selectedHive: null,
        questions: const [],
        currentQuestionIndex: 0,
        answers: const {},
        lastRecognizedWords: '',
        step: MonitoringStep.selectHive,
      );
      _askForHive();
    } else if (lower.contains("no") || lower.contains("terminar") || lower.contains("fin")) {
      _speak("Entendido. Monitoreo finalizado.");
      state = state.copyWith(step: MonitoringStep.finished);
    } else {
      _speak("No te entendí. ¿Deseas monitorear otra colmena?");
    }
  }

  Future<void> _saveAllAnswers() async {
    if (_isDisposed || state.selectedHive == null) return;
    state = state.copyWith(step: MonitoringStep.saving);
    await _speak("Guardando respuestas.");

    // Mapeo correcto para el backend: el backend usa BatchAnswerItemSchema
    // que requiere: hive_question_id, answer, score (opcional)
    final respuestas = state.answers.entries.map((e) {
      final hiveQuestionId = e.key;
      final valorStr = e.value.toString();
      
      // Intentar calcular un score básico si es bool
      int score = 0;
      if (valorStr.toLowerCase() == 'si' || valorStr.toLowerCase() == 'true') {
        score = 10;
      }

      return {
        'hive_question_id': hiveQuestionId,
        'answer': valorStr,
        'score': score,
      };
    }).toList();

    final result = await mayaRepo.guardarRespuestasVoz(state.selectedHive!.id, respuestas);
    result.fold(
      (failure) async {
        debugPrint("Maya Voz Error al guardar: ${failure.message}");
        await offlineStorage.saveAnswersLocally({
          'hive_id': state.selectedHive?.id,
          'answers': respuestas, // Usamos nombres estándar
          'timestamp': DateTime.now().toIso8601String(),
        });
        if (!_isDisposed) {
          state = state.copyWith(isOffline: true, hasOfflineData: true, step: MonitoringStep.askContinuation);
          await _speak("Hubo un problema al conectar con el servidor. Guardé los datos localmente. ¿Deseas monitorear otra colmena?");
        }
      },
      (success) async {
        if (!_isDisposed) {
          state = state.copyWith(step: MonitoringStep.askContinuation);
          await _speak("Monitoreo guardado exitosamente. ¿Deseas monitorear otra colmena?");
        }
      },
    );
  }

  Future<void> syncOfflineData() async {
    try {
      final offlineData = await offlineStorage.getOfflineAnswers();
      if (offlineData.isEmpty) {
        if (!_isDisposed) state = state.copyWith(hasOfflineData: false);
        return;
      }
      if (!_isDisposed) state = state.copyWith(hasOfflineData: true);
      for (final data in offlineData) {
        final hiveId = data['hive_id'];
        final List<Map<String, dynamic>> respuestas = List<Map<String, dynamic>>.from(data['respuestas']);
        await mayaRepo.guardarRespuestasVoz(hiveId, respuestas);
      }
      await offlineStorage.clearOfflineAnswers();
      if (!_isDisposed) state = state.copyWith(hasOfflineData: false, isOffline: false);
    } catch (_) {
      if (!_isDisposed) state = state.copyWith(hasOfflineData: true);
    }
  }

  String _formatOptionsForSpeech(List<String> options) {
    final cleaned = options.map((o) => o.trim()).where((o) => o.isNotEmpty).toList();
    if (cleaned.isEmpty) return '';
    if (cleaned.length == 1) return cleaned.first;
    if (cleaned.length == 2) return "${cleaned[0]} o ${cleaned[1]}";
    final allButLast = cleaned.sublist(0, cleaned.length - 1).join(", ");
    return "$allButLast o ${cleaned.last}";
  }

  int? _extractNumber(String text) {
    final Map<String, int> words = {
      'uno': 1, 'una': 1, 'primero': 1, 'primera': 1,
      'dos': 2, 'segundo': 2, 'segunda': 2,
      'tres': 3, 'tercero': 3, 'tercera': 3,
      'cuatro': 4, 'cinco': 5, 'diez': 10
    };
    final match = RegExp(r'\d+').firstMatch(text);
    if (match != null) return int.tryParse(match.group(0)!);
    for (var entry in words.entries) {
      if (text.contains(entry.key)) return entry.value;
    }
    return null;
  }

  void stopListening() {
    _listeningTimer?.cancel();
    _speech.stop();
    if (!_isDisposed) state = state.copyWith(isListening: false);
  }

  @override
  void dispose() {
    _isDisposed = true;
    _ttsFallbackTimer?.cancel();
    _listeningTimer?.cancel();
    _flutterTts.stop();
    _speech.stop();
    _audioPlayer.dispose();
    super.dispose();
  }
}
