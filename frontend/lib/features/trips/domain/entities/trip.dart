import 'publish_trip.dart';

enum TripStatus { published, cancelled }

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
}
