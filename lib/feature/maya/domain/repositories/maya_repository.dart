import 'package:either_dart/either.dart';
import '../../../../core/error/failures.dart';
import '../entities/chat_message.dart';

abstract class MayaRepository {
  Future<Either<Failure, ChatMessage>> sendMessage({
    required String prompt,
    String? sessionId,
    String agentId = 'general',
    String provider = 'gemini',
    Map<String, dynamic>? context,
  });

  Future<Either<Failure, Map<String, dynamic>>> iniciarMonitoreoVoz(String hiveId);
  Future<Either<Failure, void>> guardarRespuestasVoz(String hiveId, List<Map<String, dynamic>> respuestas);

  /// Precarga (con conexión) las preguntas de monitoreo de una colmena para
  /// que Maya pueda usarlas después sin señal. Best-effort: no falla si no hay
  /// conexión.
  Future<void> precacheHiveMonitoring(String hiveId);
}
