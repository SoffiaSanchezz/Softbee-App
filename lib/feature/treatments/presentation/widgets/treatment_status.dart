import 'package:flutter/material.dart';

/// Helper centralizado para el manejo de estados de un tratamiento.
///
/// El backend guarda el estado como texto libre (por defecto `active`). Aquí se
/// normaliza a un conjunto conocido para poder mostrar etiquetas, colores e
/// iconos coherentes en toda la sección de Tratamientos.
class TreatmentStatus {
  const TreatmentStatus._();

  /// Estados soportados (valor que se envía / guarda en el backend).
  static const String active = 'Activo';
  static const String completed = 'Completado';
  static const String suspended = 'Suspendido';
  static const String scheduled = 'Programado';

  /// Opciones seleccionables en formularios y filtros.
  static const List<String> options = [active, scheduled, completed, suspended];

  /// Normaliza cualquier variante recibida del backend a una etiqueta legible.
  static String label(String? raw) {
    final value = (raw ?? '').trim().toLowerCase();
    if (value.isEmpty) return active;
    if (value.contains('complet') || value.contains('finaliz')) return completed;
    if (value.contains('suspend') || value.contains('cancel')) return suspended;
    if (value.contains('program') || value.contains('schedul') || value.contains('pending')) {
      return scheduled;
    }
    if (value.contains('activ')) return active;
    // Si el backend envía algo desconocido, lo mostramos capitalizado.
    return raw!.substring(0, 1).toUpperCase() + raw.substring(1);
  }

  static Color color(String? raw) {
    switch (label(raw)) {
      case completed:
        return const Color(0xFF16A34A); // green 600
      case suspended:
        return const Color(0xFFDC2626); // red 600
      case scheduled:
        return const Color(0xFF2563EB); // blue 600
      case active:
      default:
        return const Color(0xFFF59E0B); // amber 500
    }
  }

  static IconData icon(String? raw) {
    switch (label(raw)) {
      case completed:
        return Icons.check_circle_rounded;
      case suspended:
        return Icons.cancel_rounded;
      case scheduled:
        return Icons.schedule_rounded;
      case active:
      default:
        return Icons.pending_actions_rounded;
    }
  }
}
