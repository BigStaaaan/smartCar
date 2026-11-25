import '../../domain/entities/message.dart';

class MessageModel extends Message {
  const MessageModel({
    required super.id,
    required super.conversationId,
    required super.sender,
    required super.text,
    required super.sentAt,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) => MessageModel(
        id: json['id'] as String,
        conversationId: json['conversationId'] as String,
        sender: MessageSender.values.byName(json['sender'] as String),
        text: json['text'] as String,
        sentAt: DateTime.parse(json['sentAt'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'conversationId': conversationId,
        'sender': sender.name,
        'text': text,
        'sentAt': sentAt.toIso8601String(),
      };
}
