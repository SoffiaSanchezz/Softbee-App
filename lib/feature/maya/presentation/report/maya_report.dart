import 'package:flutter/material.dart';

/// Estado general del apiario mostrado como badge.
enum ReportStatus { excelente, bueno, advertencia, critico, desconocido }

extension ReportStatusX on ReportStatus {
  String get label {
    switch (this) {
      case ReportStatus.excelente:
        return 'Excelente';
      case ReportStatus.bueno:
        return 'Bueno';
      case ReportStatus.advertencia:
        return 'Advertencia';
      case ReportStatus.critico:
        return 'Crítico';
      case ReportStatus.desconocido:
        return 'Análisis';
    }
  }

  Color get color {
    switch (this) {
      case ReportStatus.excelente:
        return const Color(0xFF2E7D32);
      case ReportStatus.bueno:
        return const Color(0xFF66BB6A);
      case ReportStatus.advertencia:
        return const Color(0xFFF57C00);
      case ReportStatus.critico:
        return const Color(0xFFD32F2F);
      case ReportStatus.desconocido:
        return const Color(0xFFF5A623);
    }
  }

  IconData get icon {
    switch (this) {
      case ReportStatus.excelente:
        return Icons.verified_rounded;
      case ReportStatus.bueno:
        return Icons.check_circle_rounded;
      case ReportStatus.advertencia:
        return Icons.warning_amber_rounded;
      case ReportStatus.critico:
        return Icons.error_rounded;
      case ReportStatus.desconocido:
        return Icons.insights_rounded;
    }
  }
}

enum Importance { alta, media, baja }

extension ImportanceX on Importance {
  String get label {
    switch (this) {
      case Importance.alta:
        return 'Alta';
      case Importance.media:
        return 'Media';
      case Importance.baja:
        return 'Baja';
    }
  }

  Color get color {
    switch (this) {
      case Importance.alta:
        return const Color(0xFFD32F2F);
      case Importance.media:
        return const Color(0xFFF57C00);
      case Importance.baja:
        return const Color(0xFF66BB6A);
    }
  }
}

enum Priority { urgente, importante, preventivo }

extension PriorityX on Priority {
  String get label {
    switch (this) {
      case Priority.urgente:
        return 'Urgente';
      case Priority.importante:
        return 'Importante';
      case Priority.preventivo:
        return 'Preventivo';
    }
  }

  Color get color {
    switch (this) {
      case Priority.urgente:
        return const Color(0xFFD32F2F);
      case Priority.importante:
        return const Color(0xFFF57C00);
      case Priority.preventivo:
        return const Color(0xFF66BB6A);
    }
  }
}

