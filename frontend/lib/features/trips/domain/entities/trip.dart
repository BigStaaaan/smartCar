import 'publish_trip.dart';

enum TripStatus { published, cancelled, inProgress, completed }

class Trip {
  const Trip({
    required this.id,
    required this.details,
    this.status = TripStatus.published,
  });

  final String id;
  final PublishTrip details;
  final TripStatus status;

  bool isUpcoming(DateTime now) =>
      status == TripStatus.published && details.departureAt.isAfter(now);

  bool canStart(DateTime now) =>
      status == TripStatus.published && !details.departureAt.isAfter(now);
}
