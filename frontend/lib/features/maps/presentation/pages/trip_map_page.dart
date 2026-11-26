import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart'
    hide LocationServiceDisabledException;
import 'package:maplibre/maplibre.dart';
import 'package:maplibre_geolocator/maplibre_geolocator.dart';

import '../../data/datasources/maps_remote_datasource.dart';
import '../../domain/entities/map_location.dart';
import '../providers/maps_provider.dart';

class TripMapPage extends ConsumerStatefulWidget {
  const TripMapPage({super.key});

  @override
  ConsumerState<TripMapPage> createState() => _TripMapPageState();
}

class _TripMapPageState extends ConsumerState<TripMapPage> {
  static const _styleUrl = 'https://tiles.openfreemap.org/styles/liberty';
  Geographic? _selectedPosition;
  var _tracking = UserLocationTracking.position;

  @override
  Widget build(BuildContext context) {
    final location = ref.watch(currentLocationProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Choose a location')),
      body: location.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _LocationError(
          message: _errorMessage(error),
          canOpenSettings:
              error is LocationPermissionPermanentlyDeniedException ||
                  error is LocationServiceDisabledException,
          onRetry: () => ref.invalidate(currentLocationProvider),
        ),
        data: (currentLocation) => _buildMap(currentLocation),
      ),
    );
  }

  Widget _buildMap(MapLocation currentLocation) {
    final current = Geographic(
      lon: currentLocation.longitude,
      lat: currentLocation.latitude,
    );
    final selected = _selectedPosition;

    return MapLibreMap(
      options: MapOptions(
        style: MapStyle.url(_styleUrl),
        initCamera: CameraUpdate.position(center: current, zoom: 14),
      ),
      onClick: (event) => setState(() => _selectedPosition = event.point),
      children: [
        UserLocationLayer(
          locations: geolocatorUserLocations(),
          tracking: _tracking,
          trackingZoom: 14,
          onTrackingChanged: (tracking) => setState(() => _tracking = tracking),
        ),
        MapControlButtons(
          tracking: _tracking,
          onTrackingPressed: () =>
              setState(() => _tracking = UserLocationTracking.position),
        ),
        if (selected != null)
          WidgetLayer(
            markers: [
              Marker(
                point: selected,
                size: const Size(32, 32),
                child: const Icon(
                  Icons.location_on,
                  color: Colors.red,
                  size: 32,
                ),
              ),
            ],
          ),
      ],
    );
  }

  String _errorMessage(Object error) {
    if (error is LocationPermissionPermanentlyDeniedException) {
      return 'Location permission is permanently denied. Enable it in app settings to show your position.';
    }
    if (error is LocationPermissionDeniedException ||
        error is PermissionDeniedException) {
      return 'Location permission was denied. Allow location access to show your position.';
    }
    if (error is LocationServiceDisabledException) {
      return 'Location services are turned off. Enable GPS to show your position.';
    }
    return 'Could not get your current location. Try again.';
  }
}

class _LocationError extends StatelessWidget {
  const _LocationError({
    required this.message,
    required this.canOpenSettings,
    required this.onRetry,
  });

  final String message;
  final bool canOpenSettings;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.location_off_outlined, size: 48),
              const SizedBox(height: 16),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                children: [
                  OutlinedButton(
                    onPressed: onRetry,
                    child: const Text('Try again'),
                  ),
                  if (canOpenSettings)
                    TextButton(
                      onPressed: () async {
                        if (message.contains('permanently denied')) {
                          await Geolocator.openAppSettings();
                        } else {
                          await Geolocator.openLocationSettings();
                        }
                      },
                      child: const Text('Open settings'),
                    ),
                ],
              ),
            ],
          ),
        ),
      );
}
