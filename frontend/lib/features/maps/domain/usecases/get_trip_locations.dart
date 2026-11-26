import '../entities/map_location.dart';
import '../repositories/maps_repository.dart';

class GetCurrentLocation {
  const GetCurrentLocation(this._repository);

  final MapsRepository _repository;

  Future<MapLocation> call() => _repository.getCurrentLocation();
}
