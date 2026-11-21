import '../../domain/entities/publish_trip.dart';
import '../../domain/entities/trip.dart';
import '../../domain/repositories/trip_repository.dart';

/// Session-only storage shared by the trip previews.
class DemoTripRepository implements TripRepository {
  DemoTripRepository({Iterable<Trip> initialTrips = const []})
      : _trips = [...initialTrips];

  final List<Trip> _trips;

  List<Trip> get publishedTrips => List.unmodifiable(_trips);

  @override
  Future<List<Trip>> listMine() async => publishedTrips;

  @override
  Future<Trip> publish(PublishTrip details) async {
    var sequence = _trips.length + 1;
    while (_trips.any((trip) => trip.id == 'preview-$sequence')) {
      sequence++;
    }
    final trip = Trip(id: 'preview-$sequence', details: details);
    _trips.add(trip);
    return trip;
  }
}
