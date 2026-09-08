import 'package:either_dart/either.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

/// Caso de uso para actualizar el perfil del usuario.
///
/// Recibe el [User] con los datos ya combinados y delega la persistencia al
/// repositorio (actualmente local).
class UpdateProfileUseCase implements UseCase<User, User> {
  final AuthRepository repository;

  UpdateProfileUseCase(this.repository);

  @override
  Future<Either<Failure, User>> call(User params) {
    return repository.updateUserProfile(params);
  }
}
