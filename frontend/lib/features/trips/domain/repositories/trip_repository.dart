import '../entities/publish_trip.dart';
import '../entities/trip.dart';

abstract interface class TripRepository {
  Future<Trip> publish(PublishTrip details);
  Future<List<Trip>> listMine();
}
