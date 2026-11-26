import 'package:geolocator/geolocator.dart';

import '../models/map_location_model.dart';

class MapsRemoteDataSource {
  Future<MapLocationModel> getCurrentLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) throw const LocationServiceDisabledException();

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      throw const LocationPermissionDeniedException();
    }
    if (permission == LocationPermission.deniedForever) {
      throw const LocationPermissionPermanentlyDeniedException();
    }

    final position = await Geolocator.getCurrentPosition();
    return MapLocationModel(
      latitude: position.latitude,
      longitude: position.longitude,
    );
  }
}

class LocationServiceDisabledException implements Exception {
  const LocationServiceDisabledException();
}

class LocationPermissionDeniedException implements Exception {
  const LocationPermissionDeniedException();
}

class LocationPermissionPermanentlyDeniedException implements Exception {
  const LocationPermissionPermanentlyDeniedException();
}
