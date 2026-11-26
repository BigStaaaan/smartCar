import 'package:flutter/material.dart';
import 'package:maplibre/maplibre.dart';

import '../../domain/entities/map_location.dart';

Marker currentPositionMarker(MapLocation location) => Marker(
      point: Geographic(lon: location.longitude, lat: location.latitude),
      size: const Size(28, 28),
      child: const Icon(Icons.my_location, color: Colors.blue, size: 28),
    );

Marker selectedPositionMarker(Geographic position) => Marker(
      point: position,
      size: const Size(32, 32),
      child: const Icon(Icons.location_on, color: Colors.red, size: 32),
    );
