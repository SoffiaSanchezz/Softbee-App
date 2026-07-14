import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:Softbee/feature/apiaries/presentation/providers/apiary_providers.dart';
import 'package:Softbee/feature/apiaries/domain/entities/apiary.dart';
import 'package:Softbee/feature/beehive/presentation/providers/beehive_providers.dart';
import 'package:Softbee/feature/beehive/presentation/controllers/beehive_controller.dart';
import '../../domain/entities/question_model.dart';
import '../providers/questions_providers.dart';
import '../providers/hive_questions_selection_controller.dart';
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
  String? selectedApiarioId;
  String? selectedHiveId;

  // Colores del tema Softbee
  final Color colorAmarillo = const Color(0xFFFBC209);
  final Color colorNaranja = const Color(0xFFFF9800);
  final Color colorAmbarClaro = const Color(0xFFFFF8E1);
  final Color colorVerde = const Color(0xFF4CAF50);
  final Color colorAzulHeredado = const Color(0xFF2196F3);
  final Color colorAmarilloOscuro = const Color(0xFFF57C00);

  @override
  void initState() {
    super.initState();
    selectedApiarioId = widget.apiaryId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(apiariesControllerProvider.notifier).fetchApiaries();
      ref.read(beehiveControllerProvider.notifier).fetchBeehivesByApiary(widget.apiaryId);
      ref.read(questionsControllerProvider.notifier).fetchPreguntas(widget.apiaryId);
      ref.read(questionsControllerProvider.notifier).fetchTemplates();
    });
  }

  void _onHiveSelected(String? hiveId) {
    setState(() {
      selectedHiveId = hiveId;
    });
    if (hiveId != null) {
      ref.read(hiveQuestionsSelectionProvider(hiveId).notifier).load(widget.apiaryId, hiveId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final apiariesState = ref.watch(apiariesControllerProvider);
    final questionsState = ref.watch(questionsControllerProvider);
    final beehiveState = ref.watch(beehiveControllerProvider);

    return Scaffold(
      backgroundColor: colorAmbarClaro,
      appBar: AppBar(
        backgroundColor: colorAmarillo,
        elevation: 0,
        title: Text(
          'Gestión de Preguntas',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync, color: Colors.white),
            onPressed: () {
              ref.read(questionsControllerProvider.notifier).fetchPreguntas(widget.apiaryId);
              if (selectedHiveId != null) {
                ref.read(hiveQuestionsSelectionProvider(selectedHiveId!).notifier).load(widget.apiaryId, selectedHiveId!);
              }
            },
          ),
        ],
      ),
      body: questionsState.isLoading || apiariesState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildHeader(apiariesState.allApiaries, questionsState),
                _buildHiveSelector(beehiveState),
                Expanded(
                  child: selectedHiveId == null 
                    ? _buildGeneralBankList(questionsState.preguntas)
                    : _buildHiveAssignmentList(),
                ),
              ],
            ),
      floatingActionButton: selectedHiveId != null ? null : Column(
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
              style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ).animate().scale(delay: 400.ms),
        ],
      ),
    );
  }

  // --- SELECTOR DE COLMENA ---
  Widget _buildHiveSelector(BeehiveState state) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)],
        border: Border.all(color: colorAmarillo.withOpacity(0.3)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedHiveId,
          hint: Text('Asignar preguntas a colmena...', style: GoogleFonts.poppins(fontSize: 13)),
          isExpanded: true,
          icon: Icon(Icons.hive_rounded, color: colorAmarilloOscuro),
          items: [
            DropdownMenuItem(
              value: null,
              child: Text('--- Gestionar Banco del Apiario (Principal) ---', 
                style: GoogleFonts.poppins(fontSize: 13, color: colorAmarilloOscuro, fontWeight: FontWeight.bold)),
            ),
            ...state.beehives.map((hive) => DropdownMenuItem(
              value: hive.id,
              child: Text('Colmena #${hive.beehiveNumber}', style: GoogleFonts.poppins(fontSize: 13)),
            )),
          ],
          onChanged: _onHiveSelected,
        ),
      ),
    ).animate().fadeIn();
  }

  // --- LISTA DE ASIGNACIÓN CON HERENCIA ---
  Widget _buildHiveAssignmentList() {
    final hiveSelectionState = ref.watch(hiveQuestionsSelectionProvider(selectedHiveId!));
    final hiveSelectionController = ref.read(hiveQuestionsSelectionProvider(selectedHiveId!).notifier);

    if (hiveSelectionState.isLoading) return const Center(child: CircularProgressIndicator());

    final heredadas = hiveSelectionState.selections.where((s) => s.isInherited).toList();
    final personalizadas = hiveSelectionState.selections.where((s) => !s.isInherited && s.isSelected).toList();
    final disponibles = hiveSelectionState.selections.where((s) => !s.isInherited && !s.isSelected).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      children: [
        _buildInheritanceInfo(),
        _buildSectionHeader('Heredadas del Apiario (${heredadas.length})', Icons.auto_awesome, colorAzulHeredado),
        if (heredadas.isEmpty) 
          _buildEmptySection('No hay preguntas activas en el banco del apiario.')
        else
          ...heredadas.map((s) => _buildAssignmentCard(s, hiveSelectionController)),

        const SizedBox(height: 20),
        _buildSectionHeader('Preguntas de la Colmena (${personalizadas.length})', Icons.check_circle, colorVerde),
        if (personalizadas.isEmpty)
          _buildEmptySection('Sin preguntas personalizadas.')
        else
          ...personalizadas.map((s) => _buildAssignmentCard(s, hiveSelectionController)),

        const SizedBox(height: 20),
        _buildSectionHeader('Banco Disponible (${disponibles.length})', Icons.add_circle_outline, colorNaranja),
        if (disponibles.isEmpty)
          _buildEmptySection('Todas las preguntas han sido asignadas.')
        else
          ...disponibles.map((s) => _buildAssignmentCard(s, hiveSelectionController)),
      ],
    );
  }

  Widget _buildInheritanceInfo() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorAzulHeredado.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorAzulHeredado.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: colorAzulHeredado, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Las preguntas activas en el apiario se aplican automáticamente a todas las colmenas.',
              style: GoogleFonts.poppins(fontSize: 11, color: colorAzulHeredado),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13, color: color)),
          const Expanded(child: Divider(indent: 12)),
        ],
      ),
    );
  }

  Widget _buildEmptySection(String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Text(message, style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey, fontStyle: FontStyle.italic)),
    );
  }

  Widget _buildAssignmentCard(HiveQuestionSelection selection, HiveQuestionsSelectionController controller) {
    final bool isHeredada = selection.isInherited;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      elevation: selection.isSelected ? 1 : 0,
      color: isHeredada ? Colors.blue[50] : (selection.isSelected ? Colors.green[50] : Colors.white),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: isHeredada ? colorAzulHeredado.withOpacity(0.3) : (selection.isSelected ? colorVerde.withOpacity(0.3) : Colors.grey.withOpacity(0.1)),
        ),
      ),
      child: CheckboxListTile(
        title: Text(
          selection.pregunta.texto,
          style: GoogleFonts.poppins(
            fontWeight: selection.isSelected ? FontWeight.w600 : FontWeight.w400,
            fontSize: 13,
            color: isHeredada ? Colors.blue[900] : (selection.isSelected ? Colors.green[900] : Colors.black87),
          ),
        ),
        subtitle: Row(
          children: [
            Text('${selection.pregunta.categoria ?? 'General'} • ${selection.pregunta.tipoRespuesta}', 
              style: TextStyle(fontSize: 10, color: isHeredada ? Colors.blue[700] : Colors.grey)),
            if (isHeredada) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(color: colorAzulHeredado, borderRadius: BorderRadius.circular(4)),
                child: const Text('AUTOMÁTICA', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
              ),
            ],
          ],
        ),
        value: selection.isSelected,
        activeColor: isHeredada ? colorAzulHeredado : colorVerde,
        onChanged: isHeredada ? null : (_) => controller.toggleQuestion(selectedHiveId!, selection),
      ),
    ).animate().fadeIn(duration: 200.ms);
  }

  // --- LISTA GENERAL (MODO APIARIO) ---
  Widget _buildGeneralBankList(List<Pregunta> preguntas) {
    if (preguntas.isEmpty) return _buildEmptyState();

    Map<String, List<Pregunta>> grouped = {};
    for (var p in preguntas) {
      final cat = p.categoria ?? 'Sin Categoría';
      if (grouped[cat] == null) grouped[cat] = [];
      grouped[cat]!.add(p);
    }

    final sortedCats = grouped.keys.toList()..sort();

    return ListView.builder(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 120),
      itemCount: sortedCats.length,
      itemBuilder: (context, index) {
        final category = sortedCats[index];
        final items = grouped[category]!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
              child: Row(
                children: [
                  Icon(Icons.folder_open_rounded, color: colorAmarilloOscuro, size: 20),
                  const SizedBox(width: 10),
                  Text(category, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: colorAmarilloOscuro)),
                  const SizedBox(width: 12),
                  Expanded(child: Divider(color: colorAmarilloOscuro.withOpacity(0.2))),
                ],
              ),
            ),
            ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              buildDefaultDragHandles: false,
              itemCount: items.length,
              onReorder: (old, newVal) => _onReorderWithinCategory(category, items, old, newVal),
              itemBuilder: (context, idx) => _buildQuestionCard(items[idx], idx),
            ),
          ],
        );
      },
    );
  }

  Widget _buildQuestionCard(Pregunta pregunta, int indexInGroup) {
    return Card(
      key: ValueKey(pregunta.id),
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shadowColor: colorAmarillo.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: pregunta.activa ? colorAmarillo.withOpacity(0.2) : Colors.grey.withOpacity(0.1)),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: pregunta.activa ? [Colors.white, colorAmbarClaro.withOpacity(0.3)] : [Colors.white, Colors.grey[50]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Column(
            children: [
              ListTile(
                contentPadding: const EdgeInsets.only(left: 8, right: 12),
                leading: ReorderableDragStartListener(
                  index: indexInGroup,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: colorAmarillo.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                    child: Icon(Icons.drag_indicator_rounded, color: colorAmarilloOscuro, size: 20),
                  ),
                ),
                title: Text(
                  pregunta.texto,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: pregunta.activa ? Colors.black87 : Colors.grey[600],
                  ),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    children: [
                      _buildInfoTag(pregunta.tipoRespuesta.toUpperCase(), colorNaranja),
                      if (pregunta.obligatoria) ...[
                        const SizedBox(width: 6),
                        _buildInfoTag('OBLIGATORIA', Colors.redAccent),
                      ],
                    ],
                  ),
                ),
                trailing: Switch(
                  value: pregunta.activa,
                  activeColor: colorVerde,
                  activeTrackColor: colorVerde.withOpacity(0.3),
                  onChanged: (val) {
                    ref.read(questionsControllerProvider.notifier).updatePregunta(pregunta.copyWith(activa: val));
                    if (selectedHiveId != null) {
                      ref.read(hiveQuestionsSelectionProvider(selectedHiveId!).notifier).load(widget.apiaryId, selectedHiveId!);
                    }
                  },
                ),
              ),
              if (pregunta.tipoRespuesta == 'opciones' && pregunta.opciones != null)
                _buildOptionsPreview(pregunta.opciones!),
              if (pregunta.tipoRespuesta == 'numero' && (pregunta.min != null || pregunta.max != null))
                _buildRangePreview(pregunta.min, pregunta.max),
              
              const Divider(height: 1, indent: 60),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => _showPreguntaDialog(pregunta: pregunta),
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    label: const Text('Editar', style: TextStyle(fontSize: 12)),
                    style: TextButton.styleFrom(foregroundColor: colorAmarilloOscuro),
                  ),
                  TextButton.icon(
                    onPressed: () => _confirmDelete(pregunta),
                    icon: const Icon(Icons.delete_outline_rounded, size: 16),
                    label: const Text('Eliminar', style: TextStyle(fontSize: 12)),
                    style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6), border: Border.all(color: color.withOpacity(0.2))),
      child: Text(text, style: GoogleFonts.poppins(fontSize: 9, fontWeight: FontWeight.bold, color: color)),
    );
  }

  Widget _buildOptionsPreview(List<String> opciones) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(60, 0, 16, 12),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: opciones.map((opt) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey[200]!)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.radio_button_checked, size: 10, color: colorAmarillo),
              const SizedBox(width: 6),
              Text(opt, style: GoogleFonts.poppins(fontSize: 11, color: Colors.black54)),
            ],
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildRangePreview(int? min, int? max) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(60, 0, 16, 12),
      child: Row(
        children: [
          Icon(Icons.linear_scale_rounded, size: 14, color: colorNaranja),
          const SizedBox(width: 8),
          Text(
            'Rango aceptado: ${min ?? "N/A"} a ${max ?? "N/A"}',
            style: GoogleFonts.poppins(fontSize: 11, color: Colors.black54, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.quiz_outlined, size: 64, color: colorNaranja.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text('No hay preguntas en este apiario', style: GoogleFonts.poppins(color: Colors.grey[600])),
        ],
      ),
    );
  }

  void _onReorderWithinCategory(String category, List<Pregunta> categoryItems, int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex -= 1;
    final List<Pregunta> reorderedCategory = List<Pregunta>.from(categoryItems);
    final Pregunta movedItem = reorderedCategory.removeAt(oldIndex);
    reorderedCategory.insert(newIndex, movedItem);

    final state = ref.read(questionsControllerProvider);
    final List<String> currentOrderIds = state.preguntas.map((p) => p.id).toList();
    
    int catIdx = 0;
    for (int i = 0; i < state.preguntas.length; i++) {
      if ((state.preguntas[i].categoria ?? 'Sin Categoría') == category) {
        currentOrderIds[i] = reorderedCategory[catIdx].id;
        catIdx++;
      }
    }
    ref.read(questionsControllerProvider.notifier).reorderPreguntas(widget.apiaryId, currentOrderIds);
  }

  Widget _buildHeader(List<Apiary> apiarios, QuestionsState state) {
    final currentApiary = apiarios.firstWhere((a) => a.id == widget.apiaryId, 
      orElse: () => Apiary(id: '', name: 'Cargando...', userId: ''));

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          EnhancedCardWidget(
            title: 'Apiario Actual',
            icon: Icons.location_on,
            color: colorNaranja,
            trailing: Text(currentApiary.name, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: colorNaranja)),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: StatCardWidget(label: 'Total Banco', value: state.preguntas.length.toString(), icon: Icons.quiz, color: colorAzulHeredado)),
              const SizedBox(width: 8),
              Expanded(child: StatCardWidget(label: 'Plantillas', value: state.templates.length.toString(), icon: Icons.library_books, color: colorAmarilloOscuro, onTap: _showQuestionBankDialog)),
            ],
          ),
        ],
      ),
    );
  }

  void _showQuestionBankDialog() {
    showDialog(
      context: context,
      builder: (context) {
        final state = ref.watch(questionsControllerProvider);
        final existingTexts = state.preguntas.map((p) => p.texto.trim().toLowerCase()).toSet();
        final missingTemplates = state.templates.where((t) => !existingTexts.contains(t.texto.trim().toLowerCase())).toList();

        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.height * 0.8,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [colorAmarilloOscuro, colorNaranja]),
                    borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.library_books, color: Colors.white, size: 28),
                          const SizedBox(width: 12),
                          const Expanded(child: Text('Banco de Preguntas', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold))),
                          IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, color: Colors.white)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: missingTemplates.isEmpty ? null : () {
                            ref.read(questionsControllerProvider.notifier).loadDefaults(widget.apiaryId);
                            Navigator.pop(context);
                          },
                          icon: const Icon(Icons.auto_awesome),
                          label: Text(missingTemplates.isEmpty ? 'Apiario Completo' : 'Importar ${missingTemplates.length} Nuevas'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: colorAmarilloOscuro, elevation: 0, padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    itemCount: state.templates.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, idx) {
                      final template = state.templates[idx];
                      final bool exists = existingTexts.contains(template.texto.trim().toLowerCase());
                      return ListTile(
                        leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: exists ? Colors.grey[100] : colorVerde.withOpacity(0.1), shape: BoxShape.circle), child: Icon(exists ? Icons.check : Icons.add, color: exists ? Colors.grey : colorVerde, size: 20)),
                        title: Text(template.texto, style: TextStyle(color: exists ? Colors.grey : Colors.black87, fontSize: 14, fontWeight: FontWeight.w500)),
                        subtitle: Text(exists ? 'Ya en apiario' : '${template.categoria ?? "General"} • ${template.tipoRespuesta}', style: TextStyle(fontSize: 11, color: exists ? colorVerde : Colors.grey)),
                        onTap: exists ? null : () {
                          ref.read(questionsControllerProvider.notifier).createPregunta(template.copyWith(apiarioId: widget.apiaryId));
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showPreguntaDialog({Pregunta? pregunta}) {
    showDialog(context: context, builder: (context) => _PreguntaFormDialog(apiaryId: widget.apiaryId, pregunta: pregunta));
  }

  void _confirmDelete(Pregunta pregunta) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Pregunta'),
        content: Text('¿Deseas eliminar "${pregunta.texto}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () {
            ref.read(questionsControllerProvider.notifier).deletePregunta(pregunta.id, widget.apiaryId);
            Navigator.pop(context);
          }, style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: const Text('Eliminar', style: TextStyle(color: Colors.white))),
        ],
      ),
    );
  }
}

