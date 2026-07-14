import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../controllers/insights_controller.dart';
import '../../../maya/presentation/report/maya_report.dart' show ReportStatus, ReportStatusX, Priority, PriorityX;
import '../report/apiary_report_builder.dart';

class ApiaryInsightsPage extends ConsumerStatefulWidget {
  final String apiaryId;
  final String apiaryName;

  const ApiaryInsightsPage({
    super.key,
    required this.apiaryId,
    required this.apiaryName,
  });

  @override
  ConsumerState<ApiaryInsightsPage> createState() => _ApiaryInsightsPageState();
}

class _ApiaryInsightsPageState extends ConsumerState<ApiaryInsightsPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => 
      ref.read(insightsControllerProvider.notifier).refreshAll(widget.apiaryId)
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(insightsControllerProvider);
    final size = MediaQuery.of(context).size;
    final bool isDesktop = size.width > 1200;
    final bool isTablet = size.width > 700 && size.width <= 1200;

    // Construimos el reporte en lenguaje natural a partir de los datos reales
    // (evitando variables técnicas, IDs o placeholders como $1).
    final report = ApiaryReport.fromStats(
      apiaryName: widget.apiaryName,
      date: DateTime.now(),
      stats: state.generalStats,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: CustomScrollView(
            slivers: [
              _buildAppBar(),
              if (state.isLoading)
                const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: Colors.amber)))
              else
                SliverPadding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isDesktop ? 40 : 20,
                    vertical: 20,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _buildAiHeroSection(state, isDesktop, report),
                      const SizedBox(height: 24),
                      _buildMetricsGrid(state.generalStats, size.width, report.status),
                      const SizedBox(height: 24),
                      ..._buildReportSections(report),
                      const SizedBox(height: 30),
                      if (isDesktop)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 2, child: _buildMainCharts(state)),
                            const SizedBox(width: 24),
                            Expanded(flex: 1, child: _buildInventoryStatus(state.inventoryLevels)),
                          ],
                        )
                      else
                        Column(
                          children: [
                            _buildMainCharts(state),
                            const SizedBox(height: 30),
                            _buildInventoryStatus(state.inventoryLevels),
                          ],
                        ),
                      const SizedBox(height: 50),
                    ]),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      pinned: true,
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87, size: 20),
        onPressed: () => Navigator.of(context).pop(),
      ),
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.symmetric(horizontal: 56, vertical: 16),
        title: Text(
          widget.apiaryName,
          style: GoogleFonts.poppins(
            color: const Color(0xFF1A1A1A),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.amber.withOpacity(0.1), Colors.white],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded, color: Colors.black54),
          onPressed: () => ref.read(insightsControllerProvider.notifier).refreshAll(widget.apiaryId),
        ),
        const SizedBox(width: 10),
      ],
    );
  }

  Widget _buildAiHeroSection(
    AdvancedInsightsState state,
    bool isDesktop,
    ApiaryReport report,
  ) {
    final dateStr =
        '${_two(report.date.day)}/${_two(report.date.month)}/${report.date.year} · ${_two(report.date.hour)}:${_two(report.date.minute)}';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isDesktop ? 30 : 22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1A1A), Color(0xFF2D3436)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
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
                  color: Colors.amber.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.auto_awesome, color: Colors.amber, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Análisis de Maya",
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: isDesktop ? 22 : 18,
                      ),
                    ),
                    Text(
                      "Apiario: ${report.apiaryName}",
                      style: GoogleFonts.poppins(
                        color: Colors.white.withOpacity(0.75),
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      dateStr,
                      style: GoogleFonts.poppins(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              _buildStatusBadgeDark(report.status),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            'Estado general',
            style: GoogleFonts.poppins(
              color: Colors.amber,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 10),
          // Razones del estado general en lenguaje natural (máx. 4 líneas).
          ...report.summaryReasons.map(
            (reason) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.only(top: 7),
                    decoration: BoxDecoration(
                      color: report.status.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      reason,
                      style: GoogleFonts.poppins(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: isDesktop ? 14 : 13,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.1);
  }

  /// Badge de estado (versión para fondo oscuro) usando el estado del parser.
  Widget _buildStatusBadgeDark(ReportStatus status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: status.color.withOpacity(0.22),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: status.color.withOpacity(0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(status.icon, size: 14, color: status.color),
          const SizedBox(width: 6),
          Text(
            status.label.toUpperCase(),
            style: GoogleFonts.poppins(
              color: status.color,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid(
    Map<String, dynamic>? stats,
    double width,
    ReportStatus? status,
  ) {
    int crossAxisCount = 2;
    double aspectRatio = 1.3;

    if (width > 1000) {
      crossAxisCount = 4;
      aspectRatio = 1.45;
    } else if (width > 600) {
      crossAxisCount = 3;
      aspectRatio = 1.4;
    }

    // Salud como valor numérico para pintar barra de progreso.
    final num healthNum = (stats?['avg_health_score'] as num?) ?? 0;
    final double healthPct = (healthNum.toDouble() / 100).clamp(0.0, 1.0);

    final risk = _riskFromStatus(status);

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: crossAxisCount,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: aspectRatio,
      children: [
        _buildMetricCard("Salud Promedio", "$healthNum%", Icons.favorite_rounded, Colors.redAccent, "Salud",
            progress: healthPct),
        _buildMetricCard("Colmenas", "${stats?['total_beehives'] ?? 0}", Icons.hive_rounded, Colors.amber, "Total"),
        _buildMetricCard("Tratamientos", "${stats?['active_treatments'] ?? 0}", Icons.healing_rounded, Colors.blueAccent, "Activos"),
        _buildMetricCard("Inventario", "${stats?['low_stock_items'] ?? 0}", Icons.inventory_2_rounded, Colors.orangeAccent, "Stock bajo"),
        _buildMetricCard("Riesgo", risk.$1, Icons.shield_rounded, risk.$2, "General"),
      ],
    );
  }

  /// Traduce el estado del informe a un nivel de riesgo (texto + color).
  (String, Color) _riskFromStatus(ReportStatus? status) {
    switch (status) {
      case ReportStatus.critico:
        return ('Alto', const Color(0xFFD32F2F));
      case ReportStatus.advertencia:
        return ('Medio', const Color(0xFFF57C00));
      case ReportStatus.bueno:
        return ('Bajo', const Color(0xFF66BB6A));
      case ReportStatus.excelente:
        return ('Muy bajo', const Color(0xFF2E7D32));
      default:
        return ('—', Colors.grey);
    }
  }

  String _two(int n) => n < 10 ? '0$n' : '$n';

  // ================= Secciones del reporte (lenguaje natural) =================

  List<Widget> _buildReportSections(ApiaryReport report) {
    if (!report.hasData) {
      return [
        _infoSection(
          title: 'Sin datos suficientes',
          icon: Icons.info_outline_rounded,
          color: Colors.grey,
          child: Text(
            'No hay información suficiente para generar el análisis del apiario.',
            style: GoogleFonts.poppins(fontSize: 13, height: 1.5, color: Colors.grey[700]),
          ),
        ),
      ];
    }

    final widgets = <Widget>[];

    // Qué funciona bien
    if (report.positives.isNotEmpty) {
      widgets.add(_bulletSection(
        title: 'Qué funciona bien',
        icon: Icons.thumb_up_rounded,
        color: const Color(0xFF2E7D32),
        background: const Color(0xFFF1F8E9),
        bulletIcon: Icons.check_circle_rounded,
        items: report.positives,
      ));
      widgets.add(const SizedBox(height: 20));
    }

    // Problemas detectados
    if (report.problems.isNotEmpty) {
      widgets.add(_bulletSection(
        title: 'Problemas detectados',
        icon: Icons.report_problem_rounded,
        color: const Color(0xFFD32F2F),
        background: const Color(0xFFFDECEA),
        bulletIcon: Icons.error_outline_rounded,
        items: report.problems,
      ));
      widgets.add(const SizedBox(height: 20));
    }

    // Qué hacer primero (acciones por prioridad)
    if (report.actions.isNotEmpty) {
      widgets.add(_actionsSection(report.actions));
      widgets.add(const SizedBox(height: 20));
    }

    // Recomendación de Maya
    widgets.add(_recommendationSection(report.mayaRecommendation));

    return [
      for (int i = 0; i < widgets.length; i++)
        widgets[i].animate().fadeIn(delay: (80 * i).ms).slideY(begin: 0.06, end: 0),
    ];
  }

  Widget _sectionShell({
    required String title,
    required IconData icon,
    required Color color,
    required Widget child,
    Color? background,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: background ?? Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withOpacity(0.18)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 20, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2D3436),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _infoSection({
    required String title,
    required IconData icon,
    required Color color,
    required Widget child,
  }) =>
      _sectionShell(title: title, icon: icon, color: color, child: child);

  Widget _bulletSection({
    required String title,
    required IconData icon,
    required Color color,
    required Color background,
    required IconData bulletIcon,
    required List<String> items,
  }) {
    return _sectionShell(
      title: title,
      icon: icon,
      color: color,
      background: background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < items.length; i++)
            Padding(
              padding: EdgeInsets.only(bottom: i == items.length - 1 ? 0 : 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(bulletIcon, size: 18, color: color),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      items[i],
                      style: GoogleFonts.poppins(
                        fontSize: 13.5,
                        height: 1.5,
                        color: Colors.grey[850],
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _actionsSection(Map<Priority, List<String>> actions) {
    final blocks = <Widget>[];
    actions.forEach((priority, items) {
      if (items.isEmpty) return;
      if (blocks.isNotEmpty) blocks.add(const SizedBox(height: 16));
      blocks.add(_priorityBlock(priority, items));
    });

    return _sectionShell(
      title: 'Qué hacer primero',
      icon: Icons.flag_rounded,
      color: const Color(0xFFF57C00),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: blocks),
    );
  }

  Widget _priorityBlock(Priority priority, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(color: priority.color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text(
              priority.label,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: priority.color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(left: 20, bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.check_circle_outline_rounded, size: 17, color: priority.color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item,
                    style: GoogleFonts.poppins(fontSize: 13, height: 1.45, color: Colors.grey[850]),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _recommendationSection(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.amber.withOpacity(0.18), Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.amber.withOpacity(0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.25),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.auto_awesome_rounded, color: Color(0xFFB8860B)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Recomendación de Maya',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2D3436),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  text,
                  style: GoogleFonts.poppins(
                    fontSize: 13.5,
                    height: 1.5,
                    color: Colors.grey[850],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(
    String title,
    String val,
    IconData icon,
    Color color,
    String trend, {
    double? progress,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              Flexible(
                child: Text(
                  trend,
                  style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(val, style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: const Color(0xFF2D3436))),
              ),
              Text(title, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]), overflow: TextOverflow.ellipsis),
              if (progress != null) ...[
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: color.withOpacity(0.12),
                    color: color,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    ).animate().fadeIn().scale();
  }

  Widget _buildMainCharts(AdvancedInsightsState state) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Evolución de Salud Global", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 30),
          SizedBox(
            height: 250,
            child: LineChart(_getHealthChartData(state.healthTrends)),
          ),
        ],
      ),
    );
  }

  LineChartData _getHealthChartData(List<dynamic>? trends) {
    if (trends == null || trends.isEmpty) return LineChartData();
    
    // Simplificamos: tomamos los data_points de la primera colmena que los tenga
    final points = trends.first['data_points'] as List;
    final List<FlSpot> spots = points.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), (e.value['score'] as num).toDouble());
    }).toList();

    return LineChartData(
      gridData: const FlGridData(show: false),
      titlesData: const FlTitlesData(show: false),
      borderData: FlBorderData(show: false),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: Colors.amber,
          barWidth: 6,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [Colors.amber.withOpacity(0.3), Colors.amber.withOpacity(0.0)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInventoryStatus(List<dynamic>? items) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Niveles de Suministros", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 20),
          ...?items?.map((item) => _buildInventoryBar(item)),
        ],
      ),
    );
  }

  Widget _buildInventoryBar(Map<String, dynamic> item) {
    final double percent = (item['current_quantity'] / (item['minimum_stock'] * 2)).clamp(0.0, 1.0);
    final color = item['status'] == 'ok' ? Colors.green : Colors.red;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(item['item_name'], style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500)),
              Text("${item['current_quantity']} uds", style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: percent,
              minHeight: 8,
              backgroundColor: Colors.grey[100],
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
