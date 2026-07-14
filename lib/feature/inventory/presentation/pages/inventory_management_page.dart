import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:Softbee/feature/inventory/data/models/inventory_item.dart';
import 'package:Softbee/feature/inventory/domain/entities/inventory_category.dart';
import 'package:Softbee/feature/inventory/presentation/providers/categories_provider.dart';
import 'package:Softbee/feature/inventory/presentation/providers/inventory_controller.dart';
import 'package:Softbee/feature/inventory/presentation/providers/inventory_state.dart';
import 'package:Softbee/feature/inventory/presentation/widgets/category_management_dialog.dart';
import 'package:Softbee/feature/inventory/presentation/widgets/error_display_widget.dart';
import 'package:Softbee/feature/inventory/presentation/widgets/loading_indicator_widget.dart';

// Enum para definir los tipos de pantalla
enum ScreenType { mobile, tablet, desktop }

// Clase para manejar breakpoints responsivos
class ResponsiveBreakpoints {
  static const double mobile = 600;
  static const double tablet = 1250;
  static const double desktop = 1400;

  static ScreenType getScreenType(double width) {
    if (width < mobile) return ScreenType.mobile;
    if (width < desktop) return ScreenType.tablet;
    return ScreenType.desktop;
  }
}

// Widget responsivo principal
class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget desktop;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    required this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenType = ResponsiveBreakpoints.getScreenType(
          constraints.maxWidth,
        );

        switch (screenType) {
          case ScreenType.mobile:
            return mobile;
          case ScreenType.tablet:
            return tablet ?? desktop;
          case ScreenType.desktop:
            return desktop;
        }
      },
    );
  }
}

class InventoryManagementPage extends ConsumerStatefulWidget {
  final String apiaryId;

  const InventoryManagementPage({super.key, required this.apiaryId});

  @override
  _InventoryManagementPageState createState() =>
      _InventoryManagementPageState();
}

