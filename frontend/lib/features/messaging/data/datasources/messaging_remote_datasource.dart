import '../../domain/entities/conversation.dart';
import '../../domain/entities/message.dart';
import '../models/message_model.dart';

/// In-memory implementation for the first UI phase.
/// Replace with REST calls while keeping the repository contract stable.
class MessagingRemoteDataSource {
  MessagingRemoteDataSource({this.currentUserRole = MessageSender.passenger}) {
    _seedMockData();
  }

  final MessageSender currentUserRole;
  final Map<String, Conversation> _conversations = {};
  final Map<String, List<MessageModel>> _messages = {};

  Future<List<Conversation>> getConversations() async {
    final conversations = _conversations.values
        .where((conversation) => conversation.isReservationAccepted)
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return conversations;
  }

  Future<List<Message>> getMessages(String conversationId) async {
    _requireAcceptedConversation(conversationId);
    return List.unmodifiable(_messages[conversationId] ?? const []);
  }

  Future<Message> sendMessage(String conversationId, String text) async {
    _requireAcceptedConversation(conversationId);
    final normalizedText = text.trim();
    if (normalizedText.isEmpty) {
      throw ArgumentError.value(text, 'text', 'Message cannot be empty');
    }

    final message = MessageModel(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      conversationId: conversationId,
      sender: currentUserRole,
      text: normalizedText,
      sentAt: DateTime.now(),
    );
    _messages.putIfAbsent(conversationId, () => []).add(message);
    final conversation = _conversations[conversationId]!;
    _conversations[conversationId] = Conversation(
      id: conversation.id,
      reservationId: conversation.reservationId,
      tripTitle: conversation.tripTitle,
      otherParticipantName: conversation.otherParticipantName,
      otherParticipantRole: conversation.otherParticipantRole,
      lastMessage: message,
      updatedAt: message.sentAt,
      isReservationAccepted: conversation.isReservationAccepted,
    );
    return message;
  }

  void _requireAcceptedConversation(String conversationId) {
    final conversation = _conversations[conversationId];
    if (conversation == null || !conversation.isReservationAccepted) {
      throw StateError(
          'Conversation is unavailable until reservation acceptance.');
    }
  }

  void _seedMockData() {
    final now = DateTime.now();
    final conversations = [
      Conversation(
        id: 'conversation-101',
        reservationId: 'reservation-101',
        tripTitle: 'Agadir → Université Ibn Zohr',
        otherParticipantName: 'Youssef Amrani',
        otherParticipantRole: 'Driver',
        lastMessage: null,
        updatedAt: now.subtract(const Duration(minutes: 4)),
        isReservationAccepted: true,
      ),
      Conversation(
        id: 'conversation-102',
        reservationId: 'reservation-102',
        tripTitle: 'Inezgane → Agadir centre',
        otherParticipantName: 'Salma Idrissi',
        otherParticipantRole: 'Passenger',
        lastMessage: null,
        updatedAt: now.subtract(const Duration(hours: 2)),
        isReservationAccepted: true,
      ),
      Conversation(
        id: 'conversation-pending',
        reservationId: 'reservation-pending',
        tripTitle: 'Pending reservation',
        otherParticipantName: 'Pending passenger',
        otherParticipantRole: 'Passenger',
        lastMessage: null,
        updatedAt: now,
        isReservationAccepted: false,
      ),
    ];
    for (final conversation in conversations) {
      _conversations[conversation.id] = conversation;
      _messages[conversation.id] = [];
    }
    _messages['conversation-101']!.addAll([
      MessageModel(
        id: 'message-101-1',
        conversationId: 'conversation-101',
        sender: MessageSender.driver,
        text: 'Hi! I can pick you up near the main gate.',
        sentAt: now.subtract(const Duration(minutes: 12)),
      ),
      MessageModel(
        id: 'message-101-2',
        conversationId: 'conversation-101',
        sender: MessageSender.passenger,
        text: 'Perfect, I will be there a few minutes early.',
        sentAt: now.subtract(const Duration(minutes: 4)),
      ),
    ]);
    _messages['conversation-102']!.add(
      MessageModel(
        id: 'message-102-1',
        conversationId: 'conversation-102',
        sender: MessageSender.passenger,
        text: 'Thanks for accepting my reservation!',
        sentAt: now.subtract(const Duration(hours: 2)),
      ),
    );
    for (final conversation
        in conversations.where((item) => item.isReservationAccepted)) {
      final messages = _messages[conversation.id]!;
      if (messages.isNotEmpty) {
        final lastMessage = messages.last;
        _conversations[conversation.id] = Conversation(
          id: conversation.id,
          reservationId: conversation.reservationId,
          tripTitle: conversation.tripTitle,
          otherParticipantName: conversation.otherParticipantName,
          otherParticipantRole: conversation.otherParticipantRole,
          lastMessage: lastMessage,
          updatedAt: lastMessage.sentAt,
          isReservationAccepted: true,
        );
      }
    }
  }
}
