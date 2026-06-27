import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:Softbee/feature/apiaries/presentation/providers/apiary_providers.dart';
import 'package:Softbee/feature/apiaries/domain/entities/apiary.dart';
import '../../domain/entities/question_model.dart';
import '../providers/questions_providers.dart';
import '../widgets/monitoring_widgets.dart';

class QuestionsManagementScreen extends ConsumerStatefulWidget {
  final String apiaryId;
  const QuestionsManagementScreen({super.key, required this.apiaryId});

  @override
  ConsumerState<QuestionsManagementScreen> createState() =>
      _QuestionsManagementScreenState();
}

class _QuestionsManagementScreenState
    extends ConsumerState<QuestionsManagementScreen> {
  // Controladores
  final TextEditingController _preguntaController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _minController = TextEditingController();
  final TextEditingController _maxController = TextEditingController();
  final TextEditingController _bankSearchController = TextEditingController();

  String? selectedApiarioId;
  String tipoRespuestaSeleccionado = "texto";
  bool obligatoriaSeleccionada = false;
  String? selectedCategoria;

  // Colores del diseño original
  final Color colorAmarillo = const Color(0xFFFBC209);
  final Color colorNaranja = const Color(0xFFFF9800);
  final Color colorAmbarClaro = const Color(0xFFFFF8E1);
  final Color colorVerde = const Color(0xFF4CAF50);
  final Color colorAmarilloOscuro = const Color(0xFFF57C00);
  final Color colorMorado = const Color(0xFF9C27B0);

  @override
  void initState() {
    super.initState();
    selectedApiarioId = widget.apiaryId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(apiariesControllerProvider.notifier).fetchApiaries();
      ref
          .read(questionsControllerProvider.notifier)
          .fetchPreguntas(widget.apiaryId);
      ref.read(questionsControllerProvider.notifier).fetchTemplates();
    });
  }

  @override
  void dispose() {
    _preguntaController.dispose();
    _searchController.dispose();
    _categoryController.dispose();
    _minController.dispose();
    _maxController.dispose();
    _bankSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final apiariesState = ref.watch(apiariesControllerProvider);
    final questionsState = ref.watch(questionsControllerProvider);

    return Scaffold(
      backgroundColor: colorAmbarClaro,
      appBar: AppBar(
        backgroundColor: colorAmarillo,
        title: Text(
          'Gestión de Preguntas',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync, color: Colors.white),
            onPressed: () => ref
                .read(questionsControllerProvider.notifier)
                .fetchPreguntas(widget.apiaryId),
          ),
        ],
      ),
      body: questionsState.isLoading || apiariesState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildHeader(apiariesState.allApiaries, questionsState),
                Expanded(child: _buildPreguntasList(questionsState.preguntas)),
              ],
            ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: "bank",
            onPressed: _showQuestionBankDialog,
            backgroundColor: colorAmarilloOscuro,
            child: const Icon(Icons.library_books, color: Colors.white),
          ).animate().scale(delay: 200.ms),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: "new",
            onPressed: () => _showPreguntaDialog(),
            backgroundColor: colorVerde,
            icon: const Icon(Icons.add, color: Colors.white),
            label: Text(
              'Nueva Pregunta',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ).animate().scale(delay: 400.ms),
        ],
      ),
    );
  }

  Widget _buildHeader(List<Apiary> apiarios, QuestionsState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          EnhancedCardWidget(
            title: 'Apiario Actual',
            icon: Icons.location_on,
            color: colorNaranja,
            isCompact: true,
            animationDelay: 0,
            trailing: SizedBox(
              width: 200,
              child: DropdownButtonFormField<String>(
                value: selectedApiarioId,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                items: apiarios.map((apiario) {
                  return DropdownMenuItem<String>(
                    value: apiario.id,
                    child: Text(
                      apiario.name,
                      style: GoogleFonts.poppins(fontSize: 12),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => selectedApiarioId = value);
                    ref
                        .read(questionsControllerProvider.notifier)
                        .fetchPreguntas(value);
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: StatCardWidget(
                  label: 'Total',
                  value: state.preguntas.length.toString(),
                  icon: Icons.quiz,
                  color: colorVerde,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: StatCardWidget(
                  label: 'Activas',
                  value: state.preguntas
                      .where((p) => p.activa)
                      .length
                      .toString(),
                  icon: Icons.check_circle,
                  color: colorAmarillo,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: StatCardWidget(
                  label: 'Banco',
                  value: state.templates.length.toString(),
                  icon: Icons.library_books,
                  color: colorAmarilloOscuro,
                  onTap: _showQuestionBankDialog,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPreguntasList(List<Pregunta> preguntas) {
    if (preguntas.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.quiz_outlined,
              size: 64,
              color: colorNaranja.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No hay preguntas en este apiario',
              style: GoogleFonts.poppins(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    Map<String, List<Pregunta>> grouped = {};
    for (var p in preguntas) {
      final cat = p.categoria ?? 'Sin Categoría';
      if (grouped[cat] == null) grouped[cat] = [];
      grouped[cat]!.add(p);
    }

    final sortedCats = grouped.keys.toList()..sort();

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: sortedCats.length,
      itemBuilder: (context, index) {
        final category = sortedCats[index];
        final items = grouped[category]!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                category,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: colorNaranja,
                ),
              ),
            ),
            ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              buildDefaultDragHandles: false,
              itemCount: items.length,
              onReorder: (oldIndex, newIndex) =>
                  _onReorderWithinCategory(category, items, oldIndex, newIndex),
              itemBuilder: (context, idx) {
                final pregunta = items[idx];
                return _buildQuestionCard(pregunta, idx);
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildQuestionCard(Pregunta pregunta, int indexInGroup) {
    return Card(
      key: ValueKey(pregunta.id),
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: ReorderableDragStartListener(
          index: indexInGroup,
          child: Icon(Icons.drag_handle, color: colorNaranja),
        ),
        title: Text(
          pregunta.texto,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w500,
            color: pregunta.activa ? Colors.black87 : Colors.grey,
            decoration: pregunta.activa ? null : TextDecoration.lineThrough,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${pregunta.tipoRespuesta} ${pregunta.obligatoria ? "(Obligatoria)" : ""}',
              style: TextStyle(
                color: pregunta.activa ? Colors.black54 : Colors.grey,
              ),
            ),
            if (pregunta.tipoRespuesta == 'opciones' &&
                pregunta.opciones != null) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: pregunta.opciones!
                    .map(
                      (opt) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: colorAmbarClaro,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: colorAmarillo.withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          opt,
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: colorAmarilloOscuro,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Switch(
              value: pregunta.activa,
              activeColor: colorVerde,
              onChanged: (val) {
                ref
                    .read(questionsControllerProvider.notifier)
                    .updatePregunta(pregunta.copyWith(activa: val));
              },
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (val) {
                if (val == 'delete') _confirmDelete(pregunta);
                if (val == 'edit') _showPreguntaDialog(pregunta: pregunta);
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'edit', child: Text('Editar')),
                const PopupMenuItem(value: 'delete', child: Text('Eliminar')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _onReorderWithinCategory(
    String category,
    List<Pregunta> categoryItems,
    int oldIndex,
    int newIndex,
  ) {
    if (newIndex > oldIndex) newIndex -= 1;

    final List<Pregunta> reorderedCategory = List<Pregunta>.from(categoryItems);
    final Pregunta movedItem = reorderedCategory.removeAt(oldIndex);
    reorderedCategory.insert(newIndex, movedItem);

    final state = ref.read(questionsControllerProvider);
    final allPreguntas = List<Pregunta>.from(state.preguntas);

    // Mapeamos los IDs manteniendo la posición global de la categoría
    final List<String> currentOrderIds = allPreguntas.map((p) => p.id).toList();
    final List<int> categoryIndices = [];

    for (int i = 0; i < allPreguntas.length; i++) {
      if ((allPreguntas[i].categoria ?? 'Sin Categoría') == category) {
        categoryIndices.add(i);
      }
    }

    for (int i = 0; i < categoryIndices.length; i++) {
      currentOrderIds[categoryIndices[i]] = reorderedCategory[i].id;
    }

    ref
        .read(questionsControllerProvider.notifier)
        .reorderPreguntas(selectedApiarioId!, currentOrderIds);
  }

  void _showQuestionBankDialog() {
    showDialog(
      context: context,
      builder: (context) {
        final state = ref.watch(questionsControllerProvider);
        return StatefulBuilder(
          builder: (context, setDialogState) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Container(
              width: MediaQuery.of(context).size.width * 0.9,
              height: MediaQuery.of(context).size.height * 0.8,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [colorAmarilloOscuro, colorNaranja],
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.library_books, color: Colors.white),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Banco de Preguntas',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: state.templates.length,
                      itemBuilder: (context, index) {
                        final template = state.templates[index];
                        return ListTile(
                          title: Text(
                            template.texto,
                            style: GoogleFonts.poppins(fontSize: 14),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (template.categoria != null)
                                Text(
                                  template.categoria!,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              if (template.tipoRespuesta == 'opciones' &&
                                  template.opciones != null)
                                Text(
                                  'Opciones: ${template.opciones!.join(", ")}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey,
                                  ),
                                ),
                            ],
                          ),
                          trailing: IconButton(
                            icon: Icon(Icons.add_circle, color: colorVerde),
                            onPressed: () {
                              ref
                                  .read(questionsControllerProvider.notifier)
                                  .createPregunta(
                                    template.copyWith(
                                      apiarioId: selectedApiarioId!,
                                    ),
                                  );
                              Navigator.pop(context);
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showPreguntaDialog({Pregunta? pregunta}) {
    final isEditing = pregunta != null;
    if (isEditing) {
      _preguntaController.text = pregunta.texto;
      _categoryController.text = pregunta.categoria ?? '';
      tipoRespuestaSeleccionado = pregunta.tipoRespuesta;
      obligatoriaSeleccionada = pregunta.obligatoria;
      _minController.text = pregunta.min?.toString() ?? '';
      _maxController.text = pregunta.max?.toString() ?? '';
    } else {
      _preguntaController.clear();
      _categoryController.clear();
      _minController.clear();
      _maxController.clear();
      tipoRespuestaSeleccionado = "texto";
      obligatoriaSeleccionada = false;
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEditing ? 'Editar Pregunta' : 'Nueva Pregunta'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _preguntaController,
                  decoration: const InputDecoration(labelText: 'Pregunta'),
                  maxLines: 2,
                ),
                TextField(
                  controller: _categoryController,
                  decoration: const InputDecoration(labelText: 'Categoría'),
                ),
                DropdownButtonFormField<String>(
                  value: tipoRespuestaSeleccionado,
                  items: ['texto', 'numero', 'opciones']
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (val) =>
                      setDialogState(() => tipoRespuestaSeleccionado = val!),
                  decoration: const InputDecoration(
                    labelText: 'Tipo de respuesta',
                  ),
                ),
                if (tipoRespuestaSeleccionado == 'numero') ...[
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _minController,
                          decoration: const InputDecoration(labelText: 'Mín'),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _maxController,
                          decoration: const InputDecoration(labelText: 'Máx'),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                ],
                CheckboxListTile(
                  title: const Text('Obligatoria'),
                  value: obligatoriaSeleccionada,
                  onChanged: (val) =>
                      setDialogState(() => obligatoriaSeleccionada = val!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                final newPregunta = Pregunta(
                  id: pregunta?.id ?? '',
                  apiarioId: selectedApiarioId!,
                  texto: _preguntaController.text,
                  tipoRespuesta: tipoRespuestaSeleccionado,
                  categoria: _categoryController.text,
                  obligatoria: obligatoriaSeleccionada,
                  orden: pregunta?.orden ?? 0,
                  min: int.tryParse(_minController.text),
                  max: int.tryParse(_maxController.text),
                );
                if (isEditing) {
                  ref
                      .read(questionsControllerProvider.notifier)
                      .updatePregunta(newPregunta);
                } else {
                  ref
                      .read(questionsControllerProvider.notifier)
                      .createPregunta(newPregunta);
                }
                Navigator.pop(context);
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(Pregunta pregunta) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Pregunta'),
        content: Text('¿Deseas eliminar "${pregunta.texto}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              ref
                  .read(questionsControllerProvider.notifier)
                  .deletePregunta(pregunta.id, selectedApiarioId!);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text(
              'Eliminar',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
