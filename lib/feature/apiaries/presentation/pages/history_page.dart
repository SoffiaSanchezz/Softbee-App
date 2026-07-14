import 'package:flutter/material.dart';

import 'package:Softbee/core/router/app_routes.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class HistoryPage extends StatelessWidget {
  final String apiaryId;
  const HistoryPage({super.key, required this.apiaryId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Historial del Apiario', style: GoogleFonts.poppins(fontWeight: FontWeight.bold))),
      body: Center(
        child: Text('Página de Historial para Apiario ID: $apiaryId', style: GoogleFonts.poppins()),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            FloatingActionButton.extended(
              heroTag: 'mayaVoiceHistory',
              onPressed: () {
                context.pushNamed(
                  AppRoutes.mayaVoiceRoute,
                  pathParameters: {'apiaryId': apiaryId},
                );
              },
              backgroundColor: const Color(0xFFFBC209),
              icon: const Icon(Icons.mic, color: Colors.white),
              label: Text('Maya Voz', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white)),
            ),
            FloatingActionButton.extended(
              heroTag: 'mayaChatHistory',
              onPressed: () {
                context.pushNamed(
                  AppRoutes.mayaChatRoute,
                  pathParameters: {'apiaryId': apiaryId},
                );
              },
              backgroundColor: const Color(0xFFFBC209),
              icon: const Icon(Icons.auto_awesome, color: Colors.white),
              label: Text('Maya Bot', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
