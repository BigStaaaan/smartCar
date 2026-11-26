import '../entities/map_location.dart';

abstract interface class MapsRepository {
  Future<MapLocation> getCurrentLocation();
}
