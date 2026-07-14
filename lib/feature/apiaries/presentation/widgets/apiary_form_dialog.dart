import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:Softbee/feature/apiaries/domain/entities/apiary.dart';
import 'package:Softbee/feature/apiaries/presentation/providers/apiary_providers.dart';
import 'package:Softbee/core/services/geocoding_service.dart';

class ApiaryFormDialog extends ConsumerStatefulWidget {
  final Apiary? apiaryToEdit;

  const ApiaryFormDialog({super.key, this.apiaryToEdit});

  @override
  ConsumerState<ApiaryFormDialog> createState() => _ApiaryFormDialogState();
}

class _ApiaryFormDialogState extends ConsumerState<ApiaryFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _locationController;
  bool _isLocationValid = false;
  bool _locationValidationAttempted = false;

  final GeocodingService _geocodingService = GeocodingService();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.apiaryToEdit?.name ?? '',
    );
    _locationController = TextEditingController(
      text: widget.apiaryToEdit?.location ?? '',
    );

    if (widget.apiaryToEdit?.location != null &&
        widget.apiaryToEdit!.location!.isNotEmpty) {
      _isLocationValid =
          true; // Assume valid if editing an existing apiary with a location
    }

    _locationController.addListener(() {
      setState(() {
        _isLocationValid = _locationController.text
            .trim()
            .isNotEmpty; // Valid if not empty
        _locationValidationAttempted =
            true; // Mark as attempted for visual feedback
      });
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    // Validate form fields (name)
    if (!_formKey.currentState!.validate()) {
      return;
    }
    _formKey.currentState!.save();

    final apiariesController = ref.read(apiariesControllerProvider.notifier);
    final locationText = _locationController.text.trim();

    // Determine if creating or updating
    if (widget.apiaryToEdit == null) {
      // Create new apiary
      await apiariesController.createApiary(
        _nameController.text.trim(),
        locationText.isEmpty ? null : locationText,
        0, // Default to 0 beehives for new apiaries
      );
    } else {
      // Update existing apiary
      await apiariesController.updateApiary(
        widget.apiaryToEdit!.id,
        _nameController.text.trim(),
        locationText.isEmpty ? null : locationText,
        widget.apiaryToEdit!.beehivesCount, // Preserve existing count on edit
      );
    }

    // After async operation, check if the widget is still in the tree
    if (!mounted) return;

    // Read the latest state to check for errors
    final latestState = ref.read(apiariesControllerProvider);
    if (latestState.errorCreating == null &&
        latestState.errorUpdating == null) {
      Navigator.of(context).pop();
    }
    // Error snackbar is already handled by a listener in ApiariesMenu
  }

  @override
  Widget build(BuildContext context) {
    final apiariesState = ref.watch(apiariesControllerProvider);
    final isLoading = apiariesState.isCreating || apiariesState.isUpdating;
    final isEditing = widget.apiaryToEdit != null;

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
              isEditing
                  ? Icons.edit_note_rounded
                  : Icons.add_circle_outline_rounded,
              color: Colors.amber.shade700,
              size: 36,
            ),
            const SizedBox(height: 10),
            Text(
              isEditing ? 'Editar Apiario' : 'Crear Nuevo Apiario',
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
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Nombre del Apiario',
                  hintText: 'Ej: Apiario El Prado',
                  prefixIcon: const Icon(Icons.hive_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Por favor, introduce el nombre del apiario';
                  }
                  if (value.trim().length < 3) {
                    return 'El nombre debe tener al menos 3 caracteres';
                  }
                  return null;
                },
                onSaved: (value) => _nameController.text = value!,
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _locationController,
                decoration: InputDecoration(
                  labelText: 'Ubicación',
                  hintText: 'Ej: Vereda La Esperanza, Cota',
                  prefixIcon: const Icon(Icons.location_on_outlined),
                  suffixIcon: _locationController.text.trim().isNotEmpty
                      ? const Icon(
                          Icons
                              .check_circle_outline, // Always show checkmark if not empty
                          color: Colors.green,
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  errorText:
                      (_locationValidationAttempted &&
                          !_isLocationValid &&
                          _locationController.text.trim().isNotEmpty)
                      ? 'No se pudo verificar la ubicación, pero se guardará.'
                      : null,
                  errorStyle: TextStyle(color: Colors.orange.shade800),
                ),
                onSaved: (value) => _locationController.text = value!,
                validator: (value) {
                  // La ubicación es ahora opcional, por lo que no es necesaria una validación para valores vacíos aquí.
                  // El backend maneja cadenas vacías/nulas para la ubicación.
                  return null;
                },
              ),
              const SizedBox(height: 20),
              if (apiariesState.errorCreating != null ||
                  apiariesState.errorUpdating != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    apiariesState.errorCreating ??
                        apiariesState.errorUpdating ??
                        'Error desconocido',
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
                            isEditing ? Icons.save_rounded : Icons.add_rounded,
                            color: Colors.white,
                          ),
                    label: Text(
                      isEditing ? 'Guardar Cambios' : 'Crear Apiario',
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
}
