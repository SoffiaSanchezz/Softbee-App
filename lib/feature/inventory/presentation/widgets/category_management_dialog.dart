import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../domain/entities/inventory_category.dart';
import '../providers/categories_provider.dart';

/// Diálogo para gestionar (crear, editar, eliminar) las categorías del
/// inventario. Cada categoría tiene nombre, icono y color.
class CategoryManagementDialog extends ConsumerWidget {
  const CategoryManagementDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (_) => const CategoryManagementDialog(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(categoriesProvider);
    final controller = ref.read(categoriesProvider.notifier);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(Icons.category_rounded, color: Colors.amber[800]),
          const SizedBox(width: 8),
          Text('Gestionar Categorías',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        ],
      ),
      content: SizedBox(
        width: 420,
        child: state.categories.isEmpty
            ? Padding(
                padding: const EdgeInsets.all(24),
                child: Text('No hay categorías.',
                    style: GoogleFonts.poppins(color: Colors.grey[600])),
              )
            : ListView.separated(
                shrinkWrap: true,
                itemCount: state.categories.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final cat = state.categories[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: cat.color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(cat.icon, color: cat.color),
                    ),
                    title: Text(cat.name,
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w500, fontSize: 14)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit_outlined,
                              size: 20, color: Colors.amber[800]),
                          onPressed: () =>
                              _openEditor(context, controller, category: cat),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete_outline,
                              size: 20, color: Colors.red[600]),
                          onPressed: () => controller.deleteCategory(cat.id),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
      actions: [
        TextButton.icon(
          onPressed: () => _openEditor(context, controller),
          icon: const Icon(Icons.add, color: Colors.amber),
          label: Text('Nueva categoría',
              style: GoogleFonts.poppins(
                  color: Colors.amber[900], fontWeight: FontWeight.w600)),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cerrar',
              style: GoogleFonts.poppins(color: Colors.grey[700])),
        ),
      ],
    );
  }

  void _openEditor(
    BuildContext context,
    CategoriesController controller, {
    InventoryCategory? category,
  }) {
    showDialog(
      context: context,
      builder: (_) => _CategoryEditorDialog(
        controller: controller,
        category: category,
      ),
    );
  }
}

class _CategoryEditorDialog extends StatefulWidget {
  final CategoriesController controller;
  final InventoryCategory? category;

  const _CategoryEditorDialog({required this.controller, this.category});

  @override
  State<_CategoryEditorDialog> createState() => _CategoryEditorDialogState();
}

class _CategoryEditorDialogState extends State<_CategoryEditorDialog> {
  late final TextEditingController _nameController;
  late String _iconKey;
  late int _colorValue;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category?.name ?? '');
    _iconKey = widget.category?.iconKey ?? CategoryIcons.keys.first;
    _colorValue = widget.category?.colorValue ?? CategoryColors.palette.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  bool get _isEditing => widget.category != null;

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    if (_isEditing) {
      widget.controller.updateCategory(
        widget.category!.copyWith(
          name: name,
          iconKey: _iconKey,
          colorValue: _colorValue,
        ),
      );
    } else {
      widget.controller.addCategory(
        name: name,
        iconKey: _iconKey,
        colorValue: _colorValue,
      );
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final color = Color(_colorValue);
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(_isEditing ? 'Editar Categoría' : 'Nueva Categoría',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 380,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Vista previa
              Center(
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(CategoryIcons.resolve(_iconKey),
                      color: color, size: 32),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Nombre de la categoría',
                  prefixIcon: const Icon(Icons.label_outline, color: Colors.amber),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 16),
              Text('Icono',
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: CategoryIcons.keys.map((key) {
                  final selected = key == _iconKey;
                  return InkWell(
                    onTap: () => setState(() => _iconKey = key),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: selected
                            ? color.withOpacity(0.18)
                            : Colors.grey[100],
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: selected ? color : Colors.grey.shade300,
                          width: selected ? 2 : 1,
                        ),
                      ),
                      child: Icon(CategoryIcons.resolve(key),
                          color: selected ? color : Colors.grey[600], size: 22),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              Text('Color',
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: CategoryColors.palette.map((value) {
                  final selected = value == _colorValue;
                  return InkWell(
                    onTap: () => setState(() => _colorValue = value),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Color(value),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: selected ? Colors.black87 : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: selected
                          ? const Icon(Icons.check,
                              color: Colors.white, size: 18)
                          : null,
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancelar',
              style: GoogleFonts.poppins(color: Colors.grey[700])),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.amber,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: _save,
          child: Text(_isEditing ? 'Guardar' : 'Crear',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}
