import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:Softbee/feature/inventory/data/models/inventory_item.dart';
import 'package:Softbee/feature/inventory/presentation/providers/inventory_controller.dart';
import 'package:Softbee/feature/inventory/presentation/providers/inventory_state.dart';
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
    Key? key,
    required this.mobile,
    this.tablet,
    required this.desktop,
  }) : super(key: key);

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

  const InventoryManagementPage({Key? key, required this.apiaryId})
    : super(key: key);

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
          description: descripcionController.text.trim(),
          minimumStock: 0, // Por defecto 0 ya que se ocultó el campo
        );
      } else {
        itemToSave = InventoryItem(
          id: '',
          itemName: nombreController.text.trim(),
          quantity: int.parse(cantidadController.text),
          unit: unidadSeleccionada,
          apiaryId: widget.apiaryId,
          description: descripcionController.text.trim(),
          minimumStock: 0,
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
    setState(() {
      unidadSeleccionada = 'Unidades';
    });
    controller.setEditingItem(null);
  }

  void _editarInsumo(InventoryItem insumo, InventoryController controller) {
    nombreController.text = insumo.itemName;
    cantidadController.text = insumo.quantity.toString();
    unidadSeleccionada = _normalizarUnidad(insumo.unit);
    descripcionController.text = insumo.description ?? '';
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
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: [
                  Icon(
                    controller.state.isEditing ? Icons.edit : Icons.add_circle,
                    color: Colors.amber,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    controller.state.isEditing
                        ? 'Editar Insumo'
                        : 'Agregar Insumo',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Form(
                  key: _formKeyAgregar,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Completa los detalles del insumo para tu apiario.',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: nombreController,
                        decoration: InputDecoration(
                          labelText: 'Nombre del insumo',
                          labelStyle: GoogleFonts.poppins(),
                          hintText: 'Ej: Traje de apicultor',
                          prefixIcon: const Icon(
                            Icons.inventory_2,
                            color: Colors.amber,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Colors.amber),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Por favor ingresa un nombre';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: cantidadController,
                        decoration: InputDecoration(
                          labelText: 'Cantidad',
                          labelStyle: GoogleFonts.poppins(),
                          hintText: 'Ej: 5',
                          prefixIcon: const Icon(
                            Icons.numbers,
                            color: Colors.amber,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Colors.amber),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Ingresa cantidad';
                          }
                          if (int.tryParse(value) == null) {
                            return 'Número válido';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: unidadSeleccionada,
                        decoration: InputDecoration(
                          labelText: 'Unidad de Medida',
                          labelStyle: GoogleFonts.poppins(),
                          prefixIcon: const Icon(
                            Icons.straighten,
                            color: Colors.amber,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Colors.amber),
                          ),
                        ),
                        items: unidades.map((String unidad) {
                          return DropdownMenuItem<String>(
                            value: unidad,
                            child: Text(unidad, style: GoogleFonts.poppins()),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setDialogState(() {
                            unidadSeleccionada = newValue!;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: descripcionController,
                        decoration: InputDecoration(
                          labelText: 'Descripción (Opcional)',
                          labelStyle: GoogleFonts.poppins(),
                          hintText: 'Ej: Insumos de protección',
                          prefixIcon: const Icon(
                            Icons.description,
                            color: Colors.amber,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Colors.amber),
                          ),
                        ),
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    _limpiarFormulario(controller);
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    'Cancelar',
                    style: GoogleFonts.poppins(color: Colors.grey[600]),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () => _guardarInsumo(controller, controller.state),
                  child: Text(
                    controller.state.isEditing ? 'Actualizar' : 'Agregar',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  List<InventoryItem> _getFilteredInsumos(List<InventoryItem> allItems) {
    if (searchController.text.isEmpty) {
      return allItems;
    }
    return allItems
        .where(
          (insumo) => insumo.itemName.toLowerCase().contains(
            searchController.text.toLowerCase(),
          ),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
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
          const SizedBox(height: 16),
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
              '${state.inventorySummary['updated_at'] != null ? 'Hace unos momentos' : 'N/A'}',
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

    if (isDesktop) {
      return GridView.builder(
        padding: EdgeInsets.zero,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 2.0,
          crossAxisSpacing: 20,
          mainAxisSpacing: 20,
        ),
        itemCount: insumosFiltrados.length,
        itemBuilder: (context, index) {
          return _buildInsumoCard(
            insumosFiltrados[index],
            index,
            screenType,
            controller,
          );
        },
      );
    }

    return ListView.builder(
      itemCount: insumosFiltrados.length,
      itemBuilder: (context, index) {
        return _buildInsumoCard(
          insumosFiltrados[index],
          index,
          screenType,
          controller,
        );
      },
    );
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

    final bool cantidadBaja = cantidad <= 1;

    // Ajustes específicos para cada tamaño de pantalla
    final cardMargin = isMobile
        ? const EdgeInsets.only(bottom: 12)
        : isTablet
        ? const EdgeInsets.only(bottom: 10)
        : EdgeInsets.zero;

    final cardPadding = isDesktop
        ? const EdgeInsets.all(24)
        : isTablet
        ? const EdgeInsets.all(12)
        : const EdgeInsets.all(16);

    final iconSize = isDesktop
        ? 26
        : isTablet
        ? 18
        : 20;
    final titleFontSize = isDesktop
        ? 18
        : isTablet
        ? 14
        : 16;
    final subtitleFontSize = isDesktop
        ? 14
        : isTablet
        ? 11
        : 12;

    return Card(
          margin: cardMargin,
    final bool cantidadBaja = cantidad < 4;

    return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: cantidadBaja ? Colors.red.shade100 : Colors.amber.shade100,
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                colors: cantidadBaja
                    ? [
                        Colors.red[50] ?? Colors.red.shade50,
                        Colors.red[25] ?? Colors.red.shade100,
                      ]
                    : [Colors.amber[50] ?? Colors.amber.shade50, Colors.white],
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
                    children: [
                      Container(
                        padding: EdgeInsets.all(
                          isDesktop
                              ? 12
                              : isTablet
                              ? 6
                              : 8,
                        ),
                        decoration: BoxDecoration(
                          color: cantidadBaja
                              ? Colors.red[100] ?? Colors.red.shade100
                              : Colors.amber[100] ?? Colors.amber.shade100,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: cantidadBaja
                              ? Colors.red[100]
                              : Colors.amber[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.inventory_2,
                          color: cantidadBaja ? Colors.red : Colors.amber[700],
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
                                fontSize: titleFontSize.toDouble(),
                                color: cantidadBaja
                                    ? Colors.red[800] ?? Colors.red
                                    : Colors.grey[800] ?? Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(
                                  'Stock: ',
                                  style: GoogleFonts.poppins(
                                    fontSize: subtitleFontSize.toDouble(),
                                    color: Colors.grey[600] ?? Colors.grey,
                                  ),
                                ),
                                Text(
                                  '$cantidad $unidad',
                                  style: GoogleFonts.poppins(
                                    fontSize: subtitleFontSize.toDouble(),
                                    fontWeight: FontWeight.w600,
                                    color: cantidadBaja
                                        ? Colors.red[700] ?? Colors.red
                                        : Colors.amber[700] ?? Colors.amber,
                                  ),
                                ),
                              ],
                                fontSize: isDesktop ? 18 : 16,
                              ),
                            ),
                            Text(
                              'Stock: $cantidad $unidad',
                              style: GoogleFonts.poppins(
                                color: cantidadBaja
                                    ? Colors.red
                                    : Colors.grey[600],
                                fontSize: isDesktop ? 14 : 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (cantidadBaja)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'STOCK BAJO',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(
                    height: isDesktop
                        ? 16
                        : isTablet
                        ? 10
                        : 12,
                  ),
                  // Botones responsivos
                  isDesktop
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OutlinedButton.icon(
                              icon: const Icon(Icons.edit, size: 16),
                              label: Text(
                                'Editar',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor:
                                    Colors.amber[700] ?? Colors.amber,
                                side: BorderSide(
                                  color: Colors.amber[300] ?? Colors.amber,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                              ),
                              onPressed: () =>
                                  _editarInsumo(insumo, controller),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton.icon(
                              icon: const Icon(Icons.delete, size: 16),
                              label: Text(
                                'Eliminar',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red[700] ?? Colors.red,
                                side: BorderSide(
                                  color: Colors.red[300] ?? Colors.red,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                              ),
                              onPressed: () => _eliminarInsumo(id, controller),
                            ),
                          ],
                        )
                      : Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                icon: Icon(
                                  Icons.edit,
                                  size: isTablet ? 14 : 16,
                                ),
                                label: Text(
                                  'Editar',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w500,
                                    fontSize: isTablet ? 12 : 14,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor:
                                      Colors.amber[700] ?? Colors.amber,
                                  side: BorderSide(
                                    color: Colors.amber[300] ?? Colors.amber,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                onPressed: () =>
                                    _editarInsumo(insumo, controller),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                icon: Icon(
                                  Icons.delete,
                                  size: isTablet ? 14 : 16,
                                ),
                                label: Text(
                                  'Eliminar',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w500,
                                    fontSize: isTablet ? 12 : 14,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor:
                                      Colors.red[700] ?? Colors.red,
                                  side: BorderSide(
                                    color: Colors.red[300] ?? Colors.red,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                onPressed: () =>
                                    _eliminarInsumo(id, controller),
                              ),
                            ),
                          ],
                        ),
                        const Icon(Icons.warning, color: Colors.red, size: 20),
                    ],
                  ),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton.icon(
                        icon: const Icon(Icons.edit, size: 16),
                        label: const Text('Editar'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.amber[700],
                          side: BorderSide(color: Colors.amber[300]!),
                        ),
                        onPressed: () => _editarInsumo(insumo, controller),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.delete, size: 16),
                        label: const Text('Eliminar'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red[700],
                          side: BorderSide(color: Colors.red[300]!),
                        ),
                        onPressed: () => _eliminarInsumo(id, controller),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        )
        .animate()
        .fadeIn(
          duration: 600.ms,
          delay: Duration(milliseconds: index * 100),
        )
        .slideX(
          begin: 0.2,
          end: 0,
          duration: 600.ms,
          curve: Curves.easeOutQuad,
        );
  }

  // Widgets auxiliares
        .fadeIn(delay: Duration(milliseconds: index * 100))
        .slideX(begin: 0.2, end: 0);
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
                ),
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
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
