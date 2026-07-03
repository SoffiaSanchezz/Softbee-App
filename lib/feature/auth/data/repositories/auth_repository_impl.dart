import 'package:Softbee/feature/auth/data/datasources/auth_local_datasource.dart';
import 'package:Softbee/feature/auth/data/datasources/auth_remote_datasource.dart';
import 'package:either_dart/either.dart';

import '../../../../core/error/failures.dart';
import '../../core/entities/user.dart';
import '../../core/errors/auth_error.dart';
import '../../core/repositories/auth_repository.dart';
// import '../datasources/auth_local_datasource.dart';
// import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final AuthLocalDataSource localDataSource;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<Either<Failure, Map<String, dynamic>>> registerUser(
    String username,
    String email,
    String phone,
    String password,
  ) async {
    try {
      final result = await remoteDataSource.registerUser(
        username,
        email,
        phone,
        password,
      );
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> login(String email, String password) async {
    try {
      final token = await remoteDataSource.login(email, password);
      await localDataSource.saveToken(token);
      return Right(token);
    } on AuthException catch (e) {
      // Propagar el mensaje específico ya interpretado por código de error.
      return Left(AuthFailure(e.message));
    } catch (e) {
      return const Left(
        AuthFailure('No se pudo iniciar sesión. Intenta nuevamente.'),
      );
    }
  }

  @override
  Future<Either<Failure, User?>> checkAuthStatus() async {
    try {
      final token = await localDataSource.getToken();
      if (token == null) {
        return const Right(null);
      }
      final user = await remoteDataSource.getUserFromToken(token);
      return Right(user);
    } catch (e) {
      await localDataSource.deleteToken();
      await localDataSource
          .deleteUser(); // También eliminar el usuario al expirar la sesión
      return const Left(AuthFailure('Session expired. Please log in again.'));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      await remoteDataSource.logout();
      await localDataSource.deleteToken();
      await localDataSource
          .deleteUser(); // También eliminar el usuario al cerrar sesión
      return const Right(null);
    } catch (e) {
      return const Left(ServerFailure('Error during logout'));
    }
  }

  @override
  Future<Either<Failure, User>> getUserFromToken(String token) async {
    try {
      final user = await remoteDataSource.getUserFromToken(token);
      return Right(user);
    } catch (e) {
      return const Left(ServerFailure('Error al obtener usuario del token'));
    }
  }

  @override
  Future<Either<Failure, void>> createApiary(
    String userId,
    String apiaryName,
    String location,
    int beehivesCount,
    String token,
  ) async {
    try {
      await remoteDataSource.createApiary(
        userId,
        apiaryName,
        location,
        beehivesCount,
        token,
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
