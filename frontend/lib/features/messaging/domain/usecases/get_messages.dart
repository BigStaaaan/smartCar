import '../entities/message.dart';
import '../repositories/messaging_repository.dart';

class GetMessages {
  const GetMessages(this._repository);

  final MessagingRepository _repository;

  Future<List<Message>> call(String conversationId) =>
      _repository.getMessages(conversationId);
}
