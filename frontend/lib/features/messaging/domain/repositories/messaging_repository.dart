import '../entities/conversation.dart';
import '../entities/message.dart';

abstract interface class MessagingRepository {
  Future<List<Conversation>> getConversations();
  Future<List<Message>> getMessages(String conversationId);
  Future<Message> sendMessage(String conversationId, String text);
}
