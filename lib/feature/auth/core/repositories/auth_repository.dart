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
  Future<Either<Failure, void>> createApiary(
    String userId,
    String apiaryName,
    String location,
    int beehivesCount,
    String token,
  );
}
