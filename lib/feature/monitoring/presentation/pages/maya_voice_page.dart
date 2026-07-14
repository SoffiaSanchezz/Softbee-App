import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lottie/lottie.dart';
import '../providers/voice_monitoring_controller.dart';
import '../providers/voice_monitoring_state.dart';

class MayaVoicePage extends ConsumerStatefulWidget {
  final String apiaryId;
  const MayaVoicePage({super.key, required this.apiaryId});

  @override
  ConsumerState<MayaVoicePage> createState() => _MayaVoicePageState();
}

class _MayaVoicePageState extends ConsumerState<MayaVoicePage> {
  @override
  void initState() {
    super.initState();
    // Iniciamos el monitoreo inmediatamente al entrar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(voiceMonitoringControllerProvider.notifier).initMonitoring(widget.apiaryId);
      ref.read(voiceMonitoringControllerProvider.notifier).syncOfflineData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(voiceMonitoringControllerProvider);
    final controller = ref.read(voiceMonitoringControllerProvider.notifier);

    // Mensaje descriptivo del estado actual
    String getStatusInfo() {
      if (state.step == MonitoringStep.error) return "Error: ${state.errorMessage ?? 'verifica la conexión'}";
      if (state.step == MonitoringStep.saving) return "Guardando respuestas...";
      if (state.isListening) return "Maya te está escuchando...";
      if (state.step == MonitoringStep.loadingQuestions) return "Cargando...";
      return "Maya está lista";
    }

    // Texto dinámico que muestra lo que Maya está preguntando o diciendo
    String getMayaText() {
      switch (state.step) {
        case MonitoringStep.greeting:
          return "Iniciando monitoreo...";
        case MonitoringStep.selectHive:
          return "¿Qué colmena deseas monitorear?";
        case MonitoringStep.askingQuestions:
          if (state.questions.isEmpty || state.currentQuestionIndex >= state.questions.length) return "";
          return state.questions[state.currentQuestionIndex].apiaryQuestion?.texto ?? "";
        case MonitoringStep.askContinuation:
          return "¿Quieres monitorear otra colmena o finalizamos el monitoreo?";
        case MonitoringStep.finished:
          return "Monitoreo finalizado";
        default:
          return "";
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F5F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFBC209),
        elevation: 0,
        title: Text(
          'Asistente Maya',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                // --- ANIMACIÓN CENTRAL ---
                _buildCentralAnimation(state.isListening),

                const SizedBox(height: 40),

                // --- BURBUJA DE MAYA ---
                if (getMayaText().isNotEmpty)
                  _buildMessageBubble(getMayaText(), isMaya: true),

                const SizedBox(height: 20),

                // --- LO QUE EL USUARIO DICE (STT) ---
                if (state.lastRecognizedWords.isNotEmpty)
                  _buildMessageBubble(state.lastRecognizedWords, isMaya: false),

                const SizedBox(height: 40),

                // --- ESTADO Y BOTÓN ---
                Text(
                  getStatusInfo(),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: state.step == MonitoringStep.error ? Colors.red : Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),

                const SizedBox(height: 24),

                if (state.step == MonitoringStep.finished)
                  ElevatedButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.check),
                    label: const Text("Finalizar"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFBC209),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                  )
                else
                  _buildMicButton(state.isListening, () {
                    if (state.isListening) {
                      controller.stopListening();
                    } else {
                      controller.startListening();
                    }
                  }),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCentralAnimation(bool isListening) {
    return Container(
      width: 200,
      height: 200,
      child: isListening
          ? Lottie.asset(
              'assets/animations/loader.json', // Ruta corregida
              fit: BoxFit.contain,
            )
          : Container(
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: const Color(0xFFFBC209).withOpacity(0.2), blurRadius: 20, spreadRadius: 5),
                ],
              ),
              child: const Icon(Icons.auto_awesome, size: 80, color: Color(0xFFFBC209)),
            ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 2.seconds),
    );
  }

  Widget _buildMessageBubble(String text, {required bool isMaya}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: isMaya ? Colors.white : const Color(0xFFFBC209),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: isMaya ? FontWeight.normal : FontWeight.w600,
          color: isMaya ? Colors.black87 : Colors.white,
        ),
      ),
    ).animate().fadeIn().slideY(begin: 0.1, end: 0);
  }

  Widget _buildMicButton(bool isListening, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: isListening ? Colors.red : const Color(0xFFFBC209),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: (isListening ? Colors.red : const Color(0xFFFBC209)).withOpacity(0.4), blurRadius: 15, spreadRadius: 2),
          ],
        ),
        child: Icon(
          isListening ? Icons.stop : Icons.mic,
          color: Colors.white,
          size: 40,
        ),
      ).animate(target: isListening ? 1 : 0).scale(begin: const Offset(1, 1), end: const Offset(1.2, 1.2)),
    );
  }
}
