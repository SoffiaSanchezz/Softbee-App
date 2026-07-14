import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/treatment_providers.dart';

class FollowupFormDialog extends ConsumerStatefulWidget {
  final String treatmentId;
  final String productName;

  const FollowupFormDialog({
    super.key,
    required this.treatmentId,
    required this.productName,
  });

  @override
  ConsumerState<FollowupFormDialog> createState() => _FollowupFormDialogState();
}

class _FollowupFormDialogState extends ConsumerState<FollowupFormDialog> {
  final _formKey = GlobalKey<FormState>();
  
  final _hiveConditionController = TextEditingController();
  final _observedChangesController = TextEditingController();
  final _partialResultsController = TextEditingController();
  final _infestationLevelController = TextEditingController();
  final _notesController = TextEditingController();
  final _reviewerController = TextEditingController();
  
  DateTime _reviewDate = DateTime.now();

  @override
  void dispose() {
    _hiveConditionController.dispose();
    _observedChangesController.dispose();
    _partialResultsController.dispose();
    _infestationLevelController.dispose();
    _notesController.dispose();
    _reviewerController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _reviewDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.amber.shade700,
              onPrimary: Colors.white,
              onSurface: Colors.amber.shade900,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _reviewDate) {
      setState(() {
        _reviewDate = picked;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final data = {
      'treatment_id': widget.treatmentId,
      'review_date': DateFormat('yyyy-MM-dd').format(_reviewDate),
      'hive_condition': _hiveConditionController.text.isEmpty ? null : _hiveConditionController.text,
      'observed_changes': _observedChangesController.text.isEmpty ? null : _observedChangesController.text,
      'partial_results': _partialResultsController.text.isEmpty ? null : _partialResultsController.text,
      'infestation_level': _infestationLevelController.text.isEmpty ? null : _infestationLevelController.text,
      'notes': _notesController.text.isEmpty ? null : _notesController.text,
      'reviewer': _reviewerController.text.isEmpty ? null : _reviewerController.text,
    };

    await ref.read(treatmentsControllerProvider.notifier).addFollowup(data);
    
    if (mounted) {
      final state = ref.read(treatmentsControllerProvider);
      if (state.errorMessage == null) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(treatmentsControllerProvider);

    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titlePadding: EdgeInsets.zero,
      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      title: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Icon(Icons.fact_check_rounded, color: Colors.green.shade700, size: 40),
            const SizedBox(height: 8),
            Text(
              'Nuevo Seguimiento',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 22,
                color: Colors.green.shade900,
              ),
            ),
            Text(
              widget.productName,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.green.shade800,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDatePickerTile(
                  'Fecha de Revisión',
                  _reviewDate,
                  () => _selectDate(context),
                ),
                const SizedBox(height: 12),
                _buildTextField(_hiveConditionController, 'Condición de la Colmena', 'Ej: Activa, Débil', Icons.health_and_safety_rounded),
                _buildTextField(_observedChangesController, 'Cambios Observados', 'Ej: Menos varroa', Icons.analytics_rounded),
                _buildTextField(_partialResultsController, 'Resultados Parciales', '', Icons.rule_rounded),
                _buildTextField(_infestationLevelController, 'Nivel de Infestación', 'Ej: 2%', Icons.bug_report_rounded),
                _buildTextField(_notesController, 'Notas adicionales', '', Icons.notes_rounded, maxLines: 3),
                _buildTextField(_reviewerController, 'Revisado por', '', Icons.person_search_rounded),
                
                if (state.errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(
                      state.errorMessage!,
                      style: GoogleFonts.poppins(color: Colors.red, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancelar', style: GoogleFonts.poppins(color: Colors.grey.shade600)),
        ),
        ElevatedButton(
          onPressed: state.isCreating ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green.shade700,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: state.isCreating 
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
            : Text('Guardar Seguimiento', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        ),
      ],
    ).animate().scale(duration: 300.ms, curve: Curves.easeOutBack).fadeIn();
  }

  Widget _buildDatePickerTile(String label, DateTime date, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(label, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600)),
        subtitle: Text(
          DateFormat('dd/MM/yyyy').format(date),
          style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.black87),
        ),
        trailing: Icon(Icons.calendar_month_rounded, color: Colors.green.shade700),
        onTap: onTap,
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, String hint, IconData icon, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        style: GoogleFonts.poppins(fontSize: 15),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, color: Colors.green.shade700, size: 20),
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
            borderSide: BorderSide(color: Colors.green.shade700, width: 2),
          ),
          labelStyle: GoogleFonts.poppins(color: Colors.grey.shade700, fontSize: 14),
          hintStyle: GoogleFonts.poppins(color: Colors.grey.shade400, fontSize: 13),
        ),
      ),
    );
  }
}
