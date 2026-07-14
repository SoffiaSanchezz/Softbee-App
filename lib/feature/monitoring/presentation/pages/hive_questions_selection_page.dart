import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/questions_providers.dart';
import '../providers/hive_questions_selection_controller.dart';

class HiveQuestionsSelectionPage extends ConsumerStatefulWidget {
  final String apiaryId;
  final String hiveId;
  final int hiveNumber;

  const HiveQuestionsSelectionPage({
    super.key,
    required this.apiaryId,
    required this.hiveId,
    required this.hiveNumber,
  });

  @override
  ConsumerState<HiveQuestionsSelectionPage> createState() => _HiveQuestionsSelectionPageState();
}

class _HiveQuestionsSelectionPageState extends ConsumerState<HiveQuestionsSelectionPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(hiveQuestionsSelectionProvider(widget.hiveId).notifier).load(
        widget.apiaryId,
        widget.hiveId,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(hiveQuestionsSelectionProvider(widget.hiveId));
    final controller = ref.read(hiveQuestionsSelectionProvider(widget.hiveId).notifier);

    // Colores del tema Softbee
    const Color colorAmarillo = Color(0xFFFBC209);
    const Color colorNaranja = Color(0xFFFF9800);
    const Color colorAmbarClaro = Color(0xFFFFF8E1);
    const Color colorVerde = Color(0xFF4CAF50);

    // Escuchar errores
    ref.listen(hiveQuestionsSelectionProvider(widget.hiveId), (prev, next) {
      if (next.error != null && next.error != prev?.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error!), backgroundColor: Colors.red),
        );
        controller.clearError();
      }
    });

    final bool allSelected = state.selections.isNotEmpty && 
                             state.selections.every((s) => s.isSelected);

    return Scaffold(
      backgroundColor: colorAmbarClaro,
      appBar: AppBar(
        backgroundColor: colorAmarillo,
        elevation: 0,
        title: Text(
          'Preguntas: Colmena ${widget.hiveNumber}',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator(color: colorNaranja))
          : Column(
              children: [
                // Info y Seleccionar Todo
                _buildHeader(allSelected, controller, colorNaranja, state.isProcessing),
                
                // Lista de preguntas
                Expanded(
                  child: state.selections.isEmpty
                      ? _buildEmptyState(colorNaranja)
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: state.selections.length,
                          itemBuilder: (context, index) {
                            final selection = state.selections[index];
                            return _buildQuestionTile(selection, controller, colorVerde, state.isProcessing);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildHeader(bool allSelected, HiveQuestionsSelectionController controller, Color color, bool isProcessing) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.fact_check_rounded, color: color, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Configuración Personalizada',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    Text(
                      'Elige las preguntas para esta colmena',
                      style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          CheckboxListTile(
            title: Text(
              'Seleccionar todas las preguntas',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            subtitle: Text(
              'Aplica el banco completo del apiario',
              style: GoogleFonts.poppins(fontSize: 11),
            ),
            value: allSelected,
            activeColor: color,
            onChanged: isProcessing ? null : (val) => controller.selectAll(widget.hiveId, val ?? false),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.1, end: 0);
  }

  Widget _buildQuestionTile(HiveQuestionSelection selection, HiveQuestionsSelectionController controller, Color color, bool isProcessing) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1,
      child: CheckboxListTile(
        title: Text(
          selection.pregunta.texto,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w500,
            fontSize: 14,
            color: selection.isSelected ? Colors.black87 : Colors.black54,
          ),
        ),
        subtitle: Row(
          children: [
            Icon(Icons.category_outlined, size: 12, color: Colors.grey[400]),
            const SizedBox(width: 4),
            Text(
              selection.pregunta.categoria ?? 'General',
              style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[500]),
            ),
            const SizedBox(width: 12),
            Icon(Icons.input_rounded, size: 12, color: Colors.grey[400]),
            const SizedBox(width: 4),
            Text(
              selection.pregunta.tipoRespuesta,
              style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[500]),
            ),
          ],
        ),
        value: selection.isSelected,
        activeColor: color,
        onChanged: isProcessing ? null : (_) => controller.toggleQuestion(widget.hiveId, selection),
      ),
    );
  }

  Widget _buildEmptyState(Color color) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.quiz_outlined, size: 64, color: color.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text(
            'No hay preguntas en el banco del apiario',
            style: GoogleFonts.poppins(color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Ve a la gestión del apiario para agregar preguntas',
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }
}
