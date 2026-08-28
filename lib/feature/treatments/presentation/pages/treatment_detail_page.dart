import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:Softbee/feature/beehive/domain/entities/beehive.dart';
import '../../domain/entities/treatment.dart';
import '../providers/treatment_providers.dart';
import '../widgets/treatment_form_dialog.dart';
import '../widgets/followup_form_dialog.dart';
import '../widgets/treatment_status.dart';

/// Vista de informe completo de un tratamiento.
///
/// Muestra toda la información disponible del tratamiento organizada en
/// secciones/tarjetas (general, colmena, detalles, seguimiento e historial),
/// con opciones para editar, gestionar seguimientos y exportar el informe.
class TreatmentDetailPage extends ConsumerWidget {
  final String treatmentId;
  final int hiveNumber;
  final Beehive? hive;

  const TreatmentDetailPage({
    super.key,
    required this.treatmentId,
    required this.hiveNumber,
    this.hive,
  });

  static const Color _amber = Color(0xFFF59E0B);
  static const Color _bg = Color(0xFFF6F7F9);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Se observa el controlador para que la vista se actualice tras editar
    // el tratamiento o registrar/eliminar seguimientos.
    final treatment = ref.watch(treatmentsControllerProvider
        .select((s) => _findById(s.treatments, treatmentId)));

    // Feedback de éxito / error (edición, seguimientos, etc.).
    ref.listen(treatmentsControllerProvider, (previous, next) {
      if (next.successMessage != null &&
          previous?.successMessage != next.successMessage) {
        _showSnack(context, next.successMessage!, Colors.green.shade600);
        ref.read(treatmentsControllerProvider.notifier).clearMessages();
      }
      if (next.errorMessage != null &&
          previous?.errorMessage != next.errorMessage) {
        _showSnack(context, next.errorMessage!, Colors.red.shade600);
        ref.read(treatmentsControllerProvider.notifier).clearMessages();
      }
    });

