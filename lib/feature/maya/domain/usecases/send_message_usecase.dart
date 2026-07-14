import 'package:either_dart/either.dart';
import '../../../../core/error/failures.dart';
import '../entities/chat_message.dart';
import '../repositories/maya_repository.dart';

class SendMessageUseCase {
  final MayaRepository repository;

  SendMessageUseCase(this.repository);

  Future<Either<Failure, ChatMessage>> execute({
    required String prompt,
    String? sessionId,
    String agentId = 'general',
    String provider = 'gemini',
    Map<String, dynamic>? context,
  }) {
    return repository.sendMessage(
      prompt: prompt,
      sessionId: sessionId,
      agentId: agentId,
      provider: provider,
      context: context,
    );
  }
}
