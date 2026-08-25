import 'package:Softbee/core/network/dio_client.dart';
import 'package:Softbee/feature/auth/presentation/providers/auth_providers.dart';
import 'package:Softbee/feature/apiaries/presentation/providers/apiary_providers.dart';
import 'package:Softbee/feature/beehive/data/datasources/beehive_local_datasource.dart';
import 'package:Softbee/feature/beehive/data/datasources/beehive_remote_datasource.dart';
import 'package:Softbee/feature/beehive/data/repositories/beehive_repository_impl.dart';
import 'package:Softbee/feature/beehive/domain/repositories/beehive_repository.dart';
import 'package:Softbee/feature/beehive/domain/usecases/get_beehives_by_apiary_usecase.dart';
import 'package:Softbee/feature/beehive/domain/usecases/create_beehive_usecase.dart';
import 'package:Softbee/feature/beehive/domain/usecases/update_beehive_usecase.dart';
import 'package:Softbee/feature/beehive/domain/usecases/delete_beehive_usecase.dart';
import 'package:Softbee/feature/beehive/presentation/controllers/beehive_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final beehiveRemoteDataSourceProvider = Provider<BeehiveRemoteDataSource>((
  ref,
) {
  final dio = ref.read(dioClientProvider);
  final localDataSource = ref.read(authLocalDataSourceProvider);
  return BeehiveRemoteDataSourceImpl(dio, localDataSource);
});

final beehiveLocalDataSourceProvider = Provider<BeehiveLocalDataSource>((ref) {
  return BeehiveLocalDataSourceImpl();
});

final beehiveRepositoryProvider = Provider<BeehiveRepository>((ref) {
  return BeehiveRepositoryImpl(
    remoteDataSource: ref.read(beehiveRemoteDataSourceProvider),
    localDataSource: ref.read(authLocalDataSourceProvider),
    beehiveLocalDataSource: ref.read(beehiveLocalDataSourceProvider),
    networkInfo: ref.read(networkInfoProvider),
  );
});

final getBeehivesByApiaryUseCaseProvider = Provider<GetBeehivesByApiaryUseCase>(
  (ref) {
    return GetBeehivesByApiaryUseCase(ref.read(beehiveRepositoryProvider));
  },
);

final createBeehiveUseCaseProvider = Provider<CreateBeehiveUseCase>((ref) {
  return CreateBeehiveUseCase(ref.read(beehiveRepositoryProvider));
});

final updateBeehiveUseCaseProvider = Provider<UpdateBeehiveUseCase>((ref) {
  return UpdateBeehiveUseCase(ref.read(beehiveRepositoryProvider));
});

final deleteBeehiveUseCaseProvider = Provider<DeleteBeehiveUseCase>((ref) {
  return DeleteBeehiveUseCase(ref.read(beehiveRepositoryProvider));
});

final beehiveControllerProvider =
    StateNotifierProvider<BeehiveController, BeehiveState>((ref) {
      final getBeehivesByApiaryUseCase = ref.read(
        getBeehivesByApiaryUseCaseProvider,
      );
      final createBeehiveUseCase = ref.read(createBeehiveUseCaseProvider);
      final updateBeehiveUseCase = ref.read(updateBeehiveUseCaseProvider);
      final deleteBeehiveUseCase = ref.read(deleteBeehiveUseCaseProvider);

      return BeehiveController(
        getBeehivesByApiaryUseCase: getBeehivesByApiaryUseCase,
        createBeehiveUseCase: createBeehiveUseCase,
        updateBeehiveUseCase: updateBeehiveUseCase,
        deleteBeehiveUseCase: deleteBeehiveUseCase,
      );
    });