// --- DIÁLOGO DE FORMULARIO MEJORADO ---
class _PreguntaFormDialog extends ConsumerStatefulWidget {
  final String apiaryId;
  final Pregunta? pregunta;
  const _PreguntaFormDialog({required this.apiaryId, this.pregunta});
  @override
  ConsumerState<_PreguntaFormDialog> createState() => _PreguntaFormDialogState();
}

class _PreguntaFormDialogState extends ConsumerState<_PreguntaFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _preguntaController;
  late TextEditingController _categoryController;
  late TextEditingController _minController;
  late TextEditingController _maxController;
  final List<TextEditingController> _opcionesControllers = [];
  
  late String _tipoRespuesta;
  late bool _obligatoria;
  String? _selectedCategoryValue;
  bool _isAddingNewCategory = false;

  final Color colorAmarillo = const Color(0xFFFBC209);
  final Color colorNaranja = const Color(0xFFFF9800);
  final Color colorVerde = const Color(0xFF4CAF50);

  @override
  void initState() {
    super.initState();
    final isEdit = widget.pregunta != null;
    _preguntaController = TextEditingController(text: isEdit ? widget.pregunta!.texto : '');
    _categoryController = TextEditingController(text: isEdit ? (widget.pregunta!.categoria ?? 'General') : 'General');
    _minController = TextEditingController(text: isEdit ? widget.pregunta!.min?.toString() : '');
    _maxController = TextEditingController(text: isEdit ? widget.pregunta!.max?.toString() : '');
    
    _tipoRespuesta = isEdit ? widget.pregunta!.tipoRespuesta : "texto";
    _obligatoria = isEdit ? widget.pregunta!.obligatoria : false;
    _selectedCategoryValue = isEdit ? widget.pregunta!.categoria : 'General';

    if (isEdit && widget.pregunta!.opciones != null) {
      for (var opt in widget.pregunta!.opciones!) {
        _opcionesControllers.add(TextEditingController(text: opt));
      }
    }
    _ensureMinimumOptions();
  }

  void _ensureMinimumOptions() {
    if (_tipoRespuesta == 'opciones' && _opcionesControllers.length < 2) {
      while (_opcionesControllers.length < 2) {
        _opcionesControllers.add(TextEditingController());
      }
    }
  }

  @override
  void dispose() {
    _preguntaController.dispose();
    _categoryController.dispose();
    _minController.dispose();
    _maxController.dispose();
    for (var c in _opcionesControllers) {
      c.dispose();
    }
    super.dispose();
  }

  InputDecoration _inputDecor(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.poppins(fontSize: 14),
      prefixIcon: Icon(icon, color: colorAmarillo, size: 20),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: colorAmarillo, width: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(questionsControllerProvider);
    List<String> categories = state.preguntas.map((p) => p.categoria ?? 'General').toSet().toList();
    if (!categories.contains('General')) categories.add('General');
    categories.sort();

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Row(
        children: [
          Icon(widget.pregunta != null ? Icons.edit_rounded : Icons.add_circle_rounded, color: colorAmarillo),
          const SizedBox(width: 12),
          Text(
            widget.pregunta != null ? 'Editar Pregunta' : 'Nueva Pregunta',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ],
      ),
      content: SizedBox(
        width: 450,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                TextFormField(
                  controller: _preguntaController,
                  style: GoogleFonts.poppins(fontSize: 14),
                  decoration: _inputDecor('Texto de la Pregunta', Icons.help_outline),
                  validator: (v) => v == null || v.trim().isEmpty ? 'La pregunta es requerida' : null,
                ),
                const SizedBox(height: 16),
                
                DropdownButtonFormField<String>(
                  value: _isAddingNewCategory ? 'NEW' : (categories.contains(_selectedCategoryValue) ? _selectedCategoryValue : 'General'),
                  style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87),
                  decoration: _inputDecor('Categoría', Icons.folder_open),
                  items: [
                    ...categories.map((c) => DropdownMenuItem(value: c, child: Text(c, style: GoogleFonts.poppins()))),
                    DropdownMenuItem(
                      value: 'NEW', 
                      child: Text('+ Crear nueva categoría', style: GoogleFonts.poppins(color: Colors.orange, fontWeight: FontWeight.bold))
                    ),
                  ],
                  onChanged: (v) => setState(() {
                    if (v == 'NEW') {
                      _isAddingNewCategory = true;
                      _categoryController.clear();
                    } else {
                      _isAddingNewCategory = false;
                      _selectedCategoryValue = v;
                      _categoryController.text = v!;
                    }
                  }),
                ),
                if (_isAddingNewCategory) ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _categoryController,
                    style: GoogleFonts.poppins(fontSize: 14),
                    decoration: _inputDecor('Nombre de Categoría', Icons.create_new_folder_outlined),
                    validator: (v) => _isAddingNewCategory && (v == null || v.trim().isEmpty) ? 'Ingresa un nombre' : null,
                  ),
                ],
                
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _tipoRespuesta,
                  style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87),
                  decoration: _inputDecor('Tipo de Respuesta', Icons.input_rounded),
                  items: ['texto', 'numero', 'opciones'].map((t) => DropdownMenuItem(value: t, child: Text(t.toUpperCase(), style: GoogleFonts.poppins()))).toList(),
                  onChanged: (v) => setState(() {
                    _tipoRespuesta = v!;
                    _ensureMinimumOptions();
                  }),
                ),
                
                if (_tipoRespuesta == 'numero') ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _minController, 
                          keyboardType: TextInputType.number, 
                          style: GoogleFonts.poppins(fontSize: 14),
                          decoration: _inputDecor('Mínimo', Icons.arrow_downward)
                        )
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _maxController, 
                          keyboardType: TextInputType.number, 
                          style: GoogleFonts.poppins(fontSize: 14),
                          decoration: _inputDecor('Máximo', Icons.arrow_upward)
                        )
                      ),
                    ],
                  ),
                ],

                if (_tipoRespuesta == 'opciones') ...[
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Opciones:', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13)),
                      TextButton.icon(
                        onPressed: () => setState(() => _opcionesControllers.add(TextEditingController())), 
                        icon: const Icon(Icons.add, size: 16), 
                        label: Text('Añadir', style: GoogleFonts.poppins(fontSize: 12)),
                        style: TextButton.styleFrom(foregroundColor: colorVerde),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ..._opcionesControllers.asMap().entries.map((entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: entry.value, 
                            style: GoogleFonts.poppins(fontSize: 13),
                            decoration: _inputDecor('Opción ${entry.key + 1}', Icons.radio_button_checked),
                            validator: (v) => _tipoRespuesta == 'opciones' && (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                          )
                        ),
                        if (_opcionesControllers.length > 2)
                          IconButton(
                            onPressed: () => setState(() => _opcionesControllers.removeAt(entry.key)), 
                            icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent, size: 20)
                          ),
                      ],
                    ),
                  )),
                ],

                const SizedBox(height: 12),
                CheckboxListTile(
                  title: Text('Respuesta obligatoria', style: GoogleFonts.poppins(fontSize: 14)),
                  value: _obligatoria,
                  activeColor: colorAmarillo,
                  contentPadding: EdgeInsets.zero,
                  onChanged: (v) => setState(() => _obligatoria = v!),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context), 
          child: Text('Cancelar', style: GoogleFonts.poppins(color: Colors.grey[600]))
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: colorAmarillo, 
            foregroundColor: Colors.white, 
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          onPressed: () async {
            if (_formKey.currentState!.validate()) {
              String texto = _preguntaController.text.trim();
              
              // Formateo automático
              if (!texto.startsWith('¿')) texto = '¿$texto';
              if (!texto.endsWith('?')) texto = '$texto?';

              final p = Pregunta(
                id: widget.pregunta?.id ?? '',
                apiarioId: widget.apiaryId,
                texto: texto,
                tipoRespuesta: _tipoRespuesta,
                categoria: _categoryController.text.trim(),
                obligatoria: _obligatoria,
                orden: widget.pregunta?.orden ?? 0,
                min: _tipoRespuesta == 'numero' ? int.tryParse(_minController.text) : null,
                max: _tipoRespuesta == 'numero' ? int.tryParse(_maxController.text) : null,
                opciones: _tipoRespuesta == 'opciones' ? _opcionesControllers.map((c) => c.text.trim()).toList() : null,
              );

              if (widget.pregunta != null) {
                ref.read(questionsControllerProvider.notifier).updatePregunta(p);
              } else {
                ref.read(questionsControllerProvider.notifier).createPregunta(p);
              }
              Navigator.pop(context);
            }
          },
          child: Text(
            widget.pregunta != null ? 'Actualizar' : 'Guardar Pregunta', 
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold)
          ),
        ),
      ],
    );
  }
}
