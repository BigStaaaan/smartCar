import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/messaging_remote_datasource.dart';
import '../../data/repositories/messaging_repository_impl.dart';
import '../../domain/entities/conversation.dart';
import '../../domain/entities/message.dart';
import '../../domain/usecases/get_conversations.dart';
import '../../domain/usecases/get_messages.dart';
import '../../domain/usecases/send_message.dart';

final messagingDataSourceProvider = Provider<MessagingRemoteDataSource>(
  (ref) => MessagingRemoteDataSource(),
);

final messagingRepositoryProvider = Provider<MessagingRepositoryImpl>(
  (ref) => MessagingRepositoryImpl(ref.watch(messagingDataSourceProvider)),
);

final getConversationsProvider = Provider<GetConversations>(
  (ref) => GetConversations(ref.watch(messagingRepositoryProvider)),
);

final getMessagesProvider = Provider<GetMessages>(
  (ref) => GetMessages(ref.watch(messagingRepositoryProvider)),
);

final sendMessageProvider = Provider<SendMessage>(
  (ref) => SendMessage(ref.watch(messagingRepositoryProvider)),
);

final conversationsProvider = FutureProvider<List<Conversation>>(
  (ref) => ref.watch(getConversationsProvider).call(),
);

final messagesProvider = FutureProvider.family<List<Message>, String>(
  (ref, conversationId) => ref.watch(getMessagesProvider).call(conversationId),
);

final messageActionsProvider = Provider<MessageActions>(
  (ref) => MessageActions(ref),
);

class MessageActions {
  const MessageActions(this._ref);

  final Ref _ref;

  Future<void> send(String conversationId, String text) async {
    await _ref.read(sendMessageProvider).call(conversationId, text);
    _ref.invalidate(messagesProvider(conversationId));
    _ref.invalidate(conversationsProvider);
  }
}
