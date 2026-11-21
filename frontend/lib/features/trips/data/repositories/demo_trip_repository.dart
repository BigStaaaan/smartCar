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

  int _editableTripIndex(String id, DateTime now) {
    final index = _trips.indexWhere((trip) => trip.id == id);
    if (index < 0 || !_trips[index].isUpcoming(now)) {
      throw StateError('Ce trajet ne peut plus être modifié ou annulé.');
    }
    return index;
  }

  @override
  Future<Trip> update(String id, PublishTrip details) async {
    final now = DateTime.now();
    final index = _editableTripIndex(id, now);
    if (!details.departureAt.isAfter(now)) {
      throw ArgumentError('Le départ doit être dans le futur.');
    }
    return _trips[index] = Trip(id: id, details: details);
  }

  @override
  Future<Trip> cancel(String id) async {
    final index = _editableTripIndex(id, DateTime.now());
    return _trips[index] = Trip(
      id: id,
      details: _trips[index].details,
      status: TripStatus.cancelled,
    );
  }

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
