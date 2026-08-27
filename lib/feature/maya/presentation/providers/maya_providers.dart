import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/services/offline_storage_provider.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/datasources/maya_remote_datasource.dart';
import '../../data/repositories/maya_repository_impl.dart';
import '../../domain/repositories/maya_repository.dart';
import '../../domain/usecases/send_message_usecase.dart';
import 'maya_controller.dart';

final mayaRemoteDataSourceProvider = Provider<MayaRemoteDataSource>((ref) {
  return MayaRemoteDataSourceImpl(ref.read(dioClientProvider));
});

final mayaRepositoryProvider = Provider<MayaRepository>((ref) {
  return MayaRepositoryImpl(
    remoteDataSource: ref.read(mayaRemoteDataSourceProvider),
    localDataSource: ref.read(authLocalDataSourceProvider),
    offlineStorage: ref.read(offlineStorageServiceProvider),
  );
});

final sendMessageUseCaseProvider = Provider<SendMessageUseCase>((ref) {
  return SendMessageUseCase(ref.read(mayaRepositoryProvider));
});

final mayaControllerProvider =
    StateNotifierProvider.autoDispose<MayaController, MayaState>((ref) {
  return MayaController(ref.read(sendMessageUseCaseProvider));
});
