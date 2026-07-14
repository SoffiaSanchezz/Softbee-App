import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lottie/lottie.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';
import '../providers/maya_providers.dart';
import '../widgets/chat_bubble.dart';
import '../../domain/entities/chat_message.dart';

class MayaChatPage extends ConsumerStatefulWidget {
  final String apiaryId;
  const MayaChatPage({super.key, required this.apiaryId});

  @override
  ConsumerState<MayaChatPage> createState() => _MayaChatPageState();
}

class _MayaChatPageState extends ConsumerState<MayaChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  late stt.SpeechToText _speech;
  bool _isListening = false;
  late FlutterTts _flutterTts;
  bool _isTtsEnabled = true;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _initTts();
  }

  void _initTts() {
    _flutterTts = FlutterTts();
    _flutterTts.setLanguage("es-ES");
    _flutterTts.setPitch(1.0);
    _flutterTts.setSpeechRate(0.5);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _flutterTts.stop();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _speak(String text) async {
    if (_isTtsEnabled) {
      await _flutterTts.speak(text);
    }
  }

  Future<void> _listen() async {
    if (!_isListening) {
      if (!kIsWeb) {
        // Solicitar permiso de micrófono explícitamente solo en plataformas nativas
        var status = await Permission.microphone.status;
        if (status.isDenied) {
          status = await Permission.microphone.request();
          if (!status.isGranted) return;
        }
      }

      bool available = await _speech.initialize(
        onStatus: (val) {
          if (val == 'done' || val == 'notListening') {
            if (mounted) setState(() => _isListening = false);
          }
        },
        onError: (val) {
          if (mounted) setState(() => _isListening = false);
        },
      );
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (val) => setState(() {
            _messageController.text = val.recognizedWords;
            if (val.finalResult) {
              _isListening = false;
              _handleSend();
            }
          }),
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final mayaState = ref.watch(mayaControllerProvider);
    
    // Auto-scroll al recibir mensajes y hablar si es necesario
    ref.listen(mayaControllerProvider, (previous, next) {
      if (next.messages.length > (previous?.messages.length ?? 0)) {
        _scrollToBottom();
        
        final lastMessage = next.messages.last;
        if (lastMessage.role == MessageRole.assistant) {
          _speak(lastMessage.content);
        }
      }
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error!)),
        );
        ref.read(mayaControllerProvider.notifier).clearError();
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF8F5F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFBC209),
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Colors.white24,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Text(
              'Maya Bot',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isTtsEnabled ? Icons.volume_up : Icons.volume_off,
              color: Colors.white,
            ),
            onPressed: () => setState(() => _isTtsEnabled = !_isTtsEnabled),
          ),
        ],
      ),
      body: Column(
        children: [
          // Área de Chat
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(vertical: 16),
              itemCount: mayaState.messages.length,
              itemBuilder: (context, index) {
                final message = mayaState.messages[index];
                return ChatBubble(message: message)
                    .animate()
                    .fadeIn(duration: 400.ms)
                    .slideY(begin: 0.1, end: 0);
              },
            ),
          ),

          // Indicador de Carga / "Escribiendo..."
          if (mayaState.isLoading)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  Lottie.asset(
                    'assets/animations/loader.json',
                    width: 40,
                    height: 40,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Maya está pensando...',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),

          // Input de Mensaje
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            GestureDetector(
              onTap: _listen,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _isListening ? Colors.red : const Color(0xFFFBC209),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _isListening ? Icons.stop : Icons.mic,
                  color: Colors.white,
                ),
              ),
            ).animate(target: _isListening ? 1 : 0).scale(begin: const Offset(1, 1), end: const Offset(1.2, 1.2)),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F5F0),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _messageController,
                  decoration: InputDecoration(
                    hintText: _isListening ? 'Escuchando...' : 'Pregúntale algo a Maya...',
                    hintStyle: GoogleFonts.poppins(color: Colors.grey),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                  ),
                  onSubmitted: (value) => _handleSend(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: _handleSend,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: Color(0xFFFF9800),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.send_rounded, color: Colors.white),
              ),
            ).animate().scale(),
          ],
        ),
      ),
    );
  }

  void _handleSend() {
    final text = _messageController.text;
    if (text.isNotEmpty) {
      ref.read(mayaControllerProvider.notifier).sendMessage(
        text,
        context: {'apiary_id': widget.apiaryId},
      );
      _messageController.clear();
    }
  }
}
