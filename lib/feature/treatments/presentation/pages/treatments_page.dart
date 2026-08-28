import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:Softbee/feature/beehive/presentation/providers/beehive_providers.dart';
import 'package:Softbee/feature/beehive/domain/entities/beehive.dart';
import 'package:Softbee/feature/treatments/presentation/widgets/hive_treatments_management_dialog.dart';

class TreatmentsPage extends ConsumerStatefulWidget {
  final String apiaryId;

  const TreatmentsPage({super.key, required this.apiaryId});

  @override
  ConsumerState<TreatmentsPage> createState() => _TreatmentsPageState();
}

class _TreatmentsPageState extends ConsumerState<TreatmentsPage> {
  // Breakpoint a partir del cual se aplica el diseño Desktop.
  static const double _kDesktopBreakpoint = 1024;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(beehiveControllerProvider.notifier)
          .fetchBeehivesByApiary(widget.apiaryId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final beehiveState = ref.watch(beehiveControllerProvider);
    final hivesRequiringTreatment = beehiveState.beehives
        .where((hive) => hive.treatments == true)
        .toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isDesktop = constraints.maxWidth >= _kDesktopBreakpoint;

        return Scaffold(
          // Fondo más neutro en Desktop para que resalten las tarjetas.
          backgroundColor: isDesktop ? const Color(0xFFF6F7F9) : null,
          appBar: AppBar(
            title: Text(
              'Tratamientos',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
            backgroundColor: Colors.amber.shade700,
            foregroundColor: Colors.white,
            elevation: isDesktop ? 0 : null,
          ),
          body: beehiveState.isLoading
              ? const Center(child: CircularProgressIndicator())
              : isDesktop
                  ? _buildDesktopBody(hivesRequiringTreatment)
                  : (hivesRequiringTreatment.isEmpty
                      ? _buildEmptyState()
                      : _buildMobileBody(hivesRequiringTreatment)),
        );
      },
    );
  }

  // ===========================================================================
  // MÓVIL / TABLET  (sin cambios de diseño)
  // ===========================================================================

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.medical_services_outlined,
              size: 100,
              color: Colors.amber.shade100,
            ),
            const SizedBox(height: 20),
            Text(
              'No hay colmenas con tratamiento',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.amber.shade900,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'Solo se muestran aquí las colmenas que tienen activada la opción de tratamientos en su configuración.',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Móvil: encabezado compacto + grid de tarjetas.
  Widget _buildMobileBody(List<Beehive> hives) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
          child: _buildMobileHeader(hives.length),
        ),
        Expanded(child: _buildMobileGrid(hives)),
      ],
    );
  }

  // Encabezado "Gestión de Tratamientos" en versión móvil: mantiene la
  // identidad de Softbee (gradiente naranja, bordes redondeados, icono y
  // tipografía) pero mucho más compacto y adaptado al ancho de pantalla.
  Widget _buildMobileHeader(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: [Colors.amber.shade600, Colors.orange.shade700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withValues(alpha: 0.22),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.medical_services_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Gestión de Tratamientos',
                  style: GoogleFonts.poppins(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '$count ${count == 1 ? 'colmena activa' : 'colmenas activas'}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Móvil: reutiliza la misma tarjeta visual de Desktop (colores, iconos,
  // bordes y jerarquía) pero en su variante compacta y distribuida en un
  // grid horizontal (2 columnas) en lugar de una lista apilada.
  Widget _buildMobileGrid(List<Beehive> hives) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // En pantallas muy estrechas 2 columnas; en las más anchas
        // (tablet en vertical) permitimos 3 para aprovechar el espacio.
        final double width = constraints.maxWidth;
        final int crossAxisCount = width >= 620 ? 3 : 2;

        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            mainAxisExtent: 250,
          ),
          itemCount: hives.length,
          itemBuilder: (context, index) =>
              _buildDesktopHiveCard(hives[index], compact: true),
        );
      },
    );
  }

  // ===========================================================================
  // DESKTOP  (rediseño visual)
  // ===========================================================================

  Widget _buildDesktopBody(List<Beehive> hives) {
    // Alineado arriba (topCenter) en lugar de Center: el Center anterior
    // centraba el contenido verticalmente y dejaba mucho espacio vacío
    // sobre la barra. Se conserva el centrado horizontal (maxWidth 1400).
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1400),
        child: SingleChildScrollView(
          // Espacio superior mínimo para que la sección quede pegada arriba.
          padding: const EdgeInsets.fromLTRB(40, 20, 40, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildDesktopHeader(hives.length),
              const SizedBox(height: 32),
              if (hives.isEmpty)
                _buildDesktopEmptyState()
              else
                _buildDesktopGrid(hives),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopHeader(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [Colors.amber.shade600, Colors.orange.shade700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withValues(alpha: 0.25),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.medical_services_rounded,
              color: Colors.white,
              size: 40,
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Gestión de Tratamientos',
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Supervisa la salud de tus colmenas y administra los tratamientos activos.',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          _buildHeaderStat(count),
        ],
      ),
    );
  }

  Widget _buildHeaderStat(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Text(
            '$count',
            style: GoogleFonts.poppins(
              fontSize: 34,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            count == 1 ? 'Colmena' : 'Colmenas',
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopGrid(List<Beehive> hives) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        int crossAxisCount;
        if (width >= 1200) {
          crossAxisCount = 4;
        } else if (width >= 900) {
          crossAxisCount = 3;
        } else {
          crossAxisCount = 2;
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 24,
            crossAxisSpacing: 24,
            mainAxisExtent: 268,
          ),
          itemCount: hives.length,
          itemBuilder: (context, index) => _buildDesktopHiveCard(hives[index]),
        );
      },
    );
  }

  Widget _buildDesktopHiveCard(Beehive hive, {bool compact = false}) {
    final Color healthColor = _healthColor(hive.healthStatus);

    // Dimensiones adaptadas: en móvil (compact) se reducen tamaños y
    // espaciados manteniendo estilos, colores, iconos y bordes.
    final double cardRadius = compact ? 16 : 20;
    final EdgeInsets headerPadding = compact
        ? const EdgeInsets.symmetric(horizontal: 12, vertical: 12)
        : const EdgeInsets.symmetric(horizontal: 18, vertical: 16);
    final double avatarRadius = compact ? 15 : 22;
    final double hiveIconSize = compact ? 18 : 24;
    final double avatarSpacing = compact ? 8 : 12;
    final double titleFontSize = compact ? 13.5 : 17;
    final EdgeInsets bodyPadding = compact
        ? const EdgeInsets.fromLTRB(12, 12, 12, 12)
        : const EdgeInsets.fromLTRB(18, 16, 18, 16);
    final double metricSpacing = compact ? 8 : 12;
    final double buttonVerticalPadding = compact ? 10 : 14;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(cardRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Banda superior con número de colmena y estado de salud.
          Container(
            padding: headerPadding,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.amber.shade50, Colors.orange.shade50],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: avatarRadius,
                  backgroundColor: Colors.amber.shade100,
                  child: Icon(Icons.hive_rounded,
                      color: Colors.amber.shade800, size: hiveIconSize),
                ),
                SizedBox(width: avatarSpacing),
                Expanded(
                  child: Text(
                    'Colmena #${hive.beehiveNumber ?? '-'}',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: titleFontSize,
                      color: Colors.grey.shade900,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(width: compact ? 6 : 8),
                _buildHealthChip(hive.healthStatus, healthColor,
                    compact: compact),
              ],
            ),
          ),
          // Cuerpo con métricas.
          Expanded(
            child: Padding(
              padding: bodyPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMetricRow(
                    Icons.local_fire_department_rounded,
                    'Actividad',
                    hive.activityLevel ?? 'N/A',
                    compact: compact,
                  ),
                  SizedBox(height: metricSpacing),
                  _buildMetricRow(
                    Icons.groups_rounded,
                    'Población',
                    hive.beePopulation ?? 'N/A',
                    compact: compact,
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => HiveTreatmentsManagementDialog(
                            hiveId: hive.id,
                            hiveNumber: hive.beehiveNumber ?? 0,
                            hive: hive,
                          ),
                        );
                      },
                      icon: Icon(Icons.medical_services_rounded,
                          size: compact ? 16 : 18),
                      label: Text(
                        'Gestionar',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: compact ? 13 : null,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber.shade700,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: EdgeInsets.symmetric(
                            vertical: buttonVerticalPadding),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricRow(IconData icon, String label, String value,
      {bool compact = false}) {
    final double fontSize = compact ? 12 : 13;
    return Row(
      children: [
        Icon(icon, size: compact ? 16 : 18, color: Colors.grey.shade500),
        SizedBox(width: compact ? 6 : 8),
        Text(
          '$label:',
          style: GoogleFonts.poppins(
            fontSize: fontSize,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade900,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildHealthChip(String? health, Color color, {bool compact = false}) {
    return Container(
      padding: compact
          ? const EdgeInsets.symmetric(horizontal: 8, vertical: 4)
          : const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: compact ? 7 : 8,
            height: compact ? 7 : 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          SizedBox(width: compact ? 4 : 6),
          Flexible(
            child: Text(
              health ?? 'N/A',
              style: GoogleFonts.poppins(
                fontSize: compact ? 10.5 : 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Color _healthColor(String? health) {
    final value = (health ?? '').toLowerCase();
    if (value.contains('buena') ||
        value.contains('excelente') ||
        value.contains('saludable') ||
        value.contains('bueno')) {
      return Colors.green.shade600;
    }
    if (value.contains('regular') || value.contains('media')) {
      return Colors.orange.shade700;
    }
    if (value.contains('mala') ||
        value.contains('crítica') ||
        value.contains('critica') ||
        value.contains('malo')) {
      return Colors.red.shade600;
    }
    return Colors.grey.shade500;
  }

  Widget _buildDesktopEmptyState() {
    return Container(
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 64),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.medical_services_outlined,
              size: 72,
              color: Colors.amber.shade400,
            ),
          ),
          const SizedBox(height: 28),
          Text(
            'No hay colmenas con tratamiento',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.amber.shade900,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Text(
              'Solo se muestran aquí las colmenas que tienen activada la opción de tratamientos en su configuración.',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
