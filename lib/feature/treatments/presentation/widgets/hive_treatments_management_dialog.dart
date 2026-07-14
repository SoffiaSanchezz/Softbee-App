import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../domain/entities/treatment.dart';
import '../providers/treatment_providers.dart';
import 'treatment_form_dialog.dart';
import 'followup_form_dialog.dart';

class HiveTreatmentsManagementDialog extends ConsumerStatefulWidget {
  final String hiveId;
  final int hiveNumber;

  const HiveTreatmentsManagementDialog({
    super.key,
    required this.hiveId,
    required this.hiveNumber,
  });

  @override
  ConsumerState<HiveTreatmentsManagementDialog> createState() => _HiveTreatmentsManagementDialogState();
}

class _HiveTreatmentsManagementDialogState extends ConsumerState<HiveTreatmentsManagementDialog> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(treatmentsControllerProvider.notifier).fetchTreatments(widget.hiveId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(treatmentsControllerProvider);

    ref.listen(treatmentsControllerProvider, (previous, next) {
      if (next.successMessage != null && previous?.successMessage != next.successMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.successMessage!, style: GoogleFonts.poppins()),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        ref.read(treatmentsControllerProvider.notifier).clearMessages();
      }

      if (next.errorMessage != null && previous?.errorMessage != next.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!, style: GoogleFonts.poppins()),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        ref.read(treatmentsControllerProvider.notifier).clearMessages();
      }
    });

    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titlePadding: EdgeInsets.zero,
      contentPadding: EdgeInsets.zero,
      title: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        decoration: BoxDecoration(
          color: Colors.amber.shade600,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Gestión de Salud',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Colmena #${widget.hiveNumber}',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_rounded, color: Colors.white, size: 32),
              onPressed: () => _showAddTreatment(context),
              tooltip: 'Registrar Tratamiento',
            ),
          ],
        ),
      ),
      content: Container(
        width: 650,
        height: 600,
        padding: const EdgeInsets.all(16),
        child: state.isLoading
            ? const Center(child: CircularProgressIndicator())
            : state.treatments.isEmpty
                ? _buildEmptyState()
                : _buildTreatmentsList(state.treatments),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cerrar', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.amber.shade800)),
        ),
      ],
    ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack).fadeIn();
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.medication_outlined, size: 80, color: Colors.amber.shade100),
          const SizedBox(height: 16),
          Text(
            'Sin tratamientos activos',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.amber.shade900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Usa el botón + para registrar uno nuevo.',
            style: GoogleFonts.poppins(color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildTreatmentsList(List<Treatment> treatments) {
    return ListView.builder(
      itemCount: treatments.length,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemBuilder: (context, index) {
        final treatment = treatments[index];
        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              title: Text(
                treatment.productName,
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '${treatment.treatmentType} • Inicio: ${DateFormat('dd/MM/yyyy').format(treatment.startDate)}',
                  style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade600),
                ),
              ),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (treatment.status == 'Completado' ? Colors.green : Colors.orange).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  treatment.status == 'Completado' ? Icons.check_circle_rounded : Icons.pending_actions_rounded,
                  color: treatment.status == 'Completado' ? Colors.green : Colors.orange,
                ),
              ),
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailItem(Icons.info_outline_rounded, 'Estado', treatment.status),
                      if (treatment.activeIngredient != null) _buildDetailItem(Icons.science_outlined, 'Ingrediente', treatment.activeIngredient!),
                      if (treatment.targetDisease != null) _buildDetailItem(Icons.bug_report_outlined, 'Combate', treatment.targetDisease!),
                      if (treatment.dosageApplied != null) _buildDetailItem(Icons.scale_outlined, 'Dosis', '${treatment.dosageApplied} ${treatment.dosageUnit ?? ''}'),
                      
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Divider(),
                      ),
                      
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Historial de Seguimientos', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14)),
                          ElevatedButton.icon(
                            onPressed: () => _showAddFollowup(treatment.id, treatment.productName),
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('Seguimiento'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade600,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              textStyle: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (treatment.followups.isEmpty)
                        Center(
                          child: Text(
                            'No hay registros aún.',
                            style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade500, fontStyle: FontStyle.italic),
                          ),
                        )
                      else
                        ...treatment.followups.map((f) => _buildFollowupItem(f)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ).animate().fadeIn(delay: (index * 100).ms).slideX(begin: 0.1, end: 0);
      },
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Text('$label: ', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
          Text(value, style: GoogleFonts.poppins(fontSize: 13, color: Colors.black87)),
        ],
      ),
    );
  }

  Widget _buildFollowupItem(dynamic followup) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DateFormat('dd/MM/yyyy').format(followup.reviewDate),
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.green.shade700),
              ),
              if (followup.reviewer != null)
                Text(followup.reviewer!, style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            followup.hiveCondition ?? 'Sin notas de condición',
            style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500),
          ),
          if (followup.notes != null && followup.notes!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                followup.notes!,
                style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600),
              ),
            ),
        ],
      ),
    );
  }

  void _showAddTreatment(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => TreatmentFormDialog(
        hiveId: widget.hiveId,
        hiveNumber: widget.hiveNumber,
      ),
    ).then((_) {
      ref.read(treatmentsControllerProvider.notifier).fetchTreatments(widget.hiveId);
    });
  }

  void _showAddFollowup(String treatmentId, String productName) {
    showDialog(
      context: context,
      builder: (context) => FollowupFormDialog(
        treatmentId: treatmentId,
        productName: productName,
      ),
    ).then((_) {
      ref.read(treatmentsControllerProvider.notifier).fetchTreatments(widget.hiveId);
    });
  }
}
