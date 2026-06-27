import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:Softbee/feature/beehive/domain/entities/beehive.dart';
import 'package:Softbee/feature/beehive/presentation/providers/beehive_providers.dart';
import 'package:Softbee/feature/beehive/domain/enums/beehive_enums.dart'; // Import the enums

class BeehiveFormDialog extends ConsumerStatefulWidget {
  final String apiaryId;
  final Beehive? beehiveToEdit;

  const BeehiveFormDialog({
    super.key,
    required this.apiaryId,
    this.beehiveToEdit,
  });

  @override
  ConsumerState<BeehiveFormDialog> createState() => _BeehiveFormDialogState();
}

class _BeehiveFormDialogState extends ConsumerState<BeehiveFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _beehiveNumberController;
  late TextEditingController _foodFramesController;
  late TextEditingController _broodFramesController;
  late TextEditingController _observationsController;

  String? _activityLevel;
  String? _beePopulation;
  String? _hiveStatus;
  String? _healthStatus;
  String? _hasProductionChamber;

  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.beehiveToEdit != null;

    _beehiveNumberController = TextEditingController(
      text: _isEditing ? widget.beehiveToEdit!.beehiveNumber.toString() : '',
    );
    _foodFramesController = TextEditingController(
      text: _isEditing
          ? (widget.beehiveToEdit!.foodFrames?.toString() ?? '')
          : '',
    );
    _broodFramesController = TextEditingController(
      text: _isEditing
          ? (widget.beehiveToEdit!.broodFrames?.toString() ?? '')
          : '',
    );
    _observationsController = TextEditingController(
      text: _isEditing ? (widget.beehiveToEdit!.observations ?? '') : '',
    );

    _activityLevel = _isEditing ? widget.beehiveToEdit!.activityLevel : null;
    _beePopulation = _isEditing ? widget.beehiveToEdit!.beePopulation : null;
    _hiveStatus = _isEditing ? widget.beehiveToEdit!.hiveStatus : null;
    _healthStatus = _isEditing ? widget.beehiveToEdit!.healthStatus : null;
    _hasProductionChamber = _isEditing
        ? widget.beehiveToEdit!.hasProductionChamber
        : null;
  }

  @override
  void dispose() {
    _beehiveNumberController.dispose();
    _foodFramesController.dispose();
    _broodFramesController.dispose();
    _observationsController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    _formKey.currentState!.save();
    final beehiveController = ref.read(beehiveControllerProvider.notifier);

    final int beehiveNumber = int.parse(_beehiveNumberController.text);
    final int? foodFrames = int.tryParse(_foodFramesController.text);
    final int? broodFrames = int.tryParse(_broodFramesController.text);

    if (_isEditing) {
      await beehiveController.updateBeehive(
        widget.beehiveToEdit!.id,
        widget.apiaryId,
        beehiveNumber,
        _activityLevel,
        _beePopulation,
        foodFrames,
        broodFrames,
        _hiveStatus,
        _healthStatus,
        _hasProductionChamber,
        _observationsController.text.isEmpty
            ? null
            : _observationsController.text,
      );
    } else {
      await beehiveController.createBeehive(
        widget.apiaryId,
        beehiveNumber,
        _activityLevel,
        _beePopulation,
        foodFrames,
        broodFrames,
        _hiveStatus,
        _healthStatus,
        _hasProductionChamber,
        _observationsController.text.isEmpty
            ? null
            : _observationsController.text,
      );
    }

    // After async operation, check if the widget is still in the tree
    if (!mounted) return;

    // Read the latest state to check for errors
    final latestState = ref.read(beehiveControllerProvider);
    if (latestState.errorMessage == null) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final beehiveState = ref.watch(beehiveControllerProvider);
    final isLoading = beehiveState.isCreating || beehiveState.isUpdating;

    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titlePadding: const EdgeInsets.all(0),
      contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      title: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.amber.shade50,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border.all(color: Colors.amber.shade100, width: 0),
        ),
        child: Column(
          children: [
            Icon(
              _isEditing
                  ? Icons.edit_note_rounded
                  : Icons.add_circle_outline_rounded,
              color: Colors.amber.shade700,
              size: 36,
            ),
            const SizedBox(height: 10),
            Text(
              _isEditing ? 'Editar Colmena' : 'Crear Nueva Colmena',
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.amber.shade900,
              ),
            ),
          ],
        ),
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 20),
              _buildTextFormField(
                controller: _beehiveNumberController,
                label: 'Número de Colmena',
                hint: 'Ej: 101',
                icon: Icons.numbers_rounded,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Por favor, introduce el número de colmena';
                  }
                  final number = int.tryParse(value);
                  if (number == null) {
                    return 'Debe ser un número válido';
                  }

                  // Validación de duplicados en el frontend
                  final existingBeehives = ref
                      .read(beehiveControllerProvider)
                      .beehives;
                  final isDuplicate = existingBeehives.any(
                    (b) =>
                        b.beehiveNumber == number &&
                        b.id != widget.beehiveToEdit?.id,
                  );

                  if (isDuplicate) {
                    return 'Ya existe una colmena con este número en el apiario';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 15),
              _buildDropdownFormField(
                label: 'Nivel de Actividad (Opcional)',
                value: _activityLevel,
                items: ActivityLevel.values.map((e) => e.value).toList(),
                onChanged: (value) {
                  setState(() {
                    _activityLevel = value!;
                  });
                },
                icon: Icons.local_activity_rounded,
              ),
              const SizedBox(height: 15),
              _buildDropdownFormField(
                label: 'Población de Abejas (Opcional)',
                value: _beePopulation,
                items: BeePopulation.values.map((e) => e.value).toList(),
                onChanged: (value) {
                  setState(() {
                    _beePopulation = value!;
                  });
                },
                icon: Icons.group_rounded,
              ),
              const SizedBox(height: 15),
              _buildTextFormField(
                controller: _foodFramesController,
                label: 'Cuadros de Alimento (Opcional)',
                hint: 'Ej: 5 (Opcional)',
                icon: Icons.storage_rounded,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value != null &&
                      value.trim().isNotEmpty &&
                      int.tryParse(value) == null) {
                    return 'Debe ser un número válido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),
              _buildTextFormField(
                controller: _broodFramesController,
                label: 'Cuadros de Cría (Opcional)',
                hint: 'Ej: 3 (Opcional)',
                icon: Icons.storage_rounded,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value != null &&
                      value.trim().isNotEmpty &&
                      int.tryParse(value) == null) {
                    return 'Debe ser un número válido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),
              _buildDropdownFormField(
                label: 'Estado de la Colmena (Opcional)',
                value: _hiveStatus,
                items: HiveStatus.values.map((e) => e.value).toList(),
                onChanged: (value) {
                  setState(() {
                    _hiveStatus = value!;
                  });
                },
                icon: Icons.home_work_rounded,
              ),
              const SizedBox(height: 15),
              _buildDropdownFormField(
                label: 'Estado de Salud (Opcional)',
                value: _healthStatus,
                items: HealthStatus.values.map((e) => e.value).toList(),
                onChanged: (value) {
                  setState(() {
                    _healthStatus = value!;
                  });
                },
                icon: Icons.health_and_safety_rounded,
              ),
              const SizedBox(height: 15),
              _buildDropdownFormField(
                label: 'Cámara de Producción (Opcional)',
                value: _hasProductionChamber,
                items: HasProductionChamber.values.map((e) => e.value).toList(),
                onChanged: (value) {
                  setState(() {
                    _hasProductionChamber = value!;
                  });
                },
                icon: Icons.hive_rounded,
              ),
              const SizedBox(height: 15),
              _buildTextFormField(
                controller: _observationsController,
                label: 'Observaciones (Opcional)',
                hint: 'Ej: La colmena se ve saludable. (Opcional)',
                icon: Icons.notes_rounded,
                maxLines: 3,
                keyboardType: TextInputType.multiline,
              ),
              const SizedBox(height: 20),
              if (beehiveState.errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    beehiveState.errorMessage!,
                    style: GoogleFonts.poppins(color: Colors.red, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: 10,
                runSpacing: 10,
                children: [
                  TextButton(
                    onPressed: isLoading
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: Text(
                      'Cancelar',
                      style: GoogleFonts.poppins(color: Colors.grey.shade700),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: isLoading ? null : _submitForm,
                    icon: isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Icon(
                            _isEditing ? Icons.save_rounded : Icons.add_rounded,
                            color: Colors.white,
                          ),
                    label: Text(
                      _isEditing ? 'Guardar Cambios' : 'Crear Colmena',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber.shade700,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      validator: validator,
    );
  }

  Widget _buildDropdownFormField({
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required IconData icon,
  }) {
    return DropdownButtonFormField<String?>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      items: [
        const DropdownMenuItem<String?>(
          value: null,
          child: Text(
            'Seleccionar (Opcional)',
            style: TextStyle(color: Colors.grey),
          ),
        ),
        ...items.map<DropdownMenuItem<String?>>((String item) {
          return DropdownMenuItem<String?>(value: item, child: Text(item));
        }),
      ],
      onChanged: onChanged,
    );
  }
}
