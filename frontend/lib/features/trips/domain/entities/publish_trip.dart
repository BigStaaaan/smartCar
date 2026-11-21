class PublishTrip {
  const PublishTrip({
    required this.origin,
    required this.destination,
    required this.departureAt,
    required this.vehicleId,
    required this.seats,
    this.contributionDh,
  });

  final String origin;
  final String destination;
  final DateTime departureAt;
  final String vehicleId;
  final int seats;
  final int? contributionDh;
}