class _InventoryManagementPageState
    extends ConsumerState<InventoryManagementPage>
    with SingleTickerProviderStateMixin {
  // Controladores para los formularios
  final TextEditingController nombreController = TextEditingController();
  final TextEditingController cantidadController = TextEditingController();
  final TextEditingController searchController = TextEditingController();
  final TextEditingController descripcionController = TextEditingController();
  
  // Nuevos controladores profesionales
  final TextEditingController loteController = TextEditingController();
  final TextEditingController proveedorController = TextEditingController();
  final TextEditingController ubicacionController = TextEditingController();
  final TextEditingController stockMinimoController = TextEditingController();
  DateTime? fechaVencimiento;
  DateTime? fechaCompra;
  String categoriaSeleccionada = 'General';

  // Clave para validación del formulario
  final _formKeyAgregar = GlobalKey<FormState>();

  // Variables de estado local para el diálogo de agregar/editar
  String unidadSeleccionada = 'Unidades';

  // Lista de unidades disponibles en español (Colombia)
  final List<String> unidades = [
    'Unidades',
    'Láminas',
    'Pares',
    'Kilogramos',
    'Litros',
    'Metros',
    'Cajas',
    'Gramos',
    'Mililitros',
    'Docenas',
  ];

  // Las categorías ahora provienen del módulo de categorías (con icono y color),
  // gestionable por el usuario. Se exponen como nombres para el resto del código.
  List<String> get categorias {
    final names =
        ref.read(categoriesProvider).categories.map((c) => c.name).toList();
    return names.isEmpty ? const ['Otros'] : names;
  }

  // Función para normalizar unidades del backend al frontend
  String _normalizarUnidad(String? unit) {
    if (unit == null || unit.isEmpty) return 'Unidades';

    final normalizedUnitLower = unit.toLowerCase().trim();

    // 1. Check if the exact unit (case-sensitive) is already in our predefined list
    if (unidades.contains(unit)) {
      return unit;
    }

    // 2. Check if a case-insensitive version exists in our predefined list
    for (String u in unidades) {
      if (u.toLowerCase() == normalizedUnitLower) {
        return u; // Return the canonical form from `unidades`
      }
    }

    // 3. Check the mapping for common backend variations
    final map = {
      'unit': 'Unidades',
      'units': 'Unidades',
      'unidades': 'Unidades',
      'unidad': 'Unidades',
      'pair': 'Pares',
      'pairs': 'Pares',
      'pares': 'Pares',
      'kg': 'Kilogramos',
      'kilogramos': 'Kilogramos',
      'liter': 'Litros',
      'litros': 'Litros',
      'meter': 'Metros',
      'metros': 'Metros',
      'box': 'Cajas',
      'cajas': 'Cajas',
      'gram': 'Gramos',
      'gramos': 'Gramos',
      'ml': 'Mililitros',
      'mililitros': 'Mililitros',
      'dozen': 'Docenas',
      'docenas': 'Docenas',
      'láminas': 'Láminas',
      'laminas': 'Láminas',
    };

    final mappedValue = map[normalizedUnitLower];
    if (mappedValue != null && unidades.contains(mappedValue)) {
      return mappedValue;
    }

    // 4. Fallback to 'Unidades' if no match is found
    return 'Unidades';
  }

  // Ícono de la categoría (dinámico desde el módulo de categorías).
  IconData _getIconForCategory(String? category) {
    final cat = ref.read(categoriesProvider).findByName(category);
    if (cat != null) return cat.icon;
    // Fallback para nombres heredados que aún no sean categorías registradas.
    switch (category?.trim()) {
      case 'Equipos':
        return Icons.precision_manufacturing;
      case 'Herramientas':
        return Icons.handyman;
      case 'Protección':
        return Icons.security;
      case 'Medicamentos':
        return Icons.medication;
      case 'Alimentación':
        return Icons.opacity;
      case 'Cosecha':
        return Icons.shopping_basket;
      default:
        return Icons.inventory_2;
    }
  }

  // Color representativo de la categoría (dinámico). Ámbar por defecto.
  Color _getColorForCategory(String? category) {
    return ref.read(categoriesProvider).findByName(category)?.color ??
        Colors.amber.shade700;
  }

  // Controlador de animación
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    nombreController.dispose();
    cantidadController.dispose();
    searchController.dispose();
    descripcionController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // Método para agregar o editar insumos
  Future<void> _guardarInsumo(
    InventoryController controller,
    InventoryState state,
  ) async {
    if (!_formKeyAgregar.currentState!.validate()) {
      return;
    }

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => LoadingIndicatorWidget(
          message: state.isEditing
              ? 'Actualizando insumo...'
              : 'Agregando insumo...',
        ),
      );

      InventoryItem itemToSave;
      if (state.isEditing && state.editingItem != null) {
        itemToSave = state.editingItem!.copyWith(
          itemName: nombreController.text.trim(),
          quantity: int.parse(cantidadController.text),
          unit: unidadSeleccionada,
          category: categoriaSeleccionada,
          description: descripcionController.text.trim(),
          batchNumber: loteController.text.trim(),
          expiryDate: fechaVencimiento,
          purchaseDate: fechaCompra,
          supplier: proveedorController.text.trim(),
          storageLocation: ubicacionController.text.trim(),
          minimumStock: int.tryParse(stockMinimoController.text) ?? 0,
        );
      } else {
        itemToSave = InventoryItem(
          id: '',
          itemName: nombreController.text.trim(),
          quantity: int.parse(cantidadController.text),
          unit: unidadSeleccionada,
          apiaryId: widget.apiaryId,
          category: categoriaSeleccionada,
          description: descripcionController.text.trim(),
          batchNumber: loteController.text.trim(),
          expiryDate: fechaVencimiento,
          purchaseDate: fechaCompra,
          supplier: proveedorController.text.trim(),
          storageLocation: ubicacionController.text.trim(),
          minimumStock: int.tryParse(stockMinimoController.text) ?? 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      }

      final errorMessage = await controller.guardarInsumo(
        itemToSave,
        apiaryId: widget.apiaryId,
      );

      if (mounted) Navigator.of(context).pop();

      if (errorMessage != null) {
        _showSnackBar(context, errorMessage, Colors.red, Icons.error);
      } else {
        if (mounted) Navigator.of(context).pop();

        _showSnackBar(
          context,
          state.isEditing
              ? 'Insumo actualizado correctamente'
              : 'Insumo agregado correctamente',
          Colors.green,
          Icons.check_circle,
        );

        _limpiarFormulario(controller);
      }
    } catch (e) {
      if (mounted) Navigator.of(context).pop();
      _showSnackBar(context, 'Error: ${e.toString()}', Colors.red, Icons.error);
    }
  }

  void _showSnackBar(
    BuildContext context,
    String message,
    Color color,
    IconData icon,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message, style: GoogleFonts.poppins())),
          ],
        ),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _limpiarFormulario(InventoryController controller) {
    nombreController.clear();
    cantidadController.clear();
    descripcionController.clear();
    loteController.clear();
    proveedorController.clear();
    ubicacionController.clear();
    stockMinimoController.clear();
    setState(() {
      unidadSeleccionada = 'Unidades';
      // Si el filtro es diferente de 'Todas', pre-llenamos la categoría con el filtro actual
      categoriaSeleccionada = (categoriaFiltro != 'Todas') ? categoriaFiltro : 'General';
      fechaVencimiento = null;
      fechaCompra = null;
    });
    controller.setEditingItem(null);
  }

  void _editarInsumo(InventoryItem insumo, InventoryController controller) {
    nombreController.text = insumo.itemName;
    cantidadController.text = insumo.quantity.toString();
    unidadSeleccionada = _normalizarUnidad(insumo.unit);
    descripcionController.text = insumo.description ?? '';
    categoriaSeleccionada = insumo.category;
    loteController.text = insumo.batchNumber ?? '';
    proveedorController.text = insumo.supplier ?? '';
    ubicacionController.text = insumo.storageLocation ?? '';
    stockMinimoController.text = insumo.minimumStock.toString();
    fechaVencimiento = insumo.expiryDate;
    fechaCompra = insumo.purchaseDate;

    controller.setEditingItem(insumo);
    _mostrarDialogoAgregar(controller);
  }

  Future<void> _eliminarInsumo(
    String id,
    InventoryController controller,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              const Icon(Icons.warning, color: Colors.red),
              const SizedBox(width: 8),
              Text(
                '¿Eliminar insumo?',
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: const Text(
            'Esta acción no se puede deshacer. El insumo será eliminado permanentemente del inventario.',
            style: TextStyle(fontFamily: 'Poppins'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Cancelar',
                style: GoogleFonts.poppins(color: Colors.grey[600]),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                'Eliminar',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      try {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) =>
              const LoadingIndicatorWidget(message: 'Eliminando insumo...'),
        );

        final errorMessage = await controller.eliminarInsumo(
          id,
          apiaryId: widget.apiaryId,
        );

        if (mounted) Navigator.of(context).pop();

        if (errorMessage != null) {
          _showSnackBar(context, errorMessage, Colors.red, Icons.error);
        } else {
          _showSnackBar(
            context,
            'Insumo eliminado correctamente',
            Colors.red,
            Icons.delete,
          );
        }
      } catch (e) {
        if (mounted) Navigator.of(context).pop();
        _showSnackBar(
          context,
          'Error al eliminar: ${e.toString()}',
          Colors.red,
          Icons.error,
        );
      }
    }
  }

  void _mostrarDialogoAgregar(InventoryController controller) {
    // Garantiza una categoría válida seleccionada por defecto (no altera la lógica de guardado).
    if (!controller.state.isEditing &&
        !categorias.contains(categoriaSeleccionada)) {
      categoriaSeleccionada =
          categorias.isNotEmpty ? categorias.first : categoriaSeleccionada;
    }

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Formulario de insumo',
      barrierColor: Colors.black.withOpacity(0.45),
      transitionDuration: const Duration(milliseconds: 260),
      transitionBuilder: (context, anim, _, child) {
        final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.96, end: 1.0).animate(curved),
            child: child,
          ),
        );
      },
      pageBuilder: (BuildContext context, _, __) {
        final screenSize = MediaQuery.of(context).size;
        final bool isMobile = screenSize.width < ResponsiveBreakpoints.mobile;
        final bool isDesktop = screenSize.width >= ResponsiveBreakpoints.desktop;
        // Modal ~35-40% más grande en escritorio para que no se vea comprimido.
        final double dialogWidth =
            isMobile ? screenSize.width : (isDesktop ? 820 : 680);

        return StatefulBuilder(
          builder: (context, setDialogState) {
            final bool isEditing = controller.state.isEditing;
            return Center(
              child: Dialog(
                insetPadding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 12 : 24,
                  vertical: 24,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                clipBehavior: Clip.antiAlias,
                backgroundColor: const Color(0xFFF8F5F0),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: dialogWidth,
                    maxHeight: screenSize.height * 0.92,
                  ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ---------- Header ----------
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.amber.shade400, Colors.amber.shade600],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.25),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              isEditing ? Icons.edit_rounded : Icons.add_box_rounded,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isEditing ? 'Editar Insumo' : 'Agregar Insumo',
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  'Completa la información del producto',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: Colors.white.withOpacity(0.9),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, color: Colors.white),
                            onPressed: () {
                              _limpiarFormulario(controller);
                              Navigator.of(context).pop();
                            },
                          ),
                        ],
                      ),
                    ),
                    // ---------- Cuerpo desplazable ----------
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Form(
                          key: _formKeyAgregar,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // ===== Información del Producto (categoría = elemento principal) =====
                              _buildFormSection(
                                title: 'Información del Producto',
                                icon: Icons.category_rounded,
                                children: [
                                  _buildProductPreview(),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Categoría',
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  _buildCategorySelector(setDialogState),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: nombreController,
                                    style: GoogleFonts.poppins(),
                                    decoration: _modernInput(
                                      label: 'Nombre del insumo',
                                      hint: 'Ej: Traje de apicultor',
                                      icon: Icons.inventory_2_rounded,
                                    ),
                                    validator: (value) =>
                                        value == null || value.trim().isEmpty
                                            ? 'Ingresa un nombre'
                                            : null,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              // ===== Inventario =====
                              _buildFormSection(
                                title: 'Inventario',
                                icon: Icons.inventory_rounded,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: TextFormField(
                                          controller: cantidadController,
                                          keyboardType: TextInputType.number,
                                          style: GoogleFonts.poppins(),
                                          decoration: _modernInput(
                                            label: 'Cantidad',
                                            icon: Icons.numbers_rounded,
                                          ),
                                          validator: (value) =>
                                              value == null || value.isEmpty
                                                  ? 'Requerido'
                                                  : null,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: DropdownButtonFormField<String>(
                                          initialValue: unidadSeleccionada,
                                          isExpanded: true,
                                          style: GoogleFonts.poppins(color: Colors.black87),
                                          decoration: _modernInput(
                                            label: 'Unidad',
                                            icon: Icons.straighten_rounded,
                                          ),
                                          items: unidades
                                              .map((u) => DropdownMenuItem(
                                                    value: u,
                                                    child: Text(u, overflow: TextOverflow.ellipsis),
                                                  ))
                                              .toList(),
                                          onChanged: (v) =>
                                              setDialogState(() => unidadSeleccionada = v!),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                  TextFormField(
                                    controller: stockMinimoController,
                                    keyboardType: TextInputType.number,
                                    style: GoogleFonts.poppins(),
                                    decoration: _modernInput(
                                      label: 'Stock mínimo (alerta)',
                                      hint: 'Se avisará al bajar de este valor',
                                      icon: Icons.warning_amber_rounded,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              // ===== Control de Calidad y Lote (condicional) =====
                              if (['Medicamentos', 'Alimentación', 'Cosecha', 'Tratamientos', 'Producción']
                                  .contains(categoriaSeleccionada)) ...[
                                _buildFormSection(
                                  title: 'Control de Calidad y Lote',
                                  icon: Icons.verified_rounded,
                                  children: [
                                    TextFormField(
                                      controller: loteController,
                                      style: GoogleFonts.poppins(),
                                      decoration: _modernInput(
                                        label: 'Número de lote',
                                        hint: 'Ej: LOT-2024-001',
                                        icon: Icons.qr_code_rounded,
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                    _buildDateField(
                                      label: 'Fecha de vencimiento',
                                      icon: Icons.event_busy_rounded,
                                      value: fechaVencimiento,
                                      onTap: () async {
                                        final picked = await showDatePicker(
                                          context: context,
                                          initialDate: fechaVencimiento ??
                                              DateTime.now().add(const Duration(days: 365)),
                                          firstDate: DateTime.now().subtract(const Duration(days: 365)),
                                          lastDate: DateTime.now().add(const Duration(days: 3650)),
                                        );
                                        if (picked != null) setDialogState(() => fechaVencimiento = picked);
                                      },
                                    ),
                                    const SizedBox(height: 14),
                                    _buildDateField(
                                      label: 'Fecha de compra',
                                      icon: Icons.shopping_cart_rounded,
                                      value: fechaCompra,
                                      onTap: () async {
                                        final picked = await showDatePicker(
                                          context: context,
                                          initialDate: fechaCompra ?? DateTime.now(),
                                          firstDate: DateTime.now().subtract(const Duration(days: 3650)),
                                          lastDate: DateTime.now(),
                                        );
                                        if (picked != null) setDialogState(() => fechaCompra = picked);
                                      },
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                              ],
                              // ===== Ubicación y Observaciones =====
                              _buildFormSection(
                                title: 'Ubicación y Observaciones',
                                icon: Icons.place_rounded,
                                children: [
                                  _twoColumn(
                                    isMobile,
                                    TextFormField(
                                      controller: proveedorController,
                                      style: GoogleFonts.poppins(),
                                      decoration: _modernInput(
                                        label: 'Proveedor',
                                        hint: 'Opcional',
                                        icon: Icons.business_rounded,
                                      ),
                                    ),
                                    TextFormField(
                                      controller: ubicacionController,
                                      style: GoogleFonts.poppins(),
                                      decoration: _modernInput(
                                        label: 'Ubicación en almacén',
                                        hint: 'Opcional',
                                        icon: Icons.place_rounded,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 18),
                                  TextFormField(
                                    controller: descripcionController,
                                    style: GoogleFonts.poppins(),
                                    maxLines: 3,
                                    decoration: _modernInput(
                                      label: 'Notas adicionales',
                                      hint: 'Observaciones, detalles, etc.',
                                      icon: Icons.notes_rounded,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // ---------- Footer fijo (sticky) ----------
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border(top: BorderSide(color: Colors.grey.shade200)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.grey[700],
                                side: BorderSide(color: Colors.grey.shade300),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () {
                                _limpiarFormulario(controller);
                                Navigator.of(context).pop();
                              },
                              child: Text(
                                'Cancelar',
                                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.amber,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: Icon(isEditing ? Icons.save_rounded : Icons.add_rounded),
                              onPressed: () => _guardarInsumo(controller, controller.state),
                              label: Text(
                                isEditing ? 'Actualizar' : 'Guardar Insumo',
                                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
          },
        );
      },
    );
  }

  // ================= Helpers de UI del formulario =================

  /// Distribuye dos campos en dos columnas (Desktop/Tablet) o apilados (Mobile).
  Widget _twoColumn(bool isMobile, Widget a, Widget b, {double gap = 16}) {
    if (isMobile) {
      return Column(
        children: [a, SizedBox(height: gap), b],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: a),
        SizedBox(width: gap),
        Expanded(child: b),
      ],
    );
  }

  InputDecoration _modernInput({
    required String label,
    String? hint,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      hintStyle: GoogleFonts.poppins(color: Colors.grey[400], fontSize: 13),
      labelStyle: GoogleFonts.poppins(color: Colors.grey[700], fontSize: 14),
      prefixIcon: Icon(icon, color: Colors.amber[700], size: 22),
      filled: true,
      fillColor: Colors.white,
      isDense: false,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.amber, width: 1.8),
      ),
    );
  }

  Widget _buildFormSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 20, color: Colors.amber[800]),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[850],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ...children,
        ],
      ),
    );
  }

  Widget _buildCategorySelector(void Function(void Function()) setDialogState) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ...categorias.map((c) {
          final bool selected = c == categoriaSeleccionada;
          final color = _getColorForCategory(c);
          return InkWell(
            onTap: () => setDialogState(() => categoriaSeleccionada = c),
            borderRadius: BorderRadius.circular(12),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: selected ? color.withOpacity(0.15) : Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selected ? color : Colors.grey.shade200,
                  width: selected ? 2 : 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_getIconForCategory(c), size: 18, color: color),
                  const SizedBox(width: 8),
                  Text(
                    c,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                      color: selected ? color : Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
        // Botón para gestionar categorías
        InkWell(
          onTap: () async {
            await CategoryManagementDialog.show(context);
            setDialogState(() {});
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.tune_rounded, size: 18, color: Colors.amber[800]),
                const SizedBox(width: 6),
                Text(
                  'Gestionar',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.amber[900],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProductPreview() {
    final color = _getColorForCategory(categoriaSeleccionada);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.12), Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withOpacity(0.18),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              _getIconForCategory(categoriaSeleccionada),
              color: color,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: nombreController,
                  builder: (context, value, _) {
                    final name = value.text.trim();
                    return Text(
                      name.isEmpty ? 'Nombre del producto' : name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: name.isEmpty ? Colors.grey[400] : Colors.grey[850],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 2),
                Text(
                  categoriaSeleccionada,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateField({
    required String label,
    required IconData icon,
    required DateTime? value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: _modernInput(label: label, icon: icon),
        child: Text(
          value == null
              ? 'Seleccionar fecha'
              : '${value.day}/${value.month}/${value.year}',
          style: GoogleFonts.poppins(
            color: value == null ? Colors.grey[500] : Colors.grey[850],
          ),
        ),
      ),
    );
  }

  String categoriaFiltro = 'Todas';

  List<InventoryItem> _getFilteredInsumos(List<InventoryItem> allItems) {
    return allItems.where((insumo) {
      final matchesSearch = insumo.itemName.toLowerCase().contains(searchController.text.toLowerCase());
      final matchesCategory = categoriaFiltro == 'Todas' || insumo.category == categoriaFiltro;
      return matchesSearch && matchesCategory;
    }).toList();
  }

  Widget _buildCategoryFilters() {
    final filtros = ['Todas', ...categorias];
    return Container(
      height: 50,
      margin: const EdgeInsets.only(bottom: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: filtros.length,
        itemBuilder: (context, index) {
          final filtro = filtros[index];
          final isSelected = categoriaFiltro == filtro;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              selected: isSelected,
              label: Text(filtro, style: GoogleFonts.poppins(
                fontSize: 12,
                color: isSelected ? Colors.white : Colors.amber[900],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              )),
              selectedColor: Colors.amber,
              backgroundColor: Colors.white,
              checkmarkColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: Colors.amber.withOpacity(0.3)),
              ),
              onSelected: (val) => setState(() => categoriaFiltro = filtro),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Observamos las categorías para que filtros, iconos y colores se
    // actualicen automáticamente cuando el usuario las gestione.
    ref.watch(categoriesProvider);
    final inventoryState = ref.watch(
      inventoryControllerProvider(widget.apiaryId),
    );
    final inventoryController = ref.read(
      inventoryControllerProvider(widget.apiaryId).notifier,
    );

    if (inventoryState.isLoading) {
      return const Scaffold(
        body: LoadingIndicatorWidget(message: 'Cargando inventario...'),
      );
    }

    if (inventoryState.errorMessage != null) {
      return Scaffold(
        body: ErrorDisplayWidget(
          message: inventoryState.errorMessage!,
          onRetry: () =>
              inventoryController.loadInventoryItems(apiaryId: widget.apiaryId),
        ),
      );
    }

    return Scaffold(
      body: ResponsiveLayout(
        mobile: _buildMobileLayout(inventoryState, inventoryController),
        tablet: _buildTabletLayout(inventoryState, inventoryController),
        desktop: _buildDesktopLayout(inventoryState, inventoryController),
      ),
    );
  }

  Widget _buildMobileLayout(
    InventoryState state,
    InventoryController controller,
  ) {
    return Container(
      color: const Color(0xFFFFF8E1),
      child: Column(
        children: [
          _buildHeader(state, ScreenType.mobile),
          _buildSearchAndAddSection(state, controller, ScreenType.mobile),
          Expanded(
            child: _buildListaInsumos(state, controller, ScreenType.mobile),
          ),
        ],
      ),
    );
  }

  Widget _buildTabletLayout(
    InventoryState state,
    InventoryController controller,
  ) {
    return Container(
      color: const Color(0xFFFFF8E1),
      child: Column(
        children: [
          _buildHeader(state, ScreenType.tablet),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: 280, child: _buildSidePanel(state)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      children: [
                        _buildSearchAndAddSection(
                          state,
                          controller,
                          ScreenType.tablet,
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: _buildListaInsumos(
                            state,
                            controller,
                            ScreenType.tablet,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(
    InventoryState state,
    InventoryController controller,
  ) {
    return Container(
      color: const Color(0xFFFFF8E1),
      child: Column(
        children: [
          _buildHeader(state, ScreenType.desktop),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: 350, child: _buildSidePanel(state)),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      children: [
                        _buildSearchAndAddSection(
                          state,
                          controller,
                          ScreenType.desktop,
                        ),
                        const SizedBox(height: 24),
                        Expanded(
                          child: _buildListaInsumos(
                            state,
                            controller,
                            ScreenType.desktop,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  SizedBox(width: 300, child: _buildStatsPanel(state)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(InventoryState state, ScreenType screenType) {
    final isDesktop = screenType == ScreenType.desktop;
    final isTablet = screenType == ScreenType.tablet;

    return Container(
      padding: EdgeInsets.all(isDesktop ? 24 : 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.amber, Colors.amber[600]!],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: Icon(
                Icons.arrow_back,
                color: Colors.white,
                size: isDesktop ? 28 : 24,
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Gestión de Inventario',
                    style: GoogleFonts.poppins(
                      fontSize: isDesktop ? 32 : (isTablet ? 28 : 22),
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Administra tus insumos de apiario',
                    style: GoogleFonts.poppins(
                      fontSize: isDesktop ? 16 : 14,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 16 : 12,
                vertical: isDesktop ? 8 : 6,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.inventory_2,
                    color: Colors.amber[700],
                    size: isDesktop ? 20 : 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${state.inventoryItems.length}',
                    style: GoogleFonts.poppins(
                      color: Colors.amber[700],
                      fontWeight: FontWeight.w600,
                      fontSize: isDesktop ? 16 : 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndAddSection(
    InventoryState state,
    InventoryController controller,
    ScreenType screenType,
  ) {
    final isDesktop = screenType == ScreenType.desktop;
    final isTablet = screenType == ScreenType.tablet;
    final padding = (isDesktop || isTablet) ? 0.0 : 16.0;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: padding, vertical: padding / 2),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber[200]!),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Buscar insumo...',
                hintStyle: GoogleFonts.poppins(color: Colors.grey[500]),
                prefixIcon: const Icon(Icons.search, color: Colors.amber),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  vertical: isDesktop ? 20 : 16,
                  horizontal: 16,
                ),
              ),
              style: GoogleFonts.poppins(fontSize: isDesktop ? 16 : 14),
              onChanged: (value) {
                setState(() {});
              },
            ),
          ),
          const SizedBox(height: 12),
          _buildCategoryFilters(),
          const SizedBox(height: 4),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: Icon(Icons.add, size: isDesktop ? 24 : 20),
              label: Text(
                'Agregar Nuevo Insumo',
                style: GoogleFonts.poppins(
                  fontSize: isDesktop ? 18 : 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: isDesktop ? 20 : 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                _limpiarFormulario(controller);
                _mostrarDialogoAgregar(controller);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidePanel(InventoryState state) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Resumen de Inventario',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 20),
            _buildSummaryCard(
              'Total de Insumos',
              '${state.inventorySummary['total_items'] ?? 0}',
              Icons.inventory_2,
              Colors.blue,
            ),
            const SizedBox(height: 12),
            _buildSummaryCard(
              'Stock Bajo',
              '${state.inventorySummary['low_stock_items'] ?? 0}',
              Icons.warning,
              Colors.orange,
            ),
            const SizedBox(height: 12),
            _buildSummaryCard(
              'Stock Total',
              '${state.inventorySummary['total_quantity'] ?? 0}',
              Icons.assessment,
              Colors.green,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsPanel(InventoryState state) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Análisis',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 20),
            _buildStatItem(
              'Items en stock',
              '${state.inventorySummary['in_stock_items'] ?? 0}',
            ),
            const SizedBox(height: 16),
            _buildStatItem(
              'Última actualización',
              state.inventorySummary['updated_at'] != null ? 'Hace unos momentos' : 'N/A',
            ),
            const SizedBox(height: 24),
            Text(
              'Alertas',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 16),
            ..._buildAlertas(state),
          ],
        ),
      ),
    );
  }

  Widget _buildListaInsumos(
    InventoryState state,
    InventoryController controller,
    ScreenType screenType,
  ) {
    final insumosFiltrados = _getFilteredInsumos(state.inventoryItems);
    final isDesktop = screenType == ScreenType.desktop;

    if (insumosFiltrados.isEmpty) {
      return _buildEmptyState(state, controller);
    }

    final groupedInsumos = _groupInsumos(insumosFiltrados);
    final sortedCategories = groupedInsumos.keys.toList()..sort();

    return CustomScrollView(
      slivers: [
        for (final category in sortedCategories) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
              child: Row(
                children: [
                  Icon(_getIconForCategory(category), color: _getColorForCategory(category), size: 24),
                  const SizedBox(width: 12),
                  Text(
                    category,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber[900],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Divider(color: Colors.amber.withOpacity(0.3))),
                  const SizedBox(width: 12),
                  Text(
                    '${groupedInsumos[category]!.length} items',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isDesktop)
            SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 2.2, // Ajustado para que quepa mejor con el nuevo diseño
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  return _buildInsumoCard(
                    groupedInsumos[category]![index],
                    index,
                    screenType,
                    controller,
                  );
                },
                childCount: groupedInsumos[category]!.length,
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  return _buildInsumoCard(
                    groupedInsumos[category]![index],
                    index,
                    screenType,
                    controller,
                  );
                },
                childCount: groupedInsumos[category]!.length,
              ),
            ),
        ],
        const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
      ],
    );
  }

  Map<String, List<InventoryItem>> _groupInsumos(List<InventoryItem> items) {
    final Map<String, List<InventoryItem>> grouped = {};
    for (var item in items) {
      if (!grouped.containsKey(item.category)) {
        grouped[item.category] = [];
      }
      grouped[item.category]!.add(item);
    }
    return grouped;
  }

  Widget _buildInsumoCard(
    InventoryItem insumo,
    int index,
    ScreenType screenType,
    InventoryController controller,
  ) {
    final isDesktop = screenType == ScreenType.desktop;
    final cantidad = insumo.quantity;
    final unidad = insumo.unit;
    final nombre = insumo.itemName;
    final id = insumo.id;

    // Usamos la lógica profesional de stock bajo o vencimiento para el color
    final bool estadoCritico = insumo.isLowStock || insumo.isExpired;

    return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: estadoCritico ? Colors.red.shade100 : Colors.amber.shade100,
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                colors: estadoCritico
                    ? [Colors.red.shade50, Colors.white]
                    : [Colors.amber.shade50, Colors.white],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Padding(
              padding: EdgeInsets.all(isDesktop ? 24 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: estadoCritico
                              ? Colors.red[100]
                              : _getColorForCategory(insumo.category)
                                  .withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          _getIconForCategory(insumo.category),
                          color: estadoCritico
                              ? Colors.red
                              : _getColorForCategory(insumo.category),
                          size: isDesktop ? 26 : 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              nombre,
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                fontSize: isDesktop ? 18 : 16,
                              ),
                            ),
                            Text(
                              'Stock: $cantidad $unidad • ${insumo.category}',
                              style: GoogleFonts.poppins(
                                color: estadoCritico
                                    ? Colors.red
                                    : Colors.grey[600],
                                fontSize: isDesktop ? 14 : 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Alertas y Menú de opciones
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (insumo.isExpired)
                            const Icon(Icons.event_busy, color: Colors.red, size: 20)
                          else if (estadoCritico)
                            const Icon(Icons.warning, color: Colors.red, size: 20),
                          
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert, color: Colors.grey, size: 22),
                            tooltip: 'Más opciones',
                            onSelected: (value) {
                              if (value == 'edit') {
                                _editarInsumo(insumo, controller);
                              } else if (value == 'delete') {
                                _eliminarInsumo(id, controller);
                              }
                            },
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit_outlined, size: 20, color: Colors.amber[800]),
                                    const SizedBox(width: 12),
                                    Text('Editar', style: GoogleFonts.poppins(fontSize: 14)),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete_outline, size: 20, color: Colors.red[700]),
                                    const SizedBox(width: 12),
                                    Text('Eliminar', style: GoogleFonts.poppins(fontSize: 14)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildActionChip(
                        icon: Icons.history,
                        label: 'Historial',
                        color: Colors.blue[700]!,
                        onTap: () => _mostrarHistorial(insumo, controller),
                      ),
                      const SizedBox(width: 8),
                      _buildActionChip(
                        icon: Icons.sync_alt,
                        label: 'Mover',
                        color: Colors.orange[700]!,
                        onTap: () => _mostrarDialogoMovimiento(insumo, controller),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        )
        .animate()
        .fadeIn(delay: Duration(milliseconds: index * 100))
        .slideX(begin: 0.2, end: 0);
  }

  Widget _buildActionChip({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionIcon({
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Material(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, color: color, size: 20),
        ),
      ),
    );
  }

  void _mostrarDialogoMovimiento(InventoryItem insumo, InventoryController controller) {
    int cantidadMovimiento = 1;
    String tipoMovimiento = 'exit'; // Salida por defecto (más común)
    String motivoSeleccionado = 'usage';
    final notasMovController = TextEditingController();

    final motivos = {
      'entry': ['purchase', 'adjustment', 'return'],
      'exit': ['usage', 'adjustment', 'expired', 'loss', 'sale'],
    };

    final motivoLabels = {
      'purchase': 'Compra',
      'usage': 'Uso en Colmena',
      'adjustment': 'Ajuste de Inventario',
      'expired': 'Vencimiento',
      'loss': 'Pérdida/Robo',
      'sale': 'Venta',
      'return': 'Devolución',
    };

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Registrar Movimiento', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(insumo.itemName, style: GoogleFonts.poppins(color: Colors.amber[800], fontWeight: FontWeight.w600)),
              const SizedBox(height: 20),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'exit', label: Text('Salida'), icon: Icon(Icons.remove_circle_outline)),
                  ButtonSegment(value: 'entry', label: Text('Entrada'), icon: Icon(Icons.add_circle_outline)),
                ],
                selected: {tipoMovimiento},
                onSelectionChanged: (val) => setDialogState(() {
                  tipoMovimiento = val.first;
                  motivoSeleccionado = motivos[tipoMovimiento]!.first;
                }),
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                initialValue: motivoSeleccionado,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Motivo', border: OutlineInputBorder()),
                items: motivos[tipoMovimiento]!.map((m) => DropdownMenuItem(value: m, child: Text(motivoLabels[m]!, overflow: TextOverflow.ellipsis))).toList(),
                onChanged: (v) => setDialogState(() => motivoSeleccionado = v!),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      initialValue: '1',
                      decoration: const InputDecoration(labelText: 'Cantidad', border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                      onChanged: (v) => cantidadMovimiento = int.tryParse(v) ?? 0,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(insumo.unit, style: GoogleFonts.poppins(color: Colors.grey)),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: notasMovController,
                decoration: const InputDecoration(labelText: 'Notas (Opcional)', border: OutlineInputBorder()),
                maxLines: 2,
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: tipoMovimiento == 'entry' ? Colors.green : Colors.orange),
              onPressed: () async {
                // Validación profesional de stock local
                if (tipoMovimiento == 'exit' && cantidadMovimiento > insumo.quantity) {
                  _showSnackBar(
                    context, 
                    'En stock es de ${insumo.quantity}, la cantidad no esta en stock', 
                    Colors.red, 
                    Icons.warning_amber_rounded
                  );
                  return; // Detiene la ejecución aquí
                }

                if (cantidadMovimiento <= 0) {
                  _showSnackBar(context, 'La cantidad debe ser mayor a 0', Colors.red, Icons.error);
                  return;
                }

                final error = await controller.registrarMovimiento(
                  itemId: insumo.id,
                  type: tipoMovimiento,
                  quantity: cantidadMovimiento,
                  reason: motivoLabels[motivoSeleccionado] ?? motivoSeleccionado,
                  notes: notasMovController.text,
                  apiaryId: widget.apiaryId,
                );
                if (mounted) {
                  Navigator.pop(context);
                  if (error != null) {
                    _showSnackBar(context, error, Colors.red, Icons.error);
                  } else {
                    _showSnackBar(context, 'Movimiento registrado', Colors.green, Icons.check_circle);
                  }
                }
              },
              child: Text(tipoMovimiento == 'entry' ? 'Cargar Stock' : 'Descargar Stock', style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarHistorial(InventoryItem insumo, InventoryController controller) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  const Icon(Icons.history, color: Colors.amber, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Historial: ${insumo.itemName}', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                        Text('Registro cronológico de cambios', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: controller.obtenerHistorial(insumo.id),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.history_toggle_off, size: 48, color: Colors.grey[300]),
                          const SizedBox(height: 16),
                          Text('No hay movimientos registrados', style: GoogleFonts.poppins(color: Colors.grey)),
                        ],
                      ),
                    );
                  }
                  
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      final mov = snapshot.data![index];
                      final String type = mov['movement_type'] ?? '';
                      final isEntry = type == 'entry' || type == 'create';
                      
                      // Determinar icono y color basado en tipo
                      IconData icon;
                      Color iconColor;
                      switch(type) {
                        case 'create': icon = Icons.add_box; iconColor = Colors.green; break;
                        case 'entry': icon = Icons.arrow_upward; iconColor = Colors.blue; break;
                        case 'exit': icon = Icons.arrow_downward; iconColor = Colors.orange; break;
                        case 'update': icon = Icons.edit_note; iconColor = Colors.purple; break;
                        case 'delete': icon = Icons.delete_forever; iconColor = Colors.red; break;
                        default: icon = Icons.sync_alt; iconColor = Colors.grey;
                      }
                      
                      // Parseo seguro de la fecha
                      DateTime date;
                      try {
                        date = DateTime.parse(mov['date']);
                      } catch (e) {
                        date = DateTime.now();
                      }
                      
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: iconColor.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(icon, color: iconColor, size: 20),
                          ),
                          title: Row(
                            children: [
                              Text(
                                '${isEntry ? "+" : "-"}${mov['quantity']} ${insumo.unit}',
                                style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.black87),
                              ),
                              const Spacer(),
                              Text(
                                DateFormat('dd/MM/yyyy HH:mm').format(date.toLocal()),
                                style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[500]),
                              ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                mov['reason'] ?? 'Sin motivo especificado',
                                style: GoogleFonts.poppins(fontSize: 13, color: Colors.black54),
                              ),
                              if (mov['notes'] != null && mov['notes'].toString().isNotEmpty)
                                Text(
                                  'Nota: ${mov['notes']}',
                                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600], fontStyle: FontStyle.italic),
                                ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  _buildSmallBadge('Antes: ${mov['stock_before']}', Colors.grey),
                                  const SizedBox(width: 8),
                                  _buildSmallBadge('Después: ${mov['stock_after']}', Colors.amber[800]!),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmallBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(fontSize: 10, color: color, fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
        ),
        const SizedBox(height: 4),
        Text(value, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildEmptyState(
    InventoryState state,
    InventoryController controller,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 64, color: Colors.amber[200]),
          const SizedBox(height: 16),
          Text(
            'No hay insumos registrados',
            style: GoogleFonts.poppins(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _mostrarDialogoAgregar(controller),
            icon: const Icon(Icons.add),
            label: const Text('Agregar Insumo'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildAlertas(InventoryState state) {
    if (state.lowStockItems.isEmpty) {
      return [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 16),
              const SizedBox(width: 8),
              Text(
                'Todo en orden',
                style: GoogleFonts.poppins(fontSize: 12, color: Colors.green),
              ),
            ],
          ),
        ),
      ];
    }
    return state.lowStockItems
        .map(
          (item) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning, color: Colors.orange, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Stock bajo: ${item.itemName}',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.orange,
                    ),
                  ),
                ),
              ],
            ),
          ),
        )
        .toList();
  }
}
