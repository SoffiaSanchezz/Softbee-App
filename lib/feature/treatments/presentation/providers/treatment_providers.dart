import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:Softbee/core/network/dio_client.dart';
import '../../data/datasources/treatment_remote_datasource.dart';
import '../../data/repositories/treatment_repository_impl.dart';
import '../../domain/repositories/treatment_repository.dart';
import '../../domain/usecases/get_treatments_by_hive.dart';
import '../../domain/usecases/create_treatment.dart';
import '../../domain/usecases/create_followup.dart';
import '../controllers/treatments_controller.dart';

final treatmentRemoteDataSourceProvider = Provider<TreatmentRemoteDataSource>((ref) {
  final dio = ref.read(dioClientProvider);
  return TreatmentRemoteDataSourceImpl(dio);
});

final treatmentRepositoryProvider = Provider<TreatmentRepository>((ref) {
  return TreatmentRepositoryImpl(
    remoteDataSource: ref.read(treatmentRemoteDataSourceProvider),
  );
});

final getTreatmentsByHiveUseCaseProvider = Provider<GetTreatmentsByHive>((ref) {
  return GetTreatmentsByHive(ref.read(treatmentRepositoryProvider));
});

final createTreatmentUseCaseProvider = Provider<CreateTreatment>((ref) {
  return CreateTreatment(ref.read(treatmentRepositoryProvider));
});

final createFollowupUseCaseProvider = Provider<CreateFollowup>((ref) {
  return CreateFollowup(ref.read(treatmentRepositoryProvider));
});

final treatmentsControllerProvider =
    StateNotifierProvider<TreatmentsController, TreatmentsState>((ref) {
  return TreatmentsController(
    getTreatmentsByHive: ref.read(getTreatmentsByHiveUseCaseProvider),
    createTreatmentUseCase: ref.read(createTreatmentUseCaseProvider),
    createFollowupUseCase: ref.read(createFollowupUseCaseProvider),
  );
});
