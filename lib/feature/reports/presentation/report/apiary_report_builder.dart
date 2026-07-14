import '../../../maya/presentation/report/maya_report.dart' show ReportStatus, Priority;

/// Reporte del apiario en lenguaje natural, construido a partir de los datos
/// reales (estadísticas) y no del texto crudo de la IA. Así se evita mostrar
/// variables técnicas, IDs o placeholders como `$1`.
class ApiaryReport {
  final String apiaryName;
  final String? location;
  final DateTime date;

  final bool hasData;
  final ReportStatus status;

  final int healthPct;
  final int beehives;
  final int activeTreatments;
  final int lowStockItems;

  /// Razones que explican el estado general (máx. 4 líneas).
  final List<String> summaryReasons;
  final List<String> positives;
  final List<String> problems;
  final Map<Priority, List<String>> actions;
  final String mayaRecommendation;

  const ApiaryReport({
    required this.apiaryName,
    required this.location,
    required this.date,
    required this.hasData,
    required this.status,
    required this.healthPct,
    required this.beehives,
    required this.activeTreatments,
    required this.lowStockItems,
    required this.summaryReasons,
    required this.positives,
    required this.problems,
    required this.actions,
    required this.mayaRecommendation,
  });

  static String _healthLabel(int h) {
    if (h < 30) return 'muy baja';
    if (h < 60) return 'baja';
    if (h < 85) return 'buena';
    return 'excelente';
  }

  static ReportStatus _statusFor(int h) {
    if (h < 30) return ReportStatus.critico;
    if (h < 60) return ReportStatus.advertencia;
    if (h < 85) return ReportStatus.bueno;
    return ReportStatus.excelente;
  }

  factory ApiaryReport.fromStats({
    required String apiaryName,
    String? location,
    required DateTime date,
    Map<String, dynamic>? stats,
  }) {
    if (stats == null) {
      return ApiaryReport(
        apiaryName: apiaryName,
        location: location,
        date: date,
        hasData: false,
        status: ReportStatus.desconocido,
        healthPct: 0,
        beehives: 0,
        activeTreatments: 0,
        lowStockItems: 0,
        summaryReasons: const [
          'No hay información suficiente para generar el análisis del apiario.',
        ],
        positives: const [],
        problems: const [],
        actions: const {},
        mayaRecommendation:
            'No hay información suficiente para generar una recomendación.',
      );
    }

    final int health = ((stats['avg_health_score'] as num?) ?? 0).round();
    final int beehives = ((stats['total_beehives'] as num?) ?? 0).toInt();
    final int treatments = ((stats['active_treatments'] as num?) ?? 0).toInt();
    final int lowStock = ((stats['low_stock_items'] as num?) ?? 0).toInt();

    final status = _statusFor(health);
    final healthLabel = _healthLabel(health);

    // ---- Estado general (razones, máx. 4) ----
    final reasons = <String>[];
    if (health < 60) {
      reasons.add('La salud promedio de las colmenas es $healthLabel ($health%).');
    }
    if (treatments == 0) {
      reasons.add('No existen tratamientos activos registrados.');
    }
    if (lowStock > 0) {
      reasons.add('Hay insumos agotados o con stock bajo.');
    }
    if (status == ReportStatus.critico || status == ReportStatus.advertencia) {
      reasons.add('Se recomienda realizar una inspección lo antes posible.');
    }
    if (reasons.isEmpty) {
      reasons.add('El apiario se encuentra en buen estado general ($health% de salud).');
    }
    final summaryReasons = reasons.take(4).toList();

    // ---- Aspectos positivos ----
    final positives = <String>[];
    if (health >= 60) {
      positives.add('La salud general de las colmenas es adecuada ($health%).');
    }
    if (lowStock == 0) {
      positives.add('El inventario está completo, sin faltantes.');
    }
    if (treatments > 0) {
      positives.add('Hay $treatments tratamiento(s) activo(s) en curso.');
    }
    if (beehives > 0) {
      positives.add('El apiario cuenta con $beehives colmena(s) registrada(s).');
    }

    // ---- Problemas detectados ----
    final problems = <String>[];
    if (health < 60) {
      problems.add(
          'Las colmenas presentan un estado sanitario $healthLabel y requieren atención.');
    }
    if (treatments == 0) {
      problems.add('No existen tratamientos registrados para este apiario.');
    }
    if (lowStock > 0) {
      problems.add(
          'El inventario tiene $lowStock insumo(s) agotado(s) o con stock bajo.');
    }

    // ---- Acciones por prioridad ----
    final actions = <Priority, List<String>>{
      Priority.urgente: [],
      Priority.importante: [],
      Priority.preventivo: [],
    };

    if (health < 30) {
      actions[Priority.urgente]!.add(beehives > 0
          ? 'Realizar una inspección sanitaria inmediata de las $beehives colmena(s).'
          : 'Realizar una inspección sanitaria inmediata del apiario.');
      actions[Priority.urgente]!.add('Registrar una nueva inspección sanitaria.');
    }
    if (treatments == 0 && health < 60) {
      actions[Priority.urgente]!
          .add('Aplicar un tratamiento sanitario (por ejemplo, contra Varroa).');
    }

    if (lowStock > 0) {
      actions[Priority.importante]!.add('Comprar y reponer los insumos faltantes.');
      actions[Priority.importante]!.add('Actualizar el inventario del apiario.');
    }
    if (health >= 30 && health < 60) {
      actions[Priority.importante]!.add('Programar una inspección de las colmenas.');
    }

    actions[Priority.preventivo]!.add('Programar un monitoreo en 7 días.');
    actions[Priority.preventivo]!
        .add('Mantener actualizado el registro de inspecciones.');

    actions.removeWhere((key, value) => value.isEmpty);

    // ---- Recomendación de Maya (máx. ~3 líneas) ----
    String recommendation;
    final pieces = <String>[];
    if (health < 60 || treatments == 0) {
      pieces.add('prioriza una inspección completa del apiario');
    }
    if (treatments == 0 || health < 60) {
      pieces.add('aplica tratamientos sanitarios');
    }
    if (lowStock > 0) {
      pieces.add('repón los insumos críticos');
    }
    if (pieces.isEmpty) {
      recommendation =
          'El apiario se encuentra en buen estado. Mantén el monitoreo periódico y el registro de inspecciones al día.';
    } else {
      final joined = _joinNatural(pieces);
      recommendation =
          '${_capitalize(joined)} antes del próximo monitoreo.';
    }

    return ApiaryReport(
      apiaryName: apiaryName,
      location: location,
      date: date,
      hasData: true,
      status: status,
      healthPct: health,
      beehives: beehives,
      activeTreatments: treatments,
      lowStockItems: lowStock,
      summaryReasons: summaryReasons,
      positives: positives,
      problems: problems,
      actions: actions,
      mayaRecommendation: recommendation,
    );
  }

  static String _joinNatural(List<String> parts) {
    if (parts.length == 1) return parts.first;
    return '${parts.sublist(0, parts.length - 1).join(', ')} y ${parts.last}';
  }

  static String _capitalize(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
}
