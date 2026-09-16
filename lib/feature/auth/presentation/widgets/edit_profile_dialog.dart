import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/entities/user.dart';
import '../providers/auth_providers.dart';
import 'profile_avatar.dart';

/// Modal para editar la información de perfil del usuario.
///
/// Incluye validaciones, indicador de carga y mensajes de error. Al guardar
/// correctamente cierra el diálogo devolviendo `true` para que la vista
/// muestre el mensaje de éxito.
class EditProfileDialog extends ConsumerStatefulWidget {
  final User user;

  const EditProfileDialog({super.key, required this.user});

  @override
  ConsumerState<EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends ConsumerState<EditProfileDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _fullNameController;
  late final TextEditingController _usernameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _locationController;

  Uint8List? _pickedBytes;
  bool _removePhoto = false;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController(text: widget.user.fullName ?? '');
    _usernameController = TextEditingController(text: widget.user.username);
    _phoneController = TextEditingController(text: widget.user.phone ?? '');
    _locationController = TextEditingController(text: widget.user.location ?? '');
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _usernameController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final XFile? file = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 70,
      );
      if (file != null) {
        final bytes = await file.readAsBytes();
        setState(() {
          _pickedBytes = bytes;
          _removePhoto = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage =
            'No se pudo seleccionar la imagen en este dispositivo.');
      }
    }
  }

  void _deletePhoto() {
    setState(() {
      _pickedBytes = null;
      _removePhoto = true;
    });
  }

  bool get _hasVisiblePhoto {
    if (_pickedBytes != null) return true;
    if (_removePhoto) return false;
    return widget.user.photoUrl != null &&
        widget.user.photoUrl!.trim().isNotEmpty;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    String? photoUrl;
    if (_pickedBytes != null) {
      photoUrl = 'data:image/jpeg;base64,${base64Encode(_pickedBytes!)}';
    }

    final error =
        await ref.read(authControllerProvider.notifier).updateProfile(
              username: _usernameController.text,
              fullName: _fullNameController.text,
              phone: _phoneController.text,
              location: _locationController.text,
              photoUrl: photoUrl,
              removePhoto: _removePhoto,
            );

    if (!mounted) return;

    if (error == null) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _isSaving = false;
        _errorMessage = error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final bool isMobile = screenSize.width < 600;
    final double dialogWidth = isMobile ? screenSize.width - 32 : 480;

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
            Icon(Icons.manage_accounts_rounded,
                color: Colors.amber.shade700, size: 40),
            const SizedBox(height: 8),
            Text('Editar perfil',
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                    color: Colors.amber.shade900)),
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
                _buildPhotoSection(),
                const SizedBox(height: 16),
                _buildTextField(
                  _fullNameController,
                  'Nombre completo',
                  Icons.badge_rounded,
                ),
                _buildTextField(
                  _usernameController,
                  'Nombre de usuario*',
                  Icons.alternate_email_rounded,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'El nombre de usuario es obligatorio'
                      : null,
                ),
                _buildTextField(
                  _phoneController,
                  'Teléfono',
                  Icons.phone_rounded,
                  keyboardType: TextInputType.phone,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return null;
                    final ok = RegExp(r'^[0-9+\-\s()]{6,20}$').hasMatch(v.trim());
                    return ok ? null : 'Ingresa un teléfono válido';
                  },
                ),
                _buildTextField(
                  _locationController,
                  'Ubicación',
                  Icons.location_on_rounded,
                ),
                const SizedBox(height: 8),
                // El correo es el identificador de acceso: se muestra pero no
                // es editable (no existe endpoint para cambiarlo).
                _buildReadOnlyEmail(),
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      _errorMessage!,
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
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: Text('Cancelar',
              style: GoogleFonts.poppins(color: Colors.grey.shade600)),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.amber.shade700,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2))
              : Text('Guardar cambios',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildPhotoSection() {
    Widget avatar;
    if (_pickedBytes != null) {
      avatar = CircleAvatar(
        radius: 44,
        backgroundColor: Colors.amber.shade100,
        backgroundImage: MemoryImage(_pickedBytes!),
      );
    } else if (_hasVisiblePhoto) {
      avatar = ProfileAvatar(
        photoUrl: widget.user.photoUrl,
        nameSource: widget.user.fullName ?? widget.user.username,
        radius: 44,
      );
    } else {
      avatar = ProfileAvatar(
        photoUrl: null,
        nameSource: widget.user.fullName ?? widget.user.username,
        radius: 44,
      );
    }

    return Column(
      children: [
        Stack(
          children: [
            avatar,
            Positioned(
              right: 0,
              bottom: 0,
              child: GestureDetector(
                onTap: _pickImage,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade700,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(Icons.camera_alt_rounded,
                      color: Colors.white, size: 16),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.photo_library_rounded, size: 18),
              label: Text('Cambiar foto', style: GoogleFonts.poppins(fontSize: 13)),
              style: TextButton.styleFrom(foregroundColor: Colors.amber.shade800),
            ),
            if (_hasVisiblePhoto)
              TextButton.icon(
                onPressed: _deletePhoto,
                icon: const Icon(Icons.delete_outline_rounded, size: 18),
                label: Text('Eliminar', style: GoogleFonts.poppins(fontSize: 13)),
                style: TextButton.styleFrom(foregroundColor: Colors.red.shade400),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildReadOnlyEmail() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.email_rounded, size: 20, color: Colors.grey.shade500),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Correo (no editable)',
                    style: GoogleFonts.poppins(
                        fontSize: 11, color: Colors.grey.shade500)),
                Text(widget.user.email,
                    style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade700),
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        style: GoogleFonts.poppins(fontSize: 15),
        decoration: InputDecoration(
          labelText: label,
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
        ),
      ),
    );
  }
}