    final bool isWide = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: Text('Informe de Tratamiento',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.amber.shade700,
        foregroundColor: Colors.white,
        actions: treatment == null
            ? null
            : [
                IconButton(
                  tooltip: 'Exportar informe',
                  icon: const Icon(Icons.ios_share_rounded),
                  onPressed: () => _exportReport(context, treatment),
                ),
                IconButton(
                  tooltip: 'Editar tratamiento',
                  icon: const Icon(Icons.edit_rounded),
                  onPressed: () => _edit(context, treatment),
                ),
                const SizedBox(width: 4),
              ],
      ),
      body: treatment == null
          ? _buildNotFound(context)
          : Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildHeaderCard(treatment),
                      const SizedBox(height: 16),
                      if (isWide)
                        IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: _buildGeneralSection(treatment)),
                              const SizedBox(width: 16),
                              Expanded(child: _buildPatientSection()),
                            ],
                          ),
                        )
                      else ...[
                        _buildGeneralSection(treatment),
                        const SizedBox(height: 16),
                        _buildPatientSection(),
                      ],
                      const SizedBox(height: 16),
                      _buildDetailsSection(treatment),
                      const SizedBox(height: 16),
                      _buildFollowupSummarySection(treatment),
                      const SizedBox(height: 16),
                      _buildHistorySection(context, ref, treatment),
                      const SizedBox(height: 24),
                      _buildEditButton(context, treatment),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  static Treatment? _findById(List<Treatment> treatments, String id) {
    for (final t in treatments) {
      if (t.id == id) return t;
    }
    return null;
  }

  void _showSnack(BuildContext context, String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.poppins()),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildNotFound(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text('Tratamiento no disponible',
                style: GoogleFonts.poppins(
                    fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
            const SizedBox(height: 8),
            Text(
              'Es posible que haya sido eliminado o que ya no esté cargado.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(color: Colors.grey.shade500),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber.shade700,
                foregroundColor: Colors.white,
              ),
              child: Text('Volver', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Encabezado
  // ---------------------------------------------------------------------------

  Widget _buildHeaderCard(Treatment t) {
    return Container(
      padding: const EdgeInsets.all(24),
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
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.medical_services_rounded,
                    color: Colors.white, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.productName,
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      t.treatmentType,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
              _statusChip(t.status, onWhite: true),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _headerPill(Icons.tag_rounded, 'Código', _shortCode(t.id)),
              _headerPill(Icons.hive_rounded, 'Colmena', '#$hiveNumber'),
              _headerPill(Icons.play_arrow_rounded, 'Inicio',
                  DateFormat('dd/MM/yyyy').format(t.startDate)),
              _headerPill(Icons.timelapse_rounded, 'Duración', _durationLabel(t)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _headerPill(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 8),
          Text('$label: ',
              style: GoogleFonts.poppins(
                  fontSize: 12, color: Colors.white.withValues(alpha: 0.85))),
          Text(value,
              style: GoogleFonts.poppins(
                  fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
        ],
      ),
    );
  }

  Widget _statusChip(String? status, {bool onWhite = false}) {
    final color = TreatmentStatus.color(status);
    final label = TreatmentStatus.label(status);
    final bg = onWhite ? Colors.white : color.withValues(alpha: 0.12);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(TreatmentStatus.icon(status), size: 16, color: color),
          const SizedBox(width: 6),
          Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 12.5, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Secciones
  // ---------------------------------------------------------------------------

  Widget _buildGeneralSection(Treatment t) {
    return _sectionCard(
      icon: Icons.info_outline_rounded,
      title: 'Información General',
      children: [
        _infoRow('Nombre del tratamiento', t.productName),
        _infoRow('Tipo', t.treatmentType),
        _infoRow('Código / Identificador', _shortCode(t.id)),
        _infoRow('Estado', TreatmentStatus.label(t.status)),
        _infoRow('Fecha de inicio', _date(t.startDate)),
        _infoRow('Fecha de finalización', _dateOrNull(t.endDate)),
        _infoRow('Duración', _durationLabel(t)),
        _infoRow('Profesional responsable', t.appliedBy),
      ],
    );
  }

  Widget _buildPatientSection() {
    final h = hive;
    return _sectionCard(
      icon: Icons.hive_rounded,
      title: 'Información de la Colmena',
      children: [
        _infoRow('Colmena', '#$hiveNumber'),
        _infoRow('Estado de la colmena', h?.hiveStatus),
        _infoRow('Salud', h?.healthStatus),
        _infoRow('Nivel de actividad', h?.activityLevel),
        _infoRow('Población', h?.beePopulation),
        _infoRow('Cuadros de alimento', h?.foodFrames?.toString()),
        _infoRow('Cuadros de cría', h?.broodFrames?.toString()),
        if (h?.observations != null && h!.observations!.trim().isNotEmpty)
          _infoRow('Observaciones', h.observations),
      ],
    );
  }

  Widget _buildDetailsSection(Treatment t) {
    return _sectionCard(
      icon: Icons.description_outlined,
      title: 'Detalles del Tratamiento',
      children: [
        _infoRow('Enfermedad / objetivo', t.targetDisease),
        _infoRow('Ingrediente activo', t.activeIngredient),
        _infoRow('Método de aplicación', t.applicationMethod),
        _infoRow(
            'Dosis aplicada',
            (t.dosageApplied != null)
                ? '${t.dosageApplied} ${t.dosageUnit ?? ''}'.trim()
                : null),
        _infoRow('Número de lote', t.batchNumber),
        _infoRow('Proveedor', t.supplier),
        _infoRow('Fecha de vencimiento', _dateOrNull(t.expiryDate)),
        _infoRow('Recomendaciones futuras', t.futureRecommendations),
      ],
    );
  }

  Widget _buildFollowupSummarySection(Treatment t) {
    final followups = t.followups;
    return _sectionCard(
      icon: Icons.timeline_rounded,
      title: 'Seguimiento',
      children: [
        _infoRow('Sesiones / revisiones realizadas', followups.length.toString()),
        _infoRow('Resultado final', t.finalResult),
        _infoRow('Condición final de la colmena', t.finalHiveCondition),
        _infoRow('Requiere repetición', t.requiresRepeat ? 'Sí' : 'No'),
        _infoRow('Fecha de registro', _dateTimeOrNull(t.registrationDate)),
        _infoRow('Última actualización', _dateTimeOrNull(t.updateDate)),
      ],
    );
  }

  Widget _buildHistorySection(BuildContext context, WidgetRef ref, Treatment t) {
    final sorted = t.followups.toList()
      ..sort((a, b) => b.reviewDate.compareTo(a.reviewDate));
    return _sectionCard(
      icon: Icons.history_rounded,
      title: 'Historial de Seguimientos',
      trailing: TextButton.icon(
        onPressed: () => _addFollowup(context, t),
        icon: const Icon(Icons.add, size: 18),
        label: Text('Agregar', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        style: TextButton.styleFrom(foregroundColor: Colors.green.shade700),
      ),
      children: [
        if (sorted.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text('No hay registros históricos aún.',
                style: GoogleFonts.poppins(
                    color: Colors.grey.shade500, fontStyle: FontStyle.italic)),
          )
        else
          ...sorted.map((f) => _buildHistoryItem(context, ref, t, f)),
      ],
    );
  }

  Widget _buildHistoryItem(BuildContext context, WidgetRef ref, Treatment t, Followup f) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.event_rounded, size: 16, color: Colors.green.shade700),
              const SizedBox(width: 6),
              Text(DateFormat('dd/MM/yyyy').format(f.reviewDate),
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold, color: Colors.green.shade800)),
              const Spacer(),
              if (f.reviewer != null && f.reviewer!.trim().isNotEmpty)
                Flexible(
                  child: Text(f.reviewer!,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                          fontSize: 12, color: Colors.grey.shade600)),
                ),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert_rounded, size: 18, color: Colors.grey.shade500),
                onSelected: (value) {
                  if (value == 'edit') _editFollowup(context, t, f);
                  if (value == 'delete') _deleteFollowup(context, ref, t, f);
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(children: [
                      const Icon(Icons.edit_rounded, size: 18, color: Colors.blueGrey),
                      const SizedBox(width: 8),
                      Text('Editar', style: GoogleFonts.poppins()),
                    ]),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(children: [
                      const Icon(Icons.delete_rounded, size: 18, color: Colors.red),
                      const SizedBox(width: 8),
                      Text('Eliminar', style: GoogleFonts.poppins()),
                    ]),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (f.hiveCondition != null && f.hiveCondition!.trim().isNotEmpty)
            _historyLine('Condición', f.hiveCondition!),
          if (f.observedChanges != null && f.observedChanges!.trim().isNotEmpty)
            _historyLine('Cambio realizado', f.observedChanges!),
          if (f.partialResults != null && f.partialResults!.trim().isNotEmpty)
            _historyLine('Resultados parciales', f.partialResults!),
          if (f.infestationLevel != null && f.infestationLevel!.trim().isNotEmpty)
            _historyLine('Nivel de infestación', f.infestationLevel!),
          if (f.notes != null && f.notes!.trim().isNotEmpty)
            _historyLine('Observaciones', f.notes!),
        ],
      ),
    );
  }

  Widget _historyLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: RichText(
        text: TextSpan(
          style: GoogleFonts.poppins(fontSize: 13, color: Colors.black87),
          children: [
            TextSpan(
                text: '$label: ',
                style: const TextStyle(fontWeight: FontWeight.w600)),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }

  Widget _buildEditButton(BuildContext context, Treatment t) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _edit(context, t),
        icon: const Icon(Icons.edit_rounded),
        label: Text('Editar tratamiento',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.amber.shade700,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Widgets reutilizables
  // ---------------------------------------------------------------------------

  Widget _sectionCard({
    required IconData icon,
    required String title,
    required List<Widget> children,
    Widget? trailing,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _amber.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: Colors.amber.shade800, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(title,
                    style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade900)),
              ),
              ?trailing,
            ],
          ),
          const Divider(height: 24),
          ...children,
        ],
      ),
    );
  }

  Widget _infoRow(String label, String? value) {
    final bool empty = (value == null || value.trim().isEmpty);
    final display = empty ? 'No especificado' : value.trim();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 170,
            child: Text(label,
                style: GoogleFonts.poppins(
                    fontSize: 13, color: Colors.grey.shade600, height: 1.35)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              display,
              style: GoogleFonts.poppins(
                fontSize: 13.5,
                height: 1.35,
                fontWeight: empty ? FontWeight.w400 : FontWeight.w600,
                color: empty ? Colors.grey.shade400 : Colors.grey.shade900,
                fontStyle: empty ? FontStyle.italic : FontStyle.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers de formato
  // ---------------------------------------------------------------------------

  String _shortCode(String id) {
    if (id.isEmpty) return 'N/D';
    final clean = id.replaceAll('-', '');
    return 'TR-${clean.substring(0, clean.length >= 8 ? 8 : clean.length).toUpperCase()}';
  }

  String _date(DateTime d) => DateFormat('dd/MM/yyyy').format(d);

  String? _dateOrNull(DateTime? d) => d == null ? null : DateFormat('dd/MM/yyyy').format(d);

  String? _dateTimeOrNull(DateTime? d) =>
      d == null ? null : DateFormat('dd/MM/yyyy HH:mm').format(d);

  String _durationLabel(Treatment t) {
    if (t.endDate != null) {
      final days = t.endDate!.difference(t.startDate).inDays;
      if (days >= 0) return '$days día(s)';
    }
    if (t.estimatedDurationDays != null) {
      return '${t.estimatedDurationDays} día(s) (estimado)';
    }
    return 'No definida';
  }

  // ---------------------------------------------------------------------------
  // Acciones
  // ---------------------------------------------------------------------------

  void _edit(BuildContext context, Treatment t) {
    showDialog(
      context: context,
      builder: (_) => TreatmentFormDialog(
        hiveId: t.hiveId,
        hiveNumber: hiveNumber,
        treatment: t,
      ),
    );
  }

  void _addFollowup(BuildContext context, Treatment t) {
    showDialog(
      context: context,
      builder: (_) => FollowupFormDialog(
        treatmentId: t.id,
        productName: t.productName,
      ),
    );
  }

  void _editFollowup(BuildContext context, Treatment t, Followup f) {
    showDialog(
      context: context,
      builder: (_) => FollowupFormDialog(
        treatmentId: t.id,
        productName: t.productName,
        followup: f,
      ),
    );
  }

  void _deleteFollowup(BuildContext context, WidgetRef ref, Treatment t, Followup f) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Eliminar seguimiento',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text(
          '¿Deseas eliminar este registro de seguimiento del ${DateFormat('dd/MM/yyyy').format(f.reviewDate)}? Esta acción no se puede deshacer.',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancelar', style: GoogleFonts.poppins(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600, foregroundColor: Colors.white),
            child: Text('Eliminar', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      ref.read(treatmentsControllerProvider.notifier).deleteFollowup(t.id, f.id);
    }
  }

  void _exportReport(BuildContext context, Treatment t) {
    final buffer = StringBuffer()
      ..writeln('INFORME DE TRATAMIENTO')
      ..writeln('=======================')
      ..writeln('Producto: ${t.productName}')
      ..writeln('Tipo: ${t.treatmentType}')
      ..writeln('Código: ${_shortCode(t.id)}')
      ..writeln('Estado: ${TreatmentStatus.label(t.status)}')
      ..writeln('Colmena: #$hiveNumber')
      ..writeln('Inicio: ${_date(t.startDate)}')
      ..writeln('Fin: ${_dateOrNull(t.endDate) ?? 'No definida'}')
      ..writeln('Duración: ${_durationLabel(t)}')
      ..writeln('Responsable: ${t.appliedBy ?? 'No especificado'}')
      ..writeln('')
      ..writeln('DETALLES')
      ..writeln('Enfermedad/objetivo: ${t.targetDisease ?? 'No especificado'}')
      ..writeln('Ingrediente activo: ${t.activeIngredient ?? 'No especificado'}')
      ..writeln('Método de aplicación: ${t.applicationMethod ?? 'No especificado'}')
      ..writeln(
          'Dosis: ${t.dosageApplied != null ? '${t.dosageApplied} ${t.dosageUnit ?? ''}'.trim() : 'No especificado'}')
      ..writeln('Lote: ${t.batchNumber ?? 'No especificado'}')
      ..writeln('Proveedor: ${t.supplier ?? 'No especificado'}')
      ..writeln('Vencimiento: ${_dateOrNull(t.expiryDate) ?? 'No especificado'}')
      ..writeln('')
      ..writeln('SEGUIMIENTO')
      ..writeln('Resultado final: ${t.finalResult ?? 'No especificado'}')
      ..writeln('Condición final: ${t.finalHiveCondition ?? 'No especificado'}')
      ..writeln('Requiere repetición: ${t.requiresRepeat ? 'Sí' : 'No'}')
      ..writeln('Recomendaciones: ${t.futureRecommendations ?? 'No especificado'}')
      ..writeln('')
      ..writeln('HISTORIAL (${t.followups.length})');
    for (final f in t.followups) {
      buffer.writeln('- ${_date(f.reviewDate)} | ${f.hiveCondition ?? ''} | ${f.notes ?? ''}');
    }

    Clipboard.setData(ClipboardData(text: buffer.toString()));
    _showSnack(context, 'Informe copiado al portapapeles', Colors.blueGrey.shade700);
  }
}
