import 'package:dio/dio.dart';
import '../../core/entities/user.dart';
import '../../core/errors/auth_error.dart';
import 'auth_local_datasource.dart'; // Importar AuthLocalDataSource

abstract class AuthRemoteDataSource {
  Future<Map<String, dynamic>> registerUser(
    String username,
    String email,
    String phone,
    String password,
  );
  Future<String> login(String email, String password);
  Future<void> logout();
  Future<User> getUserFromToken(String token);
  Future<void> createApiary(
    String userId,
    String apiaryName,
    String location,
    int beehivesCount,
    String token,
  );
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final Dio httpClient;
  final AuthLocalDataSource localDataSource; // Inyectar AuthLocalDataSource

  AuthRemoteDataSourceImpl(
    this.httpClient,
    this.localDataSource,
  ); // Constructor actualizado

  @override
  Future<Map<String, dynamic>> registerUser(
    String username,
    String email,
    String phone,
    String password,
  ) async {
    try {
      final response = await httpClient.post(
        '/api/v1/auth/register',
        data: {
          'username': username,
          'email': email,
          'phone': phone,
          'password': password,
          'confirm_password': password,
        },
      );

      if (response.statusCode == 201) {
        final token = response.data['access_token'];

        // Extraer los campos directamente de response.data

        final user = User(
          id: response.data['user_id'] ?? '', // Backend envía 'user_id'

          email: response.data['email'] ?? '',

          username: response.data['username'] ?? '',

          isVerified:
              response.data['is_verified'] ??
              false, // Asegúrate de que estos campos existan en la respuesta del backend o proporciona un valor predeterminado

          isActive:
              response.data['is_active'] ??
              true, // Asegúrate de que estos campos existan en la respuesta del backend o proporciona un valor predeterminado
        );

        if (token != null) {
          await localDataSource.saveUser(user);

          await localDataSource.saveToken(token);

          return {'access_token': token, 'user': user};
        } else {
          throw Exception('Token de acceso no recibido del servidor');
        }
      } else {
        throw Exception(response.data['message'] ?? 'Error de registro');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(
          e.response!.data['error'] ??
              e.response!.data['message'] ??
              'Error de red: ${e.response!.statusCode}',
        );
      } else {
        throw Exception('Error de conexión: ${e.message}');
      }
    } catch (e) {
      throw Exception('Error inesperado: $e');
    }
  }

  @override
  Future<String> login(String email, String password) async {
    try {
      final response = await httpClient.post(
        '/api/v1/auth/login',
        data: {'email': email, 'password': password},
      );

      if (response.statusCode == 200) {
        final token = response.data['access_token'];

        if (token != null && response.data['user_id'] != null) {
          // Corregido: Construir el usuario directamente desde la respuesta plana.
          final user = User(
            id: response.data['user_id'],
            email: response.data['email'],
            username: response.data['username'],
            isVerified: response.data['is_verified'] ?? false,
            isActive: response.data['is_active'] ?? true,
          );
          await localDataSource.saveUser(user); // Guardar el objeto User
          await localDataSource.saveToken(token); // Guardar el token
          return token;
        } else {
          throw const AuthException(
            AuthErrorCode.serverError,
            'Token o datos de usuario no recibidos del servidor.',
          );
        }
      } else {
        throw AuthException(
          AuthErrorCode.serverError,
          authErrorMessage(
            response.data is Map ? response.data['error_code'] : null,
            fallback: response.data is Map
                ? (response.data['message'] ?? response.data['error'])
                : null,
          ),
        );
      }
    } on DioException catch (e) {
      // El backend responde con { error_code, message } y un status específico.
      if (e.response != null) {
        final data = e.response!.data;
        final String? code =
            data is Map && data['error_code'] != null
            ? data['error_code'].toString()
            : null;
        final String? serverMsg = data is Map
            ? (data['message'] ?? data['error'])?.toString()
            : null;
        throw AuthException(
          code ?? AuthErrorCode.serverError,
          authErrorMessage(code, fallback: serverMsg),
        );
      } else {
        // Sin respuesta: problema de red/conexión (backend caído, CORS, etc.)
        throw const AuthException(
          AuthErrorCode.networkError,
          'No se pudo conectar con el servidor. Verifica tu conexión.',
        );
      }
    } on AuthException {
      rethrow;
    } catch (e) {
      throw AuthException(AuthErrorCode.serverError, 'Error inesperado: $e');
    }
  }

  @override
  Future<void> logout() async {
    await localDataSource.deleteToken();
    await localDataSource.deleteUser();
  }

  @override
  Future<User> getUserFromToken(String token) async {
    final user = await localDataSource.getUser();
    if (user != null) {
      return user;
    } else {
      throw Exception('No se encontró información de usuario local.');
    }
  }

  @override
  Future<void> createApiary(
    String userId,
    String apiaryName,
    String location,
    int beehivesCount,
    String token,
  ) async {
    try {
      await httpClient.post(
        '/api/v1/apiaries',
        data: {
          'user_id': userId,
          'name': apiaryName,
          'location': location.isEmpty ? null : location, // Send null if empty
          'beehives_count': beehivesCount,
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(
          e.response!.data['message'] ??
              'Error al crear apiario: ${e.response!.statusCode}',
        );
      } else {
        throw Exception('Error de conexión al crear apiario: ${e.message}');
      }
    } catch (e) {
      throw Exception('Error inesperado al crear apiario: $e');
    }
  }

  // Helper para generar username. En el futuro, esto podría ser más sofisticado.
  static String generateUsername(String email) {
    return email.split('@')[0].replaceAll('.', '_').replaceAll('-', '_');
  }
}
