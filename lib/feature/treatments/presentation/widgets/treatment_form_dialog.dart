import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/treatment_providers.dart';

class TreatmentFormDialog extends ConsumerStatefulWidget {
  final String hiveId;
  final int hiveNumber;

  const TreatmentFormDialog({
    super.key,
    required this.hiveId,
    required this.hiveNumber,
  });

  @override
  ConsumerState<TreatmentFormDialog> createState() => _TreatmentFormDialogState();
}

class _TreatmentFormDialogState extends ConsumerState<TreatmentFormDialog> {
  final _formKey = GlobalKey<FormState>();
  
  final _treatmentTypeController = TextEditingController();
  final _productNameController = TextEditingController();
  final _activeIngredientController = TextEditingController();
  final _targetDiseaseController = TextEditingController();
  final _estimatedDurationController = TextEditingController();
  final _applicationMethodController = TextEditingController();
  final _dosageAppliedController = TextEditingController();
  final _dosageUnitController = TextEditingController();
  final _batchNumberController = TextEditingController();
  final _supplierController = TextEditingController();
  final _appliedByController = TextEditingController();
  
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  DateTime? _expiryDate;

  @override
  void dispose() {
    _treatmentTypeController.dispose();
    _productNameController.dispose();
    _activeIngredientController.dispose();
    _targetDiseaseController.dispose();
    _estimatedDurationController.dispose();
    _applicationMethodController.dispose();
    _dosageAppliedController.dispose();
    _dosageUnitController.dispose();
    _batchNumberController.dispose();
    _supplierController.dispose();
    _appliedByController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, DateTime initialDate, Function(DateTime) onSelected) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
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
    if (picked != null) {
      setState(() {
        onSelected(picked);
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final data = {
      'hive_id': widget.hiveId,
      'treatment_type': _treatmentTypeController.text,
      'product_name': _productNameController.text,
      'start_date': DateFormat('yyyy-MM-dd').format(_startDate),
      'active_ingredient': _activeIngredientController.text.isEmpty ? null : _activeIngredientController.text,
      'target_disease': _targetDiseaseController.text.isEmpty ? null : _targetDiseaseController.text,
      'estimated_duration_days': int.tryParse(_estimatedDurationController.text),
      'end_date': _endDate != null ? DateFormat('yyyy-MM-dd').format(_endDate!) : null,
      'application_method': _applicationMethodController.text.isEmpty ? null : _applicationMethodController.text,
      'dosage_applied': _dosageAppliedController.text.isEmpty ? null : _dosageAppliedController.text,
      'dosage_unit': _dosageUnitController.text.isEmpty ? null : _dosageUnitController.text,
      'batch_number': _batchNumberController.text.isEmpty ? null : _batchNumberController.text,
      'supplier': _supplierController.text.isEmpty ? null : _supplierController.text,
      'expiry_date': _expiryDate != null ? DateFormat('yyyy-MM-dd').format(_expiryDate!) : null,
      'applied_by': _appliedByController.text.isEmpty ? null : _appliedByController.text,
    };

    await ref.read(treatmentsControllerProvider.notifier).createTreatment(data);
    
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
          color: Colors.amber.shade50,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Icon(Icons.medication_rounded, color: Colors.amber.shade700, size: 40),
            const SizedBox(height: 8),
            Text(
              'Nuevo Tratamiento',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 22,
                color: Colors.amber.shade900,
              ),
            ),
            Text(
              'Colmena #${widget.hiveNumber}',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.amber.shade800,
              ),
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
                _buildSectionTitle('Información General'),
                _buildTextField(_treatmentTypeController, 'Tipo de Tratamiento*', 'Ej: Orgánico, Químico', Icons.category_rounded),
                _buildTextField(_productNameController, 'Nombre del Producto*', 'Ej: Apivar, Ácido Oxálico', Icons.inventory_2_rounded),
                _buildTextField(_activeIngredientController, 'Ingrediente Activo', 'Ej: Amitraz', Icons.science_rounded),
                _buildTextField(_targetDiseaseController, 'Enfermedad Objetivo', 'Ej: Varroa', Icons.bug_report_rounded),
                
                const SizedBox(height: 16),
                _buildSectionTitle('Fechas y Duración'),
                _buildDatePickerTile(
                  'Fecha de Inicio',
                  _startDate,
                  (date) => _startDate = date,
                ),
                _buildTextField(_estimatedDurationController, 'Duración Estimada (días)', 'Ej: 30', Icons.timer_rounded, keyboardType: TextInputType.number),
                _buildDatePickerTile(
                  'Fecha de Fin',
                  _endDate,
                  (date) => _endDate = date,
                  placeholder: 'No definida',
                ),
                
                const SizedBox(height: 16),
                _buildSectionTitle('Aplicación'),
                _buildTextField(_applicationMethodController, 'Método de Aplicación', 'Ej: Tiras, Goteo', Icons.handyman_rounded),
                Row(
                  children: [
                    Expanded(child: _buildTextField(_dosageAppliedController, 'Dosis', 'Ej: 2', Icons.scale_rounded)),
                    const SizedBox(width: 10),
                    Expanded(child: _buildTextField(_dosageUnitController, 'Unidad', 'Ej: Tiras', Icons.straighten_rounded)),
                  ],
                ),
                
                const SizedBox(height: 16),
                _buildSectionTitle('Detalles del Producto'),
                _buildTextField(_batchNumberController, 'Número de Lote', '', Icons.qr_code_rounded),
                _buildTextField(_supplierController, 'Proveedor', '', Icons.store_rounded),
                _buildDatePickerTile(
                  'Fecha de Vencimiento',
                  _expiryDate,
                  (date) => _expiryDate = date,
                  placeholder: 'No definida',
                ),
                
                const SizedBox(height: 16),
                _buildSectionTitle('Responsable'),
                _buildTextField(_appliedByController, 'Aplicado por', '', Icons.person_rounded),
                
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
            backgroundColor: Colors.amber.shade700,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: state.isCreating 
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
            : Text('Guardar Tratamiento', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        ),
      ],
    ).animate().scale(duration: 300.ms, curve: Curves.easeOutBack).fadeIn();
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 16,
            decoration: BoxDecoration(
              color: Colors.amber.shade700,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Colors.grey.shade800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDatePickerTile(String label, DateTime? date, Function(DateTime) onSelected, {String? placeholder}) {
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
          date != null ? DateFormat('dd/MM/yyyy').format(date) : (placeholder ?? 'Seleccionar fecha'),
          style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.black87),
        ),
        trailing: Icon(Icons.calendar_month_rounded, color: Colors.amber.shade700),
        onTap: () => _selectDate(context, date ?? DateTime.now(), onSelected),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, String hint, IconData icon, {TextInputType keyboardType = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: TextFormField(
        controller: controller,
        style: GoogleFonts.poppins(fontSize: 15),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, color: Colors.amber.shade700, size: 20),
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
          labelStyle: GoogleFonts.poppins(color: Colors.grey.shade700, fontSize: 14),
          hintStyle: GoogleFonts.poppins(color: Colors.grey.shade400, fontSize: 13),
        ),
        keyboardType: keyboardType,
        validator: (value) {
          if (label.endsWith('*') && (value == null || value.isEmpty)) {
            return 'Este campo es obligatorio';
          }
          return null;
        },
      ),
    );
  }
}
