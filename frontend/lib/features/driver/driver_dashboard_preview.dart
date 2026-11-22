import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../trips/data/repositories/demo_trip_repository.dart';
import '../trips/domain/entities/publish_trip.dart';
import '../trips/domain/entities/trip.dart';
import '../trips/presentation/providers/trip_provider.dart';
import '../vehicles/data/demo_vehicle_repository.dart';
import '../vehicles/presentation/vehicle_provider.dart';
import 'presentation/pages/driver_home_page.dart';

// Temporary entry point using the same repositories throughout the Driver flow.
void main() {
  final departure = DateTime.now().subtract(const Duration(minutes: 1));
  runApp(ProviderScope(
    overrides: [
      vehicleRepositoryProvider.overrideWithValue(DemoVehicleRepository()),
      tripRepositoryProvider
          .overrideWithValue(DemoTripRepository(initialTrips: [
        Trip(
          id: 'preview-ready',
          details: PublishTrip(
            origin: 'Gare Marrakech (démo)',
            destination: 'Campus universitaire',
            departureAt: departure,
            vehicleId: 'dacia',
            seats: 2,
            contributionDh: 15,
          ),
        ),
      ])),
    ],
    child: const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: DriverHomePage(
        isPreview: true,
        driverPhotoUrl: 'https://i.pravatar.cc/128?img=12',
      ),
    ),
  ));
}
