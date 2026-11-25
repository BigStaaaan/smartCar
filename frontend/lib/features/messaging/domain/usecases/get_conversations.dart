import '../entities/conversation.dart';
import '../repositories/messaging_repository.dart';

class GetConversations {
  const GetConversations(this._repository);

  final MessagingRepository _repository;

  Future<List<Conversation>> call() => _repository.getConversations();
}
