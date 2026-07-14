import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'maya_report.dart';

/// Vista de informe ejecutivo para los reportes generados por Maya.
/// Solo transforma la presentación del texto; no altera su contenido.
class MayaReportView extends StatelessWidget {
  final MayaReport report;

  /// Permiten reutilizar solo las secciones (p. ej. dentro de otro dashboard
  /// que ya muestra su propio encabezado y KPIs).
  final bool showHeader;
  final bool showIndicators;

  const MayaReportView({
    super.key,
    required this.report,
    this.showHeader = true,
    this.showIndicators = true,
  });

  static const Color _amber = Color(0xFFF5A623);
  static const Color _textDark = Color(0xFF2D2D2D);

  @override
  Widget build(BuildContext context) {
    final sections = report.sections;

    final widgets = <Widget>[
      if (showHeader) _buildHeader(),
      if (showIndicators && report.indicators.isNotEmpty) ...[
        const SizedBox(height: 14),
        _buildIndicators(context),
      ],
    ];

    int delay = 0;
    for (final section in sections) {
      if (section.type == SectionType.summary) continue; // ya está en el header
      widgets.add(const SizedBox(height: 14));
      widgets.add(_buildSection(section));
    }

    // Animación escalonada de entrada.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final w in widgets)
          w
              .animate()
              .fadeIn(duration: 350.ms, delay: (delay += 60).ms)
              .slideY(begin: 0.08, end: 0, curve: Curves.easeOut),
      ],
    );
  }

  // ---------------- Header ----------------
  Widget _buildHeader() {
    final status = report.status;
    final date = report.generatedAt;
    final dateStr =
        '${_two(date.day)}/${_two(date.month)}/${date.year} · ${_two(date.hour)}:${_two(date.minute)}';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF3D6), Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _amber.withOpacity(0.25)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _amber.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.auto_awesome_rounded, color: _amber),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      report.title,
                      style: GoogleFonts.poppins(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: _textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.schedule_rounded,
                            size: 13, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Text(
                          dateStr,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              _statusBadge(status),
            ],
          ),
          if (report.summary.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              report.summary,
              style: GoogleFonts.poppins(
                fontSize: 13.5,
                height: 1.5,
                color: Colors.grey[800],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _statusBadge(ReportStatus status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: status.color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: status.color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(status.icon, size: 15, color: status.color),
          const SizedBox(width: 6),
          Text(
            status.label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: status.color,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- Indicadores ----------------
  Widget _buildIndicators(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Responsive: 3 columnas en ancho amplio, 2 en estrecho.
        final int cols = constraints.maxWidth >= 420 ? 3 : 2;
        final double spacing = 10;
        final double itemWidth =
            (constraints.maxWidth - spacing * (cols - 1)) / cols;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: report.indicators.map((ind) {
            return SizedBox(
              width: itemWidth,
              child: _indicatorCard(ind),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _indicatorCard(ReportIndicator ind) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: ind.color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(ind.icon, size: 18, color: ind.color),
          ),
          const SizedBox(height: 8),
          Text(
            ind.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: _textDark,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            ind.label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  // ---------------- Secciones ----------------
  Widget _buildSection(ReportSection section) {
    switch (section.type) {
      case SectionType.findings:
        return _findingsSection(section);
      case SectionType.recommendations:
        return _recommendationsSection(section);
      case SectionType.actions:
        return _actionsSection(section);
      case SectionType.positives:
        return _positivesSection(section);
      case SectionType.conclusion:
        return _conclusionSection(section);
      case SectionType.summary:
      case SectionType.generic:
        return _genericSection(section);
    }
  }

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
    Color? background,
    Color? borderColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: background ?? Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor ?? Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: color),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: _textDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  // --- Hallazgos: una tarjeta por hallazgo ---
  Widget _findingsSection(ReportSection section) {
    final items = _itemsOf(section);
    return _sectionCard(
      title: section.title.isEmpty ? 'Hallazgos principales' : section.title,
      icon: Icons.search_rounded,
      color: _amber,
      children: [
        for (int i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          _findingCard(items[i]),
        ],
      ],
    );
  }

  Widget _findingCard(String text) {
    final importance = _importanceOf(text);
    final clean = _stripLeadingEmoji(text);
    final parts = _splitTitleDesc(clean);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: importance.color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: importance.color.withOpacity(0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 10,
            height: 10,
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(color: importance.color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        parts.$1,
                        style: GoogleFonts.poppins(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: _textDark,
                        ),
                      ),
                    ),
                    _pill(importance.label, importance.color),
                  ],
                ),
                if (parts.$2.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    parts.$2,
                    style: GoogleFonts.poppins(
                      fontSize: 12.5,
                      height: 1.45,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Recomendaciones: checklist numerada ---
  Widget _recommendationsSection(ReportSection section) {
    final items = _itemsOf(section);
    return _sectionCard(
      title: section.title.isEmpty ? 'Recomendaciones' : section.title,
      icon: Icons.checklist_rounded,
      color: const Color(0xFF42A5F5),
      children: [
        for (int i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 24,
                height: 24,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFF42A5F5).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${i + 1}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E88E5),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _stripLeadingEmoji(items[i]),
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    height: 1.45,
                    color: Colors.grey[800],
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  // --- Prioridad de acciones: agrupadas por prioridad ---
  Widget _actionsSection(ReportSection section) {
    final items = _itemsOf(section);
    final grouped = <Priority, List<String>>{
      Priority.urgente: [],
      Priority.importante: [],
      Priority.preventivo: [],
    };
    for (final item in items) {
      grouped[_priorityOf(item)]!.add(_stripLeadingEmoji(item));
    }

    final blocks = <Widget>[];
    grouped.forEach((priority, list) {
      if (list.isEmpty) return;
      if (blocks.isNotEmpty) blocks.add(const SizedBox(height: 12));
      blocks.add(_priorityBlock(priority, list));
    });

    if (blocks.isEmpty) {
      return _genericSection(section);
    }

    return _sectionCard(
      title: section.title.isEmpty ? 'Prioridad de acciones' : section.title,
      icon: Icons.flag_rounded,
      color: const Color(0xFFF57C00),
      children: blocks,
    );
  }

  Widget _priorityBlock(Priority priority, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: priority.color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text(
              priority.label,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: priority.color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(left: 18, bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.arrow_right_rounded, size: 18, color: priority.color),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    item,
                    style: GoogleFonts.poppins(
                      fontSize: 12.5,
                      height: 1.4,
                      color: Colors.grey[800],
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // --- Aspectos positivos: tarjeta verde ---
  Widget _positivesSection(ReportSection section) {
    final items = _itemsOf(section);
    const green = Color(0xFF2E7D32);
    return _sectionCard(
      title: section.title.isEmpty ? 'Aspectos positivos' : section.title,
      icon: Icons.thumb_up_rounded,
      color: green,
      background: const Color(0xFFF1F8E9),
      borderColor: green.withOpacity(0.25),
      children: [
        for (int i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.check_circle_rounded, size: 18, color: green),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _stripLeadingEmoji(items[i]),
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    height: 1.45,
                    color: Colors.grey[800],
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  // --- Conclusión: tarjeta destacada ---
  Widget _conclusionSection(ReportSection section) {
    final text = [...section.paragraphs, ...section.bullets].join(' ');
    return _sectionCard(
      title: section.title.isEmpty ? 'Conclusión' : section.title,
      icon: Icons.summarize_rounded,
      color: _amber,
      background: const Color(0xFFFFFDF5),
      borderColor: _amber.withOpacity(0.3),
      children: [
        Text(
          _stripLeadingEmoji(text),
          style: GoogleFonts.poppins(
            fontSize: 13.5,
            height: 1.5,
            color: Colors.grey[850],
          ),
        ),
      ],
    );
  }

  // --- Sección genérica: viñetas + párrafos ---
  Widget _genericSection(ReportSection section) {
    final children = <Widget>[];
    for (final p in section.paragraphs) {
      if (children.isNotEmpty) children.add(const SizedBox(height: 8));
      children.add(Text(
        p,
        style: GoogleFonts.poppins(fontSize: 13, height: 1.5, color: Colors.grey[800]),
      ));
    }
    for (final b in section.bullets) {
      if (children.isNotEmpty) children.add(const SizedBox(height: 8));
      children.add(Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(color: _amber, shape: BoxShape.circle),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _stripLeadingEmoji(b),
              style: GoogleFonts.poppins(fontSize: 13, height: 1.45, color: Colors.grey[800]),
            ),
          ),
        ],
      ));
    }
    return _sectionCard(
      title: section.title.isEmpty ? 'Análisis' : section.title,
      icon: Icons.article_rounded,
      color: _amber,
      children: children,
    );
  }

  Widget _pill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  // ---------------- Utilidades de clasificación ----------------

  List<String> _itemsOf(ReportSection section) {
    if (section.bullets.isNotEmpty) return section.bullets;
    // Si no hay viñetas, tratar cada párrafo como un ítem.
    return section.paragraphs;
  }

  Importance _importanceOf(String text) {
    final t = text.toLowerCase();
    if (text.contains('🔴') ||
        t.contains('alta') ||
        t.contains('crítico') ||
        t.contains('critico') ||
        t.contains('urgente')) {
      return Importance.alta;
    }
    if (text.contains('🟢') ||
        t.contains('baja') ||
        t.contains('leve') ||
        t.contains('preventivo')) {
      return Importance.baja;
    }
    return Importance.media;
  }

  Priority _priorityOf(String text) {
    final t = text.toLowerCase();
    if (text.contains('🔴') || t.contains('urgente') || t.contains('inmediat') || t.contains('crítico') || t.contains('critico')) {
      return Priority.urgente;
    }
    if (text.contains('🟢') || t.contains('preventivo') || t.contains('largo plazo')) {
      return Priority.preventivo;
    }
    return Priority.importante;
  }

  (String, String) _splitTitleDesc(String text) {
    // Divide "Título: descripción" o "Título. descripción".
    final colon = text.indexOf(':');
    if (colon > 0 && colon < 60) {
      return (text.substring(0, colon).trim(), text.substring(colon + 1).trim());
    }
    final dot = text.indexOf('. ');
    if (dot > 0 && dot < 60) {
      return (text.substring(0, dot).trim(), text.substring(dot + 2).trim());
    }
    if (text.length <= 70) return (text, '');
    return ('${text.substring(0, 60).trimRight()}…', text);
  }

  /// Elimina un emoji/símbolo inicial (🔴🟠🟢 etc.) y espacios.
  String _stripLeadingEmoji(String text) {
    return text
        .replaceFirst(
          RegExp(r'^[\s\u{1F300}-\u{1FAFF}\u2600-\u27BF•\-]+', unicode: true),
          '',
        )
        .trim();
  }

  String _two(int n) => n < 10 ? '0$n' : '$n';
}
