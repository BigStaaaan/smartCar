enum MessageSender { driver, passenger }

class Message {
  const Message({
    required this.id,
    required this.conversationId,
    required this.sender,
    required this.text,
    required this.sentAt,
  });

  final String id;
  final String conversationId;
  final MessageSender sender;
  final String text;
  final DateTime sentAt;
}
