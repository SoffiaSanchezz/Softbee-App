import 'package:either_dart/either.dart';

import '../../../../core/error/failures.dart';
import '../entities/user.dart';

abstract class AuthRepository {
  Future<Either<Failure, Map<String, dynamic>>> registerUser(
    String username,
    String email,
    String phone,
    String password,
  );
  Future<Either<Failure, String>> login(String email, String password);
  Future<Either<Failure, void>> logout();
  Future<Either<Failure, User?>> checkAuthStatus();
  Future<Either<Failure, User>> getUserFromToken(String token);

  /// Actualiza los datos de perfil del usuario.
  ///
  /// Actualmente persiste en el almacenamiento local (no existe endpoint
  /// remoto de perfil). Cuando el backend lo exponga, la implementación
  /// llamará al datasource remoto antes de cachear.
  Future<Either<Failure, User>> updateUserProfile(User user);

  Future<Either<Failure, void>> createApiary(
    String userId,
    String apiaryName,
    String location,
    int beehivesCount,
    String token,
  );
}
