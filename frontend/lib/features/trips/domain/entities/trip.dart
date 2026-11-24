import 'publish_trip.dart';

enum TripStatus { published, cancelled, inProgress, completed }

class Trip {
  const Trip({
    required this.id,
    required this.details,
    this.status = TripStatus.published,
    this.confirmedPassengerNames,
  });

  final String id;
  final PublishTrip details;
  final TripStatus status;

  /// Null when no reservation data is available.
  final List<String>? confirmedPassengerNames;

  bool isUpcoming(DateTime now) =>
      status == TripStatus.published && details.departureAt.isAfter(now);

  bool canStart(DateTime now) =>
      status == TripStatus.published && !details.departureAt.isAfter(now);
}
