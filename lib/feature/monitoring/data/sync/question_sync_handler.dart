import 'package:Softbee/core/sync/entity_sync_handler.dart';
import 'package:Softbee/core/sync/pending_sync_operation.dart';
import 'package:Softbee/feature/monitoring/data/datasources/question_local_datasource.dart';
import 'package:Softbee/feature/monitoring/data/datasources/question_remote_datasource.dart';
import 'package:Softbee/feature/monitoring/domain/entities/question_model.dart';

/// Nombre de entidad usado en la cola de sincronización para preguntas.
const String kQuestionEntity = 'question';

/// Sube al servidor las operaciones de preguntas del apiario hechas offline.
class QuestionSyncHandler implements EntitySyncHandler {
  final QuestionRemoteDataSource remoteDataSource;
  final QuestionLocalDataSource localDataSource;

  QuestionSyncHandler({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  String get entity => kQuestionEntity;

  @override
  Future<SyncHandlerResult> process(
    PendingSyncOperation op,
    String token,
  ) async {
    final data = op.data;
    final apiaryId = op.apiaryId ?? data?['apiary_id']?.toString() ?? '';

    switch (op.type) {
      case SyncOperationType.create:
        // Reconstruir sin el id temporal para que el backend genere uno real.
        final pregunta = Pregunta.fromJson(data!).copyWith(id: '');
        final created = await remoteDataSource.createPregunta(pregunta, token);

        // Remapear el id temporal por el real en el cache.
        if (op.isTemporary && created.id.isNotEmpty && apiaryId.isNotEmpty) {
          await localDataSource.replacePreguntaId(apiaryId, op.entityId, created);
        }
        return SyncHandlerResult.created(created.id);

      case SyncOperationType.update:
        if (op.isTemporary) return const SyncHandlerResult.ok();
        final pregunta = Pregunta.fromJson(data!);
        await remoteDataSource.updatePregunta(pregunta, token);
        return const SyncHandlerResult.ok();

      case SyncOperationType.delete:
        if (op.isTemporary) return const SyncHandlerResult.ok();
        await remoteDataSource.deletePregunta(op.entityId, token);
        return const SyncHandlerResult.ok();
    }
  }
}
