import 'dart:convert';
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

  /// Actualiza el perfil del usuario en el backend (`PUT /api/v1/users/<id>`).
  ///
  /// Devuelve el [User] tal como quedó persistido en el servidor.
  Future<User> updateProfile(User user);

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
        // Asegurar que data sea un Map (puede llegar como String desde tunnels)
        final Map<String, dynamic> data = response.data is String
            ? json.decode(response.data) as Map<String, dynamic>
            : response.data as Map<String, dynamic>;

        final token = data['access_token'];
        final refreshToken = data['refresh_token'];

        final user = User(
          id: (data['user_id'] ?? '').toString(),
          email: (data['email'] ?? '').toString(),
          username: (data['username'] ?? '').toString(),
          isVerified: data['is_verified'] ?? false,
          isActive: data['is_active'] ?? true,
        );

        if (token != null) {
          await localDataSource.saveUser(user);
          await localDataSource.saveToken(token.toString());
          if (refreshToken != null) {
            await localDataSource.saveRefreshToken(refreshToken.toString());
          }

          return {'access_token': token.toString(), 'user': user};
        } else {
          throw Exception('Token de acceso no recibido del servidor');
        }
      } else {
        final Map<String, dynamic> data = response.data is String
            ? json.decode(response.data) as Map<String, dynamic>
            : response.data as Map<String, dynamic>;
        throw Exception(data['message'] ?? 'Error de registro');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        final errData = e.response!.data is String
            ? json.decode(e.response!.data) as Map<String, dynamic>
            : e.response!.data as Map<String, dynamic>;
        throw Exception(
          errData['error'] ??
              errData['message'] ??
              'Error de red: ${e.response!.statusCode}',
        );
      } else {
        throw Exception('Error de conexión: ${e.message}');
      }
    } catch (e) {
      if (e is Exception) rethrow;
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
        // Asegurar que data sea un Map
        final Map<String, dynamic> data = response.data is String
            ? json.decode(response.data) as Map<String, dynamic>
            : response.data as Map<String, dynamic>;

        final token = data['access_token'];
        final refreshToken = data['refresh_token'];

        if (token != null && data['user_id'] != null) {
          final user = User(
            id: (data['user_id']).toString(),
            email: (data['email'] ?? '').toString(),
            username: (data['username'] ?? '').toString(),
            isVerified: data['is_verified'] ?? false,
            isActive: data['is_active'] ?? true,
          );
          await localDataSource.saveUser(user);
          await localDataSource.saveToken(token.toString());
          if (refreshToken != null) {
            await localDataSource.saveRefreshToken(refreshToken.toString());
          }
          return token.toString();
        } else {
          throw const AuthException(
            AuthErrorCode.serverError,
            'Token o datos de usuario no recibidos del servidor.',
          );
        }
      } else {
        final Map<String, dynamic> data = response.data is String
            ? json.decode(response.data) as Map<String, dynamic>
            : response.data as Map<String, dynamic>;
        throw AuthException(
          AuthErrorCode.serverError,
          authErrorMessage(
            data['error_code']?.toString(),
            fallback: (data['message'] ?? data['error'])?.toString(),
          ),
        );
      }
    } on DioException catch (e) {
      if (e.response != null) {
        final rawData = e.response!.data;
        final Map<String, dynamic> data = rawData is String
            ? json.decode(rawData) as Map<String, dynamic>
            : rawData as Map<String, dynamic>;
        final String? code = data['error_code']?.toString();
        final String? serverMsg =
            (data['message'] ?? data['error'])?.toString();
        throw AuthException(
          code ?? AuthErrorCode.serverError,
          authErrorMessage(code, fallback: serverMsg),
        );
      } else {
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
    await localDataSource.clearSession();
  }

  @override
  Future<User> getUserFromToken(String token) async {
    // El usuario cacheado localmente proviene del login/registro y solo trae
    // los campos básicos (id, email, username, is_verified, is_active). Los
    // datos de perfil (full_name, phone, location, photo_url) viven en el
    // backend, así que los traemos frescos con GET /api/v1/users/<id>.
    final cached = await localDataSource.getUser();
    if (cached == null) {
      throw Exception('No se encontró información de usuario local.');
    }

    if (cached.id.isEmpty) {
      // Sin id no podemos consultar el backend; devolvemos lo que haya.
      return cached;
    }

    try {
      final response = await httpClient.get('/api/v1/users/${cached.id}');
      final Map<String, dynamic> data = response.data is String
          ? json.decode(response.data) as Map<String, dynamic>
          : response.data as Map<String, dynamic>;

      final remote = User.fromJson(data);
      // El UserDTO del backend no incluye is_verified / is_active, así que
      // conservamos esos valores del usuario cacheado (vienen del login).
      final merged = remote.copyWith(
        isVerified: cached.isVerified,
        isActive: cached.isActive,
      );
      // Refrescamos el cache para que la sesión mantenga los datos completos.
      await localDataSource.saveUser(merged);
      return merged;
    } catch (_) {
      // Sin conexión o error del backend: usamos el cache para no romper la
      // sesión. Los datos de perfil pueden verse desactualizados hasta el
      // próximo arranque con red.
      return cached;
    }
  }

  @override
  Future<User> updateProfile(User user) async {
    try {
      // El backend usa cadena vacía para "limpiar" un campo opcional y omite
      // (no envía) los que no cambian. Aquí enviamos los campos editables del
      // perfil; los null se convierten en "" para permitir borrarlos.
      final response = await httpClient.put(
        '/api/v1/users/${user.id}',
        data: {
          'username': user.username,
          'full_name': user.fullName ?? '',
          'phone': user.phone ?? '',
          'location': user.location ?? '',
          'photo_url': user.photoUrl ?? '',
        },
      );

      final Map<String, dynamic> data = response.data is String
          ? json.decode(response.data) as Map<String, dynamic>
          : response.data as Map<String, dynamic>;

      // El backend devuelve el usuario actualizado, pero no incluye
      // is_verified / is_active en el UserDTO: conservamos los del usuario
      // actual para no perder ese estado en la UI.
      final updated = User.fromJson(data);
      return updated.copyWith(
        isVerified: user.isVerified,
        isActive: user.isActive,
      );
    } on DioException catch (e) {
      if (e.response != null) {
        final rawData = e.response!.data;
        final Map<String, dynamic> data = rawData is String
            ? json.decode(rawData) as Map<String, dynamic>
            : rawData as Map<String, dynamic>;
        throw Exception(
          data['error'] ??
              data['message'] ??
              'Error al actualizar el perfil: ${e.response!.statusCode}',
        );
      } else {
        throw Exception('Error de conexión al actualizar el perfil: ${e.message}');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Error inesperado al actualizar el perfil: $e');
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
