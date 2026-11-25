import '../entities/message.dart';
import '../repositories/messaging_repository.dart';

class SendMessage {
  const SendMessage(this._repository);

  final MessagingRepository _repository;

  Future<Message> call(String conversationId, String text) =>
      _repository.sendMessage(conversationId, text);
}
