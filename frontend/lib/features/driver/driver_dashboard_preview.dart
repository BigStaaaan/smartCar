import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../trips/data/repositories/demo_trip_repository.dart';
import '../trips/domain/entities/publish_trip.dart';
import '../trips/domain/entities/trip.dart';
import '../trips/presentation/providers/trip_provider.dart';
import '../vehicles/data/demo_vehicle_repository.dart';
import '../vehicles/presentation/vehicle_provider.dart';
import 'data/driver_reservation_repository.dart';
import 'presentation/pages/driver_home_page.dart';

// Temporary entry point using the same repositories throughout the Driver flow.
void main() {
  final departure = DateTime.now().subtract(const Duration(minutes: 1));
  final reservations = DemoDriverReservationRepository([
    DriverReservationRequest(
      id: 'preview-salma',
      passengerName: 'Salma E.',
      pickup: 'Gare Marrakech',
      departureAt: departure,
      seats: 1,
      contributionDh: 15,
      rating: 4.9,
      isUniversityVerified: true,
    ),
    DriverReservationRequest(
      id: 'preview-omar',
      passengerName: 'Omar B.',
      pickup: 'Bab Doukkala',
      departureAt: departure.add(const Duration(minutes: 15)),
      seats: 2,
      contributionDh: 15,
    ),
  ]);
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
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      home: DriverHomePage(
        isPreview: true,
        reservationRepository: reservations,
        driverPhotoUrl: 'https://i.pravatar.cc/128?img=12',
      ),
    ),
  ));
}
