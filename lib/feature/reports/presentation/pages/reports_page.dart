import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../providers/reports_provider.dart';
import '../../domain/entities/monitoring_report.dart';

// Constantes de diseño para el módulo de informes
const Color _primaryColor = Color(0xFFF5A623);
const Color _backgroundLight = Color(0xFFF8F5F0);
const Color _textPrimary = Color(0xFF2D2D2D);

class ReportsPage extends ConsumerWidget {
  final String hiveId;
  final String hiveNumber;

  const ReportsPage({
    super.key,
    required this.hiveId,
    required this.hiveNumber,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(reportsProvider(hiveId));
    final isDesktop = MediaQuery.of(context).size.width > 1024;

    return Scaffold(
      backgroundColor: _backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: isDesktop
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _textPrimary),
                onPressed: () => Navigator.of(context).pop(),
              ),
        title: isDesktop
            ? Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1400),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _textPrimary),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Informes - Colmena $hiveNumber',
                        style: GoogleFonts.poppins(
                          color: _textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : Text(
                'Informes - Colmena $hiveNumber',
                style: GoogleFonts.poppins(
                  color: _textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator(color: _primaryColor))
          : state.error != null
              ? Center(child: Text('Error: ${state.error}'))
              : state.reports.isEmpty
                  ? _buildEmptyState()
                  : isDesktop
                      ? Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 1400),
                            child: GridView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                                maxCrossAxisExtent: 440,
                                mainAxisExtent: 176,
                                crossAxisSpacing: 20,
                                mainAxisSpacing: 20,
                              ),
                              itemCount: state.reports.length,
                              itemBuilder: (context, index) {
                                final report = state.reports[index];
                                return _buildReportCardDesktop(context, report);
                              },
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: state.reports.length,
                          itemBuilder: (context, index) {
                            final report = state.reports[index];
                            return _buildReportCard(context, report);
                          },
                        ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.description_outlined, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            'No hay informes generados aún.',
            style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  // Card rediseñada para Desktop: jerarquía visual clara, badge de puntaje,
  // divisor e indicadores. Conserva colores, tipografía e identidad de la app.
  Widget _buildReportCardDesktop(BuildContext context, MonitoringReport report) {
    final dateStr = DateFormat('dd/MM/yyyy').format(report.timestamp);
    final timeStr = DateFormat('HH:mm').format(report.timestamp);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showReportDetail(context, report),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _primaryColor.withOpacity(0.12)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Encabezado: icono + título/fecha + badge de puntaje ---
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: _primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.assignment_turned_in_rounded,
                      color: _primaryColor,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Monitoreo',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: _textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          dateStr,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Badge de puntaje
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: _primaryColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Puntaje',
                          style: GoogleFonts.poppins(
                            fontSize: 9,
                            fontWeight: FontWeight.w500,
                            color: _primaryColor,
                          ),
                        ),
                        Text(
                          '${report.totalScore}',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: _primaryColor,
                            height: 1.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Divider(height: 1, color: Colors.grey[200]),
              const SizedBox(height: 12),
              // --- Indicadores: hora, respuestas y llamada a la acción ---
              Row(
                children: [
                  // Los chips ocupan el espacio disponible y se adaptan sin
                  // desbordar; el CTA "Ver detalle" permanece fijo a la derecha.
                  Expanded(
                    child: Row(
                      children: [
                        Flexible(
                          child: _buildReportIndicator(
                            Icons.schedule_rounded,
                            timeStr,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: _buildReportIndicator(
                            Icons.question_answer_rounded,
                            '${report.answers.length} respuestas',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Ver detalle',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _primaryColor,
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    size: 15,
                    color: _primaryColor,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Pequeño indicador (icono + texto) para el pie de la card de escritorio.
  Widget _buildReportIndicator(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey[600]),
          const SizedBox(width: 6),
          // Flexible + ellipsis como red de seguridad: en anchos normales se
          // muestra completo; solo se recorta en casos extremos para no
          // desbordar. No se reduce el tamaño de fuente.
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              softWrap: false,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard(BuildContext context, MonitoringReport report) {
    final isDesktop = MediaQuery.of(context).size.width > 1024;
    final dateStr = DateFormat('dd/MM/yyyy').format(report.timestamp);
    final timeStr = DateFormat('HH:mm').format(report.timestamp);

    return Container(
      margin: isDesktop ? EdgeInsets.zero : const EdgeInsets.only(bottom: 16),
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
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: _primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.assignment_turned_in_rounded, color: _primaryColor),
        ),
        title: Text(
          'Monitoreo del $dateStr',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: _textPrimary,
          ),
        ),
        subtitle: Text(
          'Hora: $timeStr - ${report.answers.length} respuestas',
          style: GoogleFonts.poppins(color: Colors.grey),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'Puntaje',
              style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey),
            ),
            Text(
              '${report.totalScore}',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: _primaryColor,
              ),
            ),
          ],
        ),
        onTap: () => _showReportDetail(context, report),
      ),
    );
  }

  void _showReportDetail(BuildContext context, MonitoringReport report) {
    final isDesktop = MediaQuery.of(context).size.width > 1024;
    if (isDesktop) {
      final screenSize = MediaQuery.of(context).size;
      showDialog(
        context: context,
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 960,
              maxHeight: screenSize.height * 0.85,
            ),
            child: _ReportDetailBottomSheet(report: report, isDesktop: true),
          ),
        ),
      );
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => _ReportDetailBottomSheet(report: report, isDesktop: false),
      );
    }
  }
}

class _ReportDetailBottomSheet extends StatelessWidget {
  final MonitoringReport report;
  final bool isDesktop;

  const _ReportDetailBottomSheet({
    required this.report,
    required this.isDesktop,
  });

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('dd/MM/yyyy HH:mm').format(report.timestamp);

    return Container(
      height: isDesktop ? double.infinity : MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: isDesktop
            ? BorderRadius.circular(24)
            : const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          if (!isDesktop)
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Detalle del Informe',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        dateStr,
                        style: GoogleFonts.poppins(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _primaryColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Score: ${report.totalScore}',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (isDesktop) ...[
                      const SizedBox(width: 12),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: _textPrimary),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: isDesktop
                // Desktop: respuestas en 2 columnas para aprovechar el ancho.
                ? LayoutBuilder(
                    builder: (context, constraints) {
                      const double spacing = 20.0;
                      final double itemWidth =
                          (constraints.maxWidth - 48 - spacing) / 2;
                      return SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Wrap(
                          spacing: spacing,
                          runSpacing: spacing,
                          children: List.generate(report.answers.length, (index) {
                            return SizedBox(
                              width: itemWidth,
                              child: _buildAnswerItem(index),
                            );
                          }),
                        ),
                      );
                    },
                  )
                // Móvil: comportamiento original en una columna.
                : ListView.separated(
                    padding: const EdgeInsets.all(24),
                    itemCount: report.answers.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 20),
                    itemBuilder: (context, index) => _buildAnswerItem(index),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerItem(int index) {
    final ans = report.answers[index];
    // Intentamos obtener el texto de la pregunta de la relación apiaryQuestion
    final preguntaTexto =
        ans.hiveQuestion?.apiaryQuestion?.texto ?? 'Pregunta #${index + 1}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          preguntaTexto,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Row(
            children: [
              const Icon(Icons.chat_bubble_outline_rounded, size: 16, color: _primaryColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  ans.answer,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
              ),
              if (ans.score != null && ans.score != 0)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '+${ans.score}',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Colors.green[700],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
