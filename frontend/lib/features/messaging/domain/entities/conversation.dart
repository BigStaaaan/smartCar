import 'message.dart';

class Conversation {
  const Conversation({
    required this.id,
    required this.reservationId,
    required this.tripTitle,
    required this.otherParticipantName,
    required this.otherParticipantRole,
    required this.lastMessage,
    required this.updatedAt,
    required this.isReservationAccepted,
  });

  final String id;
  final String reservationId;
  final String tripTitle;
  final String otherParticipantName;
  final String otherParticipantRole;
  final Message? lastMessage;
  final DateTime updatedAt;
  final bool isReservationAccepted;
}
