import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:Softbee/feature/beehive/domain/entities/beehive.dart';
import '../../domain/entities/treatment.dart';
import '../controllers/treatments_controller.dart';
import '../pages/treatment_detail_page.dart';
import '../providers/treatment_providers.dart';
import 'treatment_form_dialog.dart';
import 'treatment_status.dart';

/// Listado de tratamientos de una colmena con búsqueda, filtros, paginación y
/// acciones CRUD (ver informe, editar, eliminar).
class HiveTreatmentsManagementDialog extends ConsumerStatefulWidget {
  final String hiveId;
  final int hiveNumber;
  final Beehive? hive;

  const HiveTreatmentsManagementDialog({
    super.key,
    required this.hiveId,
    required this.hiveNumber,
    this.hive,
  });

  @override
  ConsumerState<HiveTreatmentsManagementDialog> createState() =>
      _HiveTreatmentsManagementDialogState();
}

class _HiveTreatmentsManagementDialogState
    extends ConsumerState<HiveTreatmentsManagementDialog> {
  static const int _pageSize = 5;

  final _searchController = TextEditingController();
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(treatmentsControllerProvider.notifier)
        ..resetFilters()
        ..fetchTreatments(widget.hiveId);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _listenMessages() {
    ref.listen(treatmentsControllerProvider, (previous, next) {
      if (next.successMessage != null &&
          previous?.successMessage != next.successMessage) {
        _showSnack(next.successMessage!, Colors.green.shade600);
        ref.read(treatmentsControllerProvider.notifier).clearMessages();
      }
      if (next.errorMessage != null &&
          previous?.errorMessage != next.errorMessage) {
        _showSnack(next.errorMessage!, Colors.red.shade600);
        ref.read(treatmentsControllerProvider.notifier).clearMessages();
      }
    });
  }

  void _showSnack(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.poppins()),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _listenMessages();
    final state = ref.watch(treatmentsControllerProvider);

    final Size screenSize = MediaQuery.of(context).size;
    final bool isMobile = screenSize.width < 600;
    final double horizontalInset = isMobile ? 12 : 40;
    final double dialogWidth =
        isMobile ? screenSize.width - (horizontalInset * 2) : 680;
    final double dialogHeight = isMobile ? screenSize.height * 0.82 : 640;

    final filtered = state.filteredTreatments;
    final totalPages = (filtered.length / _pageSize).ceil();
    if (_currentPage >= totalPages && _currentPage > 0) {
      _currentPage = totalPages - 1;
    }
    final pageItems = filtered
        .skip(_currentPage * _pageSize)
        .take(_pageSize)
        .toList();

    return AlertDialog(
      backgroundColor: Colors.white,
      insetPadding: EdgeInsets.symmetric(horizontal: horizontalInset, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titlePadding: EdgeInsets.zero,
      contentPadding: EdgeInsets.zero,
      title: _buildHeader(isMobile, state.treatments.length),
      content: SizedBox(
        width: dialogWidth,
        height: dialogHeight,
        child: Column(
          children: [
            _buildSearchAndFilters(state),
            Expanded(
              child: state.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : state.treatments.isEmpty
                      ? _buildEmptyState(hasFilters: false)
                      : filtered.isEmpty
                          ? _buildEmptyState(hasFilters: true)
                          : _buildList(pageItems, isMobile),
            ),
            if (totalPages > 1) _buildPagination(totalPages, filtered.length),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cerrar',
              style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600, color: Colors.amber.shade800)),
        ),
      ],
    ).animate().scale(duration: 350.ms, curve: Curves.easeOutBack).fadeIn();
  }

  Widget _buildHeader(bool isMobile, int total) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 18 : 24, vertical: isMobile ? 16 : 20),
      decoration: BoxDecoration(
        color: Colors.amber.shade600,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tratamientos',
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white)),
                Text('Colmena #${widget.hiveNumber} • $total registrado(s)',
                    style: GoogleFonts.poppins(
                        fontSize: 13, color: Colors.white.withValues(alpha: 0.9))),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: _showAddTreatment,
            icon: const Icon(Icons.add_rounded, size: 20),
            label: Text('Nuevo', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.amber.shade800,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters(TreatmentsState state) {
    final filters = ['Todos', ...TreatmentStatus.options];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            onChanged: (value) {
              ref.read(treatmentsControllerProvider.notifier).setSearchQuery(value);
              setState(() => _currentPage = 0);
            },
            style: GoogleFonts.poppins(fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Buscar por producto, tipo, responsable...',
              hintStyle: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade400),
              prefixIcon: Icon(Icons.search_rounded, color: Colors.amber.shade700),
              suffixIcon: _searchController.text.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        ref
                            .read(treatmentsControllerProvider.notifier)
                            .setSearchQuery('');
                        setState(() => _currentPage = 0);
                      },
                    ),
              isDense: true,
              filled: true,
              fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.amber.shade700, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: filters.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final label = filters[index];
                final selected = state.statusFilter == label;
                final color =
                    label == 'Todos' ? Colors.amber.shade700 : TreatmentStatus.color(label);
                return ChoiceChip(
                  label: Text(label,
                      style: GoogleFonts.poppins(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: selected ? Colors.white : Colors.grey.shade700)),
                  selected: selected,
                  showCheckmark: false,
                  backgroundColor: Colors.grey.shade100,
                  selectedColor: color,
                  side: BorderSide(color: selected ? color : Colors.grey.shade200),
                  onSelected: (_) {
                    ref
                        .read(treatmentsControllerProvider.notifier)
                        .setStatusFilter(label);
                    setState(() => _currentPage = 0);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(List<Treatment> items, bool isMobile) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      itemCount: items.length,
      itemBuilder: (context, index) => _buildTreatmentCard(items[index], index, isMobile),
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: Colors.grey.shade400),
            const SizedBox(width: 5),
            Text(
              label.toUpperCase(),
              style: GoogleFonts.poppins(
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade400,
                letterSpacing: 0.6,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF334155), // slate 700
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildTreatmentCard(Treatment t, int index, bool isMobile) {
    final color = TreatmentStatus.color(t.status);
    
    final startItem = _buildDetailItem(
      Icons.play_arrow_rounded,
      'Inicio',
      DateFormat('dd/MM/yyyy').format(t.startDate),
    );
    final endItem = _buildDetailItem(
      Icons.stop_rounded,
      'Fin',
      t.endDate != null ? DateFormat('dd/MM/yyyy').format(t.endDate!) : '—',
    );
    final respItem = _buildDetailItem(
      Icons.person_rounded,
      'Responsable',
      (t.appliedBy != null && t.appliedBy!.trim().isNotEmpty) ? t.appliedBy! : '—',
    );
    final updateItem = t.updateDate != null
        ? _buildDetailItem(
            Icons.update_rounded,
            'Actualizado',
            DateFormat('dd/MM/yyyy').format(t.updateDate!),
          )
        : null;

    final details = <Widget>[startItem, endItem, respItem, ?updateItem];

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: color.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Franja lateral de estado: refuerza la jerarquía visual.
            Container(
              width: 5,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [color, color.withValues(alpha: 0.55)],
                ),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Encabezado: icono + producto (título) + tipo + estado.
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 14, 12),
                    child: Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            TreatmentStatus.icon(t.status),
                            color: color,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                t.productName,
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16.5,
                                  height: 1.15,
                                  color: const Color(0xFF0F172A), // slate 900
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.local_offer_rounded,
                                      size: 12, color: Colors.grey.shade400),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      t.treatmentType,
                                      style: GoogleFonts.poppins(
                                        fontSize: 12.5,
                                        color: Colors.grey.shade600,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        _statusChip(t.status),
                      ],
                    ),
                  ),
                  // Información clave (fechas, responsable, actualización).
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 2, 16, 0),
                    child: isMobile
                        ? Column(
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(child: details[0]),
                                  const SizedBox(width: 16),
                                  Expanded(child: details[1]),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(child: details[2]),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: details.length > 3
                                        ? details[3]
                                        : const SizedBox.shrink(),
                                  ),
                                ],
                              ),
                            ],
                          )
                        : _buildDesktopDetailsRow(details),
                  ),
                  const SizedBox(height: 14),
                  Divider(height: 1, thickness: 1, color: Colors.grey.shade100),
                  // Acciones: Ver / Editar / Eliminar (envuelven en pantallas
                  // estrechas para evitar overflow).
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                    child: Wrap(
                      alignment: WrapAlignment.end,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _actionButton(
                          icon: Icons.visibility_rounded,
                          label: 'Ver',
                          color: Colors.blueGrey.shade600,
                          onPressed: () => _openDetail(t),
                        ),
                        _actionButton(
                          icon: Icons.edit_rounded,
                          label: 'Editar',
                          color: Colors.amber.shade800,
                          onPressed: () => _showEditTreatment(t),
                        ),
                        _actionButton(
                          icon: Icons.delete_rounded,
                          label: 'Eliminar',
                          color: Colors.red.shade600,
                          onPressed: () => _confirmDelete(t),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: (index * 60).ms).slideY(begin: 0.05, end: 0);
  }

  /// Distribuye los bloques de información en una fila con separadores
  /// verticales sutiles (solo escritorio/tablet).
  Widget _buildDesktopDetailsRow(List<Widget> details) {
    final children = <Widget>[];
    for (var i = 0; i < details.length; i++) {
      children.add(Expanded(child: details[i]));
      if (i != details.length - 1) {
        children.add(Container(
          width: 1,
          height: 30,
          margin: const EdgeInsets.symmetric(horizontal: 12),
          color: Colors.grey.shade200,
        ));
      }
    }
    return Row(crossAxisAlignment: CrossAxisAlignment.center, children: children);
  }

  Widget _statusChip(String? status) {
    final color = TreatmentStatus.color(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            TreatmentStatus.label(status),
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 17, color: color),
      label: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
      style: TextButton.styleFrom(
        backgroundColor: color.withValues(alpha: 0.10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        minimumSize: const Size(0, 38),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: color.withValues(alpha: 0.18)),
        ),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }

  Widget _buildPagination(int totalPages, int totalItems) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('$totalItems tratamiento(s)',
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600)),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left_rounded),
                onPressed: _currentPage > 0
                    ? () => setState(() => _currentPage--)
                    : null,
                color: Colors.amber.shade800,
              ),
              Text('${_currentPage + 1} / $totalPages',
                  style: GoogleFonts.poppins(
                      fontSize: 13, fontWeight: FontWeight.w600)),
              IconButton(
                icon: const Icon(Icons.chevron_right_rounded),
                onPressed: _currentPage < totalPages - 1
                    ? () => setState(() => _currentPage++)
                    : null,
                color: Colors.amber.shade800,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({required bool hasFilters}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(hasFilters ? Icons.filter_alt_off_rounded : Icons.medication_outlined,
                size: 72, color: Colors.amber.shade100),
            const SizedBox(height: 16),
            Text(
              hasFilters ? 'Sin coincidencias' : 'Sin tratamientos registrados',
              style: GoogleFonts.poppins(
                  fontSize: 17, fontWeight: FontWeight.bold, color: Colors.amber.shade900),
            ),
            const SizedBox(height: 8),
            Text(
              hasFilters
                  ? 'Ajusta la búsqueda o los filtros para ver más resultados.'
                  : 'Usa el botón "Nuevo" para registrar el primer tratamiento.',
              style: GoogleFonts.poppins(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Acciones
  // ---------------------------------------------------------------------------

  void _openDetail(Treatment t) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TreatmentDetailPage(
          treatmentId: t.id,
          hiveNumber: widget.hiveNumber,
          hive: widget.hive,
        ),
      ),
    );
  }

  void _showAddTreatment() {
    showDialog(
      context: context,
      builder: (_) => TreatmentFormDialog(
        hiveId: widget.hiveId,
        hiveNumber: widget.hiveNumber,
      ),
    );
  }

  void _showEditTreatment(Treatment t) {
    showDialog(
      context: context,
      builder: (_) => TreatmentFormDialog(
        hiveId: widget.hiveId,
        hiveNumber: widget.hiveNumber,
        treatment: t,
      ),
    );
  }

  Future<void> _confirmDelete(Treatment t) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red.shade600),
            const SizedBox(width: 10),
            Text('Eliminar tratamiento',
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: Text(
          '¿Estás seguro de que deseas eliminar el tratamiento "${t.productName}"? Esta acción no se puede deshacer.',
          style: GoogleFonts.poppins(height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancelar', style: GoogleFonts.poppins(color: Colors.grey.shade600)),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.delete_rounded, size: 18),
            label: Text('Eliminar', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600, foregroundColor: Colors.white),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(treatmentsControllerProvider.notifier).deleteTreatment(t.id);
    }
  }
}
