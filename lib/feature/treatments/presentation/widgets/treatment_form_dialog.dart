import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../domain/entities/treatment.dart';
import '../providers/treatment_providers.dart';
import 'treatment_status.dart';

/// Formulario para crear o editar un tratamiento.
///
/// - Si [treatment] es `null` se comporta como formulario de creación.
/// - Si [treatment] tiene valor se comporta como formulario de edición:
///   precarga todos los datos y expone además los campos de cierre del
///   tratamiento (estado, resultado final, condición final, recomendaciones).
class TreatmentFormDialog extends ConsumerStatefulWidget {
  final String hiveId;
  final int hiveNumber;
  final Treatment? treatment;

  const TreatmentFormDialog({
    super.key,
    required this.hiveId,
    required this.hiveNumber,
    this.treatment,
  });

  bool get isEditing => treatment != null;

  @override
  ConsumerState<TreatmentFormDialog> createState() => _TreatmentFormDialogState();
}

class _TreatmentFormDialogState extends ConsumerState<TreatmentFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _treatmentTypeController;
  late final TextEditingController _productNameController;
  late final TextEditingController _activeIngredientController;
  late final TextEditingController _targetDiseaseController;
  late final TextEditingController _estimatedDurationController;
  late final TextEditingController _applicationMethodController;
  late final TextEditingController _dosageAppliedController;
  late final TextEditingController _dosageUnitController;
  late final TextEditingController _batchNumberController;
  late final TextEditingController _supplierController;
  late final TextEditingController _appliedByController;
  late final TextEditingController _finalResultController;
  late final TextEditingController _finalHiveConditionController;
  late final TextEditingController _futureRecommendationsController;

  late DateTime _startDate;
  DateTime? _endDate;
  DateTime? _expiryDate;
  late String _status;
  late bool _requiresRepeat;

  @override
  void initState() {
    super.initState();
    final t = widget.treatment;
    _treatmentTypeController = TextEditingController(text: t?.treatmentType ?? '');
    _productNameController = TextEditingController(text: t?.productName ?? '');
    _activeIngredientController = TextEditingController(text: t?.activeIngredient ?? '');
    _targetDiseaseController = TextEditingController(text: t?.targetDisease ?? '');
    _estimatedDurationController =
        TextEditingController(text: t?.estimatedDurationDays?.toString() ?? '');
    _applicationMethodController = TextEditingController(text: t?.applicationMethod ?? '');
    _dosageAppliedController = TextEditingController(text: t?.dosageApplied ?? '');
    _dosageUnitController = TextEditingController(text: t?.dosageUnit ?? '');
    _batchNumberController = TextEditingController(text: t?.batchNumber ?? '');
    _supplierController = TextEditingController(text: t?.supplier ?? '');
    _appliedByController = TextEditingController(text: t?.appliedBy ?? '');
    _finalResultController = TextEditingController(text: t?.finalResult ?? '');
    _finalHiveConditionController = TextEditingController(text: t?.finalHiveCondition ?? '');
    _futureRecommendationsController =
        TextEditingController(text: t?.futureRecommendations ?? '');

    _startDate = t?.startDate ?? DateTime.now();
    _endDate = t?.endDate;
    _expiryDate = t?.expiryDate;
    _status = t != null ? TreatmentStatus.label(t.status) : TreatmentStatus.active;
    _requiresRepeat = t?.requiresRepeat ?? false;
  }

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
    _finalResultController.dispose();
    _finalHiveConditionController.dispose();
    _futureRecommendationsController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(
      BuildContext context, DateTime initialDate, Function(DateTime) onSelected) async {
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
      setState(() => onSelected(picked));
    }
  }

  String? _text(TextEditingController c) => c.text.trim().isEmpty ? null : c.text.trim();

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final controller = ref.read(treatmentsControllerProvider.notifier);

    if (widget.isEditing) {
      final data = {
        'treatment_type': _treatmentTypeController.text.trim(),
        'product_name': _productNameController.text.trim(),
        'start_date': DateFormat('yyyy-MM-dd').format(_startDate),
        'active_ingredient': _text(_activeIngredientController),
        'target_disease': _text(_targetDiseaseController),
        'estimated_duration_days': int.tryParse(_estimatedDurationController.text.trim()),
        'end_date': _endDate != null ? DateFormat('yyyy-MM-dd').format(_endDate!) : null,
        'application_method': _text(_applicationMethodController),
        'dosage_applied': _text(_dosageAppliedController),
        'dosage_unit': _text(_dosageUnitController),
        'batch_number': _text(_batchNumberController),
        'supplier': _text(_supplierController),
        'expiry_date': _expiryDate != null ? DateFormat('yyyy-MM-dd').format(_expiryDate!) : null,
        'applied_by': _text(_appliedByController),
        'status': _status,
        'final_result': _text(_finalResultController),
        'final_hive_condition': _text(_finalHiveConditionController),
        'requires_repeat': _requiresRepeat,
        'future_recommendations': _text(_futureRecommendationsController),
      };
      await controller.updateTreatment(widget.treatment!.id, data);
    } else {
      final data = {
        'hive_id': widget.hiveId,
        'treatment_type': _treatmentTypeController.text.trim(),
        'product_name': _productNameController.text.trim(),
        'start_date': DateFormat('yyyy-MM-dd').format(_startDate),
        'active_ingredient': _text(_activeIngredientController),
        'target_disease': _text(_targetDiseaseController),
        'estimated_duration_days': int.tryParse(_estimatedDurationController.text.trim()),
        'end_date': _endDate != null ? DateFormat('yyyy-MM-dd').format(_endDate!) : null,
        'application_method': _text(_applicationMethodController),
        'dosage_applied': _text(_dosageAppliedController),
        'dosage_unit': _text(_dosageUnitController),
        'batch_number': _text(_batchNumberController),
        'supplier': _text(_supplierController),
        'expiry_date': _expiryDate != null ? DateFormat('yyyy-MM-dd').format(_expiryDate!) : null,
        'applied_by': _text(_appliedByController),
      };
      await controller.createTreatment(data);
    }

    if (mounted) {
      final state = ref.read(treatmentsControllerProvider);
      if (state.errorMessage == null) {
        Navigator.of(context).pop(true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(treatmentsControllerProvider);
    final bool isEditing = widget.isEditing;

    final Size screenSize = MediaQuery.of(context).size;
    final bool isMobile = screenSize.width < 600;
    final double dialogWidth = isMobile ? screenSize.width - 32 : 520;

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
            Icon(
              isEditing ? Icons.edit_note_rounded : Icons.medication_rounded,
              color: Colors.amber.shade700,
              size: 40,
            ),
            const SizedBox(height: 8),
            Text(
              isEditing ? 'Editar Tratamiento' : 'Nuevo Tratamiento',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 22,
                color: Colors.amber.shade900,
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              'Colmena #${widget.hiveNumber}',
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.amber.shade800),
            ),
          ],
        ),
      ),
      content: SizedBox(
        width: dialogWidth,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildSectionTitle('Información General'),
                _buildTextField(_treatmentTypeController, 'Tipo de Tratamiento*',
                    'Ej: Orgánico, Químico', Icons.category_rounded),
                _buildTextField(_productNameController, 'Nombre del Producto*',
                    'Ej: Apivar, Ácido Oxálico', Icons.inventory_2_rounded),
                _buildTextField(_activeIngredientController, 'Ingrediente Activo',
                    'Ej: Amitraz', Icons.science_rounded),
                _buildTextField(_targetDiseaseController, 'Enfermedad Objetivo',
                    'Ej: Varroa', Icons.bug_report_rounded),

                const SizedBox(height: 16),
                _buildSectionTitle('Fechas y Duración'),
                _buildDatePickerTile('Fecha de Inicio', _startDate, (date) => _startDate = date),
                _buildTextField(_estimatedDurationController, 'Duración Estimada (días)',
                    'Ej: 30', Icons.timer_rounded,
                    keyboardType: TextInputType.number),
                _buildDatePickerTile('Fecha de Fin', _endDate, (date) => _endDate = date,
                    placeholder: 'No definida'),

                const SizedBox(height: 16),
                _buildSectionTitle('Aplicación'),
                _buildTextField(_applicationMethodController, 'Método de Aplicación',
                    'Ej: Tiras, Goteo', Icons.handyman_rounded),
                Row(
                  children: [
                    Expanded(
                        child: _buildTextField(_dosageAppliedController, 'Dosis', 'Ej: 2',
                            Icons.scale_rounded)),
                    const SizedBox(width: 10),
                    Expanded(
                        child: _buildTextField(_dosageUnitController, 'Unidad', 'Ej: Tiras',
                            Icons.straighten_rounded)),
                  ],
                ),

                const SizedBox(height: 16),
                _buildSectionTitle('Detalles del Producto'),
                _buildTextField(
                    _batchNumberController, 'Número de Lote', '', Icons.qr_code_rounded),
                _buildTextField(_supplierController, 'Proveedor', '', Icons.store_rounded),
                _buildDatePickerTile(
                    'Fecha de Vencimiento', _expiryDate, (date) => _expiryDate = date,
                    placeholder: 'No definida'),

                const SizedBox(height: 16),
                _buildSectionTitle('Responsable'),
                _buildTextField(_appliedByController, 'Aplicado por', '', Icons.person_rounded),

                // Sección de cierre/seguimiento, solo en modo edición.
                if (isEditing) ...[
                  const SizedBox(height: 16),
                  _buildSectionTitle('Estado y Cierre'),
                  _buildStatusDropdown(),
                  _buildTextField(_finalResultController, 'Resultado Final',
                      'Ej: Infestación controlada', Icons.flag_rounded),
                  _buildTextField(_finalHiveConditionController, 'Condición Final de la Colmena',
                      'Ej: Saludable', Icons.health_and_safety_rounded),
                  _buildTextField(_futureRecommendationsController, 'Recomendaciones Futuras',
                      '', Icons.tips_and_updates_rounded, maxLines: 2),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('Requiere repetición',
                        style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade800)),
                    value: _requiresRepeat,
                    activeThumbColor: Colors.amber.shade700,
                    onChanged: (v) => setState(() => _requiresRepeat = v),
                  ),
                ],

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
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : Text(isEditing ? 'Guardar Cambios' : 'Guardar Tratamiento',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        ),
      ],
    ).animate().scale(duration: 300.ms, curve: Curves.easeOutBack).fadeIn();
  }

  Widget _buildStatusDropdown() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: DropdownButtonFormField<String>(
        initialValue: TreatmentStatus.options.contains(_status)
            ? _status
            : TreatmentStatus.active,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: 'Estado',
          prefixIcon: Icon(Icons.flag_circle_rounded, color: Colors.amber.shade700, size: 20),
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
        ),
        items: TreatmentStatus.options
            .map((s) => DropdownMenuItem(
                  value: s,
                  child: Text(s, style: GoogleFonts.poppins(fontSize: 15)),
                ))
            .toList(),
        onChanged: (value) {
          if (value != null) setState(() => _status = value);
        },
      ),
    );
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

  Widget _buildDatePickerTile(String label, DateTime? date, Function(DateTime) onSelected,
      {String? placeholder}) {
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
          style: GoogleFonts.poppins(
              fontSize: 15, fontWeight: FontWeight.w500, color: Colors.black87),
        ),
        trailing: Icon(Icons.calendar_month_rounded, color: Colors.amber.shade700),
        onTap: () => _selectDate(context, date ?? DateTime.now(), onSelected),
      ),
    );
  }

  Widget _buildTextField(
      TextEditingController controller, String label, String hint, IconData icon,
      {TextInputType keyboardType = TextInputType.text, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
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
          if (label.endsWith('*') && (value == null || value.trim().isEmpty)) {
            return 'Este campo es obligatorio';
          }
          return null;
        },
      ),
    );
  }
}
