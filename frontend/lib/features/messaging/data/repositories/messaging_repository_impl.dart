import '../../domain/entities/conversation.dart';
import '../../domain/entities/message.dart';
import '../../domain/repositories/messaging_repository.dart';
import '../datasources/messaging_remote_datasource.dart';

class MessagingRepositoryImpl implements MessagingRepository {
  const MessagingRepositoryImpl(this._dataSource);

  final MessagingRemoteDataSource _dataSource;

  @override
  Future<List<Conversation>> getConversations() =>
      _dataSource.getConversations();

  @override
  Future<List<Message>> getMessages(String conversationId) =>
      _dataSource.getMessages(conversationId);

  @override
  Future<Message> sendMessage(String conversationId, String text) =>
      _dataSource.sendMessage(conversationId, text);
}
