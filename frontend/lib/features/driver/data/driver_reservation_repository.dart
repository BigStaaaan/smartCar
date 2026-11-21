enum DriverReservationStatus { pending, accepted, rejected }

class DriverReservationRequest {
  const DriverReservationRequest({
    required this.id,
    required this.passengerName,
    required this.pickup,
    required this.departureAt,
    required this.seats,
    this.contributionDh,
    this.photoUrl,
    this.rating,
    this.isUniversityVerified = false,
    this.status = DriverReservationStatus.pending,
  });

  final String id;
  final String passengerName;
  final String pickup;
  final DateTime departureAt;
  final int seats;
  final int? contributionDh;
  final String? photoUrl;
  final double? rating;
  final bool isUniversityVerified;
  final DriverReservationStatus status;
}

/// Point de raccordement à l'API du Developer 3.
abstract interface class DriverReservationRepository {
  Future<List<DriverReservationRequest>> listPending();
  Future<void> decide(String requestId, DriverReservationStatus decision);
}

/// Données de démonstration conservées uniquement pendant la session.
class DemoDriverReservationRepository implements DriverReservationRepository {
  DemoDriverReservationRepository(Iterable<DriverReservationRequest> requests)
      : _requests = {for (final request in requests) request.id: request};

  final Map<String, DriverReservationRequest> _requests;

  List<DriverReservationRequest> get requests =>
      List.unmodifiable(_requests.values);

  @override
  Future<List<DriverReservationRequest>> listPending() async => requests
      .where((request) => request.status == DriverReservationStatus.pending)
      .toList();

  @override
  Future<void> decide(
      String requestId, DriverReservationStatus decision) async {
    final request = _requests[requestId];
    if (request == null ||
        request.status != DriverReservationStatus.pending ||
        decision == DriverReservationStatus.pending) {
      throw StateError('Cette demande ne peut pas être traitée.');
    }
    _requests[requestId] = DriverReservationRequest(
      id: request.id,
      passengerName: request.passengerName,
      pickup: request.pickup,
      departureAt: request.departureAt,
      seats: request.seats,
      contributionDh: request.contributionDh,
      photoUrl: request.photoUrl,
      rating: request.rating,
      isUniversityVerified: request.isUniversityVerified,
      status: decision,
    );
  }
}
