import 'package:intl/intl.dart';

/// Utilidades para parsear fechas provenientes del backend de forma tolerante.
///
/// El backend puede enviar fechas en dos formatos:
///  - ISO 8601: `2026-03-18T04:47:59` (formato preferido).
///  - RFC 1123 / HTTP date: `Wed, 18 Mar 2026 04:47:59 GMT` (serialización por
///    defecto de algunos endpoints).
///
/// [parseBackendDate] intenta ambos formatos y nunca lanza excepción: si no
/// puede interpretar la cadena devuelve `null`, evitando el
/// `FormatException: Invalid date format`.
class DateParser {
  DateParser._();

  // Formato RFC 1123 usado por HTTP (siempre en inglés / locale 'en_US').
  static final DateFormat _rfc1123 =
      DateFormat("EEE, dd MMM yyyy HH:mm:ss 'GMT'", 'en_US');

  /// Intenta parsear una fecha desde [value]. Devuelve `null` si no es válida.
  static DateTime? parseBackendDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;

    final String raw = value.toString().trim();
    if (raw.isEmpty) return null;

    // 1. Intentar ISO 8601 (formato preferido).
    final DateTime? iso = DateTime.tryParse(raw);
    if (iso != null) return iso;

    // 2. Intentar RFC 1123 (p. ej. "Wed, 18 Mar 2026 04:47:59 GMT").
    try {
      // GMT == UTC; se interpreta como UTC.
      return _rfc1123.parseUtc(raw);
    } catch (_) {
      return null;
    }
  }

  /// Igual que [parseBackendDate] pero devuelve [fallback] (por defecto
  /// `DateTime.now()`) cuando la fecha no puede parsearse.
  static DateTime parseBackendDateOr(dynamic value, {DateTime? fallback}) {
    return parseBackendDate(value) ?? fallback ?? DateTime.now();
  }
}
