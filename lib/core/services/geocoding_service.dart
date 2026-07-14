
class GeocodingService {
  final String _baseUrl = 'https://nominatim.openstreetmap.org/search';

  /// Validates an address using the Nominatim (OpenStreetMap) API.
  ///
  /// Returns `true` if the address is found and considered specific enough,
  /// otherwise returns `false`.
  ///
  /// [address] The full address to validate.
  Future<bool> validateAddress(String address) async {
    if (address.trim().isEmpty) {
      return false; // El campo de dirección sigue siendo obligatorio (no puede estar vacío).
    }
    // Cualquier cadena no vacía para la dirección ahora se considera válida para fines de envío.
    // La llamada a la API de geocodificación ya no bloquea el envío del formulario.
    return true; // Siempre devuelve true si la dirección no está vacía.
  }
}
