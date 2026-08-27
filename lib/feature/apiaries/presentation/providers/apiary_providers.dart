import 'package:Softbee/core/network/dio_client.dart';
import 'package:Softbee/core/network/network_info.dart';
import 'package:Softbee/feature/apiaries/data/datasources/apiary_local_datasource.dart';
import 'package:Softbee/feature/apiaries/data/datasources/apiary_remote_datasource.dart';
import 'package:Softbee/feature/apiaries/data/repositories/apiary_repository_impl.dart';
import 'package:Softbee/feature/apiaries/data/services/connectivity_listener.dart';
import 'package:Softbee/feature/apiaries/data/services/sync_service.dart';
import 'package:Softbee/feature/apiaries/domain/repositories/apiary_repository.dart';
import 'package:Softbee/feature/apiaries/domain/usecases/get_apiaries.dart';
import 'package:Softbee/feature/apiaries/domain/usecases/create_apiary_usecase.dart';
import 'package:Softbee/feature/apiaries/domain/usecases/update_apiary_usecase.dart';
import 'package:Softbee/feature/apiaries/domain/usecases/delete_apiary_usecase.dart';
import 'package:Softbee/feature/apiaries/presentation/controllers/apiaries_controller.dart';
import 'package:Softbee/feature/auth/presentation/providers/auth_providers.dart';
import 'package:Softbee/feature/beehive/presentation/providers/beehive_providers.dart';
import 'package:Softbee/feature/inventory/presentation/providers/inventory_providers.dart';
import 'package:Softbee/feature/maya/presentation/providers/maya_providers.dart';
import 'package:Softbee/core/services/offline_storage_provider.dart';
import 'package:Softbee/core/sync/entity_sync_handler.dart';
import 'package:Softbee/core/sync/sync_dispatcher.dart';
import 'package:Softbee/core/sync/sync_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final networkInfoProvider = Provider<NetworkInfo>((ref) {
  return NetworkInfoImpl();
});

final apiaryLocalDataSourceProvider = Provider<ApiaryLocalDataSource>((ref) {
  return ApiaryLocalDataSourceImpl();
});

final apiaryRemoteDataSourceProvider = Provider<ApiaryRemoteDataSource>((ref) {
  final dio = ref.read(dioClientProvider);
  final localDataSource = ref.read(authLocalDataSourceProvider);
  return ApiaryRemoteDataSourceImpl(dio, localDataSource);
});

final apiaryRepositoryProvider = Provider<ApiaryRepository>((ref) {
  return ApiaryRepositoryImpl(
    remoteDataSource: ref.read(apiaryRemoteDataSourceProvider),
    authLocalDataSource: ref.read(authLocalDataSourceProvider),
    localDataSource: ref.read(apiaryLocalDataSourceProvider),
    networkInfo: ref.read(networkInfoProvider),
  );
});

// ===================== SYNC SERVICE =====================

/// Lista central de handlers de sincronización de la cola genérica.
/// Aquí se registran las features conforme se van habilitando para offline.
final syncHandlersProvider = Provider<List<EntitySyncHandler>>((ref) {
  return [
    ref.read(inventorySyncHandlerProvider),
  ];
});

final syncDispatcherProvider = Provider<SyncDispatcher>((ref) {
  return SyncDispatcher(
    queue: ref.read(syncQueueProvider),
    handlers: ref.read(syncHandlersProvider),
  );
});

final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService(
    remoteDataSource: ref.read(apiaryRemoteDataSourceProvider),
    localDataSource: ref.read(apiaryLocalDataSourceProvider),
    authLocalDataSource: ref.read(authLocalDataSourceProvider),
    offlineStorage: ref.read(offlineStorageServiceProvider),
    mayaRepository: ref.read(mayaRepositoryProvider),
    beehiveRemoteDataSource: ref.read(beehiveRemoteDataSourceProvider),
    beehiveLocalDataSource: ref.read(beehiveLocalDataSourceProvider),
    syncDispatcher: ref.read(syncDispatcherProvider),
  );
});

// ===================== CONNECTIVITY LISTENER =====================

final connectivityListenerProvider = Provider<ConnectivityListener>((ref) {
  final syncService = ref.read(syncServiceProvider);
  final listener = ConnectivityListener(syncService: syncService);
  listener.startListening();

  ref.onDispose(() {
    listener.stopListening();
  });

  return listener;
});

// ===================== USE CASES =====================

final getApiariesUseCaseProvider = Provider<GetApiariesUseCase>((ref) {
  return GetApiariesUseCase(ref.read(apiaryRepositoryProvider));
});

final createApiaryUseCaseProvider = Provider<CreateApiaryUseCase>((ref) {
  return CreateApiaryUseCase(ref.read(apiaryRepositoryProvider));
});

final updateApiaryUseCaseProvider = Provider<UpdateApiaryUseCase>((ref) {
  return UpdateApiaryUseCase(ref.read(apiaryRepositoryProvider));
});

final deleteApiaryUseCaseProvider = Provider<DeleteApiaryUseCase>((ref) {
  return DeleteApiaryUseCase(ref.read(apiaryRepositoryProvider));
});

// ===================== CONTROLLER =====================

final apiariesControllerProvider =
    StateNotifierProvider<ApiariesController, ApiariesState>((ref) {
      final getApiariesUseCase = ref.read(getApiariesUseCaseProvider);
      final createApiaryUseCase = ref.read(createApiaryUseCaseProvider);
      final updateApiaryUseCase = ref.read(updateApiaryUseCaseProvider);
      final deleteApiaryUseCase = ref.read(deleteApiaryUseCaseProvider);
      final authController = ref.watch(authControllerProvider.notifier);

      // Asegurar que el ConnectivityListener esté activo
      ref.read(connectivityListenerProvider);

      return ApiariesController(
        getApiariesUseCase: getApiariesUseCase,
        createApiaryUseCase: createApiaryUseCase,
        updateApiaryUseCase: updateApiaryUseCase,
        deleteApiaryUseCase: deleteApiaryUseCase,
        authController: authController,
      );
    });
