import 'package:equatable/equatable.dart';

class Pregunta extends Equatable {
  final String id;
  final String apiarioId;
  final String texto;
  final String tipoRespuesta;
  final String? categoria;
  final bool obligatoria;
  final List<String>? opciones;
  final int? min;
  final int? max;
  final int orden;
  final bool activa;

  const Pregunta({
    required this.id,
    required this.apiarioId,
    required this.texto,
    required this.tipoRespuesta,
    this.categoria,
    required this.obligatoria,
    this.opciones,
    this.min,
    this.max,
    required this.orden,
    this.activa = true,
  });

  factory Pregunta.fromJson(Map<String, dynamic> json) {
    // Manejo robusto de opciones (puede venir como String o List)
    List<String>? parsedOptions;
    dynamic rawOptions = json['options'] ?? json['opciones'];
    
    if (rawOptions is String) {
      parsedOptions = rawOptions.split(',').map((e) => e.trim()).toList();
    } else if (rawOptions is List) {
      parsedOptions = List<String>.from(rawOptions);
    }

    // Filtrar valores no deseados como '{}' o vacíos
    parsedOptions = parsedOptions?.where((opt) => opt.isNotEmpty && opt != '{}').toList();

    return Pregunta(
      id: json['id']?.toString() ?? '',
      apiarioId: json['apiary_id']?.toString() ?? '',
      texto: json['question_text'] ?? json['question'] ?? json['pregunta'] ?? '',
      tipoRespuesta:
          json['question_type'] ?? json['type'] ?? json['tipo'] ?? 'texto',
      categoria: json['category'] ?? json['categoria'],
      obligatoria: json['is_required'] ?? json['obligatoria'] ?? false,
      opciones: parsedOptions,
      min: (json['min_value'] as num?)?.toInt() ?? (json['min'] as num?)?.toInt(),
      max: (json['max_value'] as num?)?.toInt() ?? (json['max'] as num?)?.toInt(),
      orden: (json['display_order'] as num?)?.toInt() ??
          (json['orden'] as num?)?.toInt() ??
          0,
      activa: json['is_active'] ?? json['activa'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'apiary_id': apiarioId,
      'question_text': texto,
      'question_type': tipoRespuesta,
      'is_required': obligatoria,
      'display_order': orden,
      'is_active': activa,
    };

    if (id.isNotEmpty) {
      data['id'] = id;
    }

    if (categoria != null && categoria!.isNotEmpty) {
      data['category'] = categoria;
    }

    if (opciones != null && opciones!.isNotEmpty) {
      // Convertir lista a String separado por comas para el backend
      data['options'] = opciones!.where((opt) => opt.isNotEmpty && opt != '{}').join(',');
    } else {
      data['options'] = null;
    }

    if (min != null) data['min_value'] = min;
    if (max != null) data['max_value'] = max;

    return data;
  }

  Pregunta copyWith({
    String? id,
    String? apiarioId,
    String? texto,
    String? tipoRespuesta,
    String? categoria,
    bool? obligatoria,
    List<String>? opciones,
    int? min,
    int? max,
    int? orden,
    bool? activa,
  }) {
    return Pregunta(
      id: id ?? this.id,
      apiarioId: apiarioId ?? this.apiarioId,
      texto: texto ?? this.texto,
      tipoRespuesta: tipoRespuesta ?? this.tipoRespuesta,
      categoria: categoria ?? this.categoria,
      obligatoria: obligatoria ?? this.obligatoria,
      opciones: opciones ?? this.opciones,
      min: min ?? this.min,
      max: max ?? this.max,
      orden: orden ?? this.orden,
      activa: activa ?? this.activa,
    );
  }

  @override
  List<Object?> get props => [
    id,
    apiarioId,
    texto,
    tipoRespuesta,
    categoria,
    obligatoria,
    opciones,
    min,
    max,
    orden,
    activa,
  ];
}