class ReportIndicator {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const ReportIndicator({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
}

class ReportFinding {
  final String title;
  final String description;
  final Importance importance;
  const ReportFinding({
    required this.title,
    required this.description,
    required this.importance,
  });
}

class ReportAction {
  final String text;
  final Priority priority;
  const ReportAction({required this.text, required this.priority});
}

/// Tipo semántico de una sección detectada.
enum SectionType {
  summary,
  findings,
  recommendations,
  actions,
  positives,
  conclusion,
  generic,
}

class ReportSection {
  final String title;
  final SectionType type;
  final List<String> bullets;
  final List<String> paragraphs;
  const ReportSection({
    required this.title,
    required this.type,
    required this.bullets,
    required this.paragraphs,
  });

  bool get isEmpty => bullets.isEmpty && paragraphs.isEmpty;
}

/// Informe estructurado obtenido a partir del texto libre generado por Maya.
class MayaReport {
  final String title;
  final DateTime generatedAt;
  final ReportStatus status;
  final String summary;
  final List<ReportIndicator> indicators;
  final List<ReportSection> sections;
  final String rawText;

  const MayaReport({
    required this.title,
    required this.generatedAt,
    required this.status,
    required this.summary,
    required this.indicators,
    required this.sections,
    required this.rawText,
  });

  /// Heurística: ¿el texto parece un informe (y no una respuesta corta de chat)?
  static bool looksLikeReport(String text) {
    final t = text.toLowerCase();
    const keywords = [
      'resumen',
      'hallazgo',
      'recomendaci',
      'prioridad',
      'conclusi',
      'aspectos positivos',
      'estado general',
      'diagnóstico',
      'diagnostico',
      'análisis',
      'analisis',
    ];
    final hits = keywords.where(t.contains).length;
    return text.length > 220 && hits >= 2;
  }

  static MayaReport parse(String raw, DateTime timestamp) {
    final parser = _ReportParser(raw, timestamp);
    return parser.parse();
  }
}

// ============================ PARSER ============================

class _ReportParser {
  final String raw;
  final DateTime timestamp;
  _ReportParser(this.raw, this.timestamp);

  static final RegExp _bullet = RegExp(r'^\s*[-*•]\s+');
  static final RegExp _numbered = RegExp(r'^\s*\d+[.)]\s+');
  static final RegExp _percent = RegExp(r'(\d+(?:[.,]\d+)?)\s*%');

  MayaReport parse() {
    final lines = raw.replaceAll('\r', '').split('\n');

    String title = 'Informe del Apiario';
    final List<ReportSection> sections = [];

    String? currentTitle;
    SectionType currentType = SectionType.generic;
    List<String> bullets = [];
    List<String> paragraphs = [];
    bool titleFound = false;

    void flush() {
      if (currentTitle != null && (bullets.isNotEmpty || paragraphs.isNotEmpty)) {
        sections.add(ReportSection(
          title: currentTitle!,
          type: currentType,
          bullets: List.of(bullets),
          paragraphs: List.of(paragraphs),
        ));
      }
      bullets = [];
      paragraphs = [];
    }

    for (final rawLine in lines) {
      final line = rawLine.trim();
      if (line.isEmpty) continue;

      final header = _asHeader(line);
      if (header != null) {
        // Primer header de nivel alto se toma como título del informe.
        if (!titleFound && sections.isEmpty && bullets.isEmpty && paragraphs.isEmpty) {
          title = header;
          titleFound = true;
          currentTitle = header;
          currentType = _typeFor(header);
          // Si el título coincide con una sección conocida, lo tratamos como sección.
          if (currentType == SectionType.generic) {
            currentTitle = null; // era solo el título del informe
            continue;
          }
          continue;
        }
        flush();
        currentTitle = header;
        currentType = _typeFor(header);
        continue;
      }

      // Contenido
      if (_bullet.hasMatch(line) || _numbered.hasMatch(line)) {
        bullets.add(_cleanBullet(line));
      } else {
        paragraphs.add(_cleanInline(line));
      }
      currentTitle ??= 'Análisis';
    }
    flush();

    final status = _detectStatus(raw);
    final indicators = _extractIndicators(lines);
    final summary = _extractSummary(sections, lines);

    return MayaReport(
      title: _cleanInline(title),
      generatedAt: timestamp,
      status: status,
      summary: summary,
      indicators: indicators,
      sections: sections,
      rawText: raw,
    );
  }

  /// Devuelve el texto del encabezado si la línea lo es; si no, null.
  String? _asHeader(String line) {
    // Markdown heading
    if (line.startsWith('#')) {
      return _cleanInline(line.replaceFirst(RegExp(r'^#+\s*'), ''));
    }
    // Bold-only: **Titulo** o **Titulo:**
    final boldOnly = RegExp(r'^\*\*(.+?)\*\*:?$').firstMatch(line);
    if (boldOnly != null) {
      return _cleanInline(boldOnly.group(1)!);
    }
    // Palabra clave seguida de ':' o encabezado corto conocido
    final cleaned = _cleanInline(line);
    final lower = cleaned.toLowerCase();
    const known = [
      'resumen ejecutivo',
      'resumen',
      'hallazgos principales',
      'hallazgos',
      'recomendaciones',
      'prioridad de acciones',
      'prioridad',
      'acciones',
      'aspectos positivos',
      'conclusión',
      'conclusiones',
      'estado general',
      'indicadores',
      'diagnóstico',
    ];
    for (final k in known) {
      if (lower == k || lower == '$k:' || lower.startsWith('$k:')) {
        // Si es "clave: contenido", no es header puro salvo que sea corto.
        if (lower == k || lower == '$k:') return cleaned.replaceAll(':', '');
      }
    }
    return null;
  }

  SectionType _typeFor(String title) {
    final t = title.toLowerCase();
    if (t.contains('resumen')) return SectionType.summary;
    if (t.contains('hallazgo')) return SectionType.findings;
    if (t.contains('recomendaci')) return SectionType.recommendations;
    if (t.contains('prioridad') || t.contains('acciones')) {
      return SectionType.actions;
    }
    if (t.contains('positivo')) return SectionType.positives;
    if (t.contains('conclusi')) return SectionType.conclusion;
    return SectionType.generic;
  }

  ReportStatus _detectStatus(String raw) {
    final t = raw.toLowerCase();
    if (t.contains('crítico') || t.contains('critico') || t.contains('crítica') || t.contains('critica') || t.contains('urgente')) {
      return ReportStatus.critico;
    }
    if (t.contains('advertencia') || t.contains('riesgo alto') || t.contains('precaución') || t.contains('precaucion') || t.contains('atención') || t.contains('atencion')) {
      return ReportStatus.advertencia;
    }
    if (t.contains('excelente') || t.contains('óptimo') || t.contains('optimo')) {
      return ReportStatus.excelente;
    }
    if (t.contains('bueno') || t.contains('estable') || t.contains('saludable')) {
      return ReportStatus.bueno;
    }
    // Inferir por salud si aparece
    final m = _percent.firstMatch(raw);
    if (m != null) {
      final v = double.tryParse(m.group(1)!.replaceAll(',', '.')) ?? -1;
      if (v >= 0) {
        if (v < 30) return ReportStatus.critico;
        if (v < 60) return ReportStatus.advertencia;
        if (v < 85) return ReportStatus.bueno;
        return ReportStatus.excelente;
      }
    }
    return ReportStatus.desconocido;
  }

  List<ReportIndicator> _extractIndicators(List<String> lines) {
    final List<ReportIndicator> result = [];
    final Set<String> seen = {};

    // Definición de indicadores conocidos: keyword -> (icon, color)
    final defs = <String, (IconData, Color)>{
      'salud': (Icons.favorite_rounded, const Color(0xFFEF5350)),
      'colmena': (Icons.hive_rounded, const Color(0xFFF5A623)),
      'tratamiento': (Icons.medical_services_rounded, const Color(0xFF66BB6A)),
      'inventario': (Icons.inventory_2_rounded, const Color(0xFF78909C)),
      'riesgo': (Icons.warning_amber_rounded, const Color(0xFFF57C00)),
      'puntaje': (Icons.star_rounded, const Color(0xFF42A5F5)),
      'score': (Icons.star_rounded, const Color(0xFF42A5F5)),
    };

    final kv = RegExp(r'^[\s\-*•]*\**\s*([A-Za-zÁÉÍÓÚÑáéíóúñ ]{3,40}?)\s*\**\s*[:=]\s*(.+)$');

    for (final rawLine in lines) {
      final line = rawLine.trim();
      final match = kv.firstMatch(line);
      if (match == null) continue;
      final label = _cleanInline(match.group(1)!).trim();
      var value = _cleanInline(match.group(2)!).trim();
      if (label.isEmpty || value.isEmpty || value.length > 24) continue;

      final lower = label.toLowerCase();
      for (final entry in defs.entries) {
        if (lower.contains(entry.key) && !seen.contains(entry.key)) {
          seen.add(entry.key);
          // Recortar el valor a lo esencial (primer número/%, o texto breve)
          final pv = _percent.firstMatch(value);
          if (pv != null) value = '${pv.group(1)}%';
          result.add(ReportIndicator(
            label: label,
            value: value,
            icon: entry.value.$1,
            color: entry.value.$2,
          ));
          break;
        }
      }
    }
    return result;
  }

  String _extractSummary(List<ReportSection> sections, List<String> lines) {
    // 1. Usar la sección de resumen si existe
    for (final s in sections) {
      if (s.type == SectionType.summary) {
        final text = [...s.paragraphs, ...s.bullets].join(' ');
        if (text.trim().isNotEmpty) return _shorten(text.trim(), 260);
      }
    }
    // 2. Primer párrafo significativo
    for (final rawLine in lines) {
      final line = _cleanInline(rawLine.trim());
      if (line.length > 40 && !line.startsWith('#')) {
        return _shorten(line, 260);
      }
    }
    return 'Informe generado por Maya con el análisis del estado actual del apiario.';
  }

  String _shorten(String text, int max) {
    if (text.length <= max) return text;
    return '${text.substring(0, max).trimRight()}…';
  }

  String _cleanBullet(String line) {
    var s = line.replaceFirst(_bullet, '').replaceFirst(_numbered, '');
    return _cleanInline(s);
  }

  /// Quita markdown inline (**bold**, *italic*, `code`, #, exceso de espacios).
  String _cleanInline(String line) {
    var s = line;
    s = s.replaceAll(RegExp(r'\*\*(.+?)\*\*'), r'$1');
    s = s.replaceAll(RegExp(r'\*(.+?)\*'), r'$1');
    s = s.replaceAll('`', '');
    s = s.replaceFirst(RegExp(r'^#+\s*'), '');
    s = s.replaceAll(RegExp(r'\s+'), ' ').trim();
    return s;
  }
}
