import '../../domain/entities/publish_trip.dart';
import '../../domain/entities/trip.dart';
import '../../domain/repositories/trip_repository.dart';

/// Session-only storage used by the standalone publication preview.
class DemoTripRepository implements TripRepository {
  final _trips = <Trip>[];

  List<Trip> get publishedTrips => List.unmodifiable(_trips);

  @override
  Future<Trip> publish(PublishTrip details) async {
    final trip = Trip(id: 'preview-${_trips.length + 1}', details: details);
    _trips.add(trip);
    return trip;
  }
}
