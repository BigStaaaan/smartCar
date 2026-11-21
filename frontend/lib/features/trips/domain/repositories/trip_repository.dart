import '../entities/publish_trip.dart';
import '../entities/trip.dart';

abstract interface class TripRepository {
  Future<Trip> publish(PublishTrip details);
  Future<List<Trip>> listMine();
  Future<Trip> update(String id, PublishTrip details);
  Future<Trip> cancel(String id);
}
