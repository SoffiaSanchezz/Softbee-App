import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../domain/entities/chat_message.dart';
import '../report/maya_report.dart';
import '../report/maya_report_view.dart';

class ChatBubble extends StatelessWidget {
  final ChatMessage message;

  const ChatBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == MessageRole.user;

    // Los informes de Maya (texto largo y estructurado) se muestran como un
    // informe ejecutivo con tarjetas. El contenido no se modifica, solo su
    // presentación. Los mensajes cortos conservan la burbuja de chat.
    if (!isUser && MayaReport.looksLikeReport(message.content)) {
      final report = MayaReport.parse(message.content, message.timestamp);
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        child: MayaReportView(report: report),
      );
    }

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isUser ? const Color(0xFFFBC209) : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 0),
            bottomRight: Radius.circular(isUser ? 0 : 16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isUser)
              Text(
                'Maya',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFFF9800),
                ),
              ),
            Text(
              message.content,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: isUser ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
