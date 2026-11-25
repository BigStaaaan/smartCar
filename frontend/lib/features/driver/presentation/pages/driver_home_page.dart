import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../trips/domain/entities/trip.dart';
import '../../../trips/presentation/pages/my_trips_page.dart';
import '../../../trips/presentation/pages/publish_trip_page.dart';
import '../../../trips/presentation/pages/trip_details_page.dart';
import '../../../trips/presentation/providers/trip_provider.dart';
import '../../../vehicles/presentation/vehicles_page.dart';
import '../../data/driver_reservation_repository.dart';
import 'driver_dashboard_page.dart';
import 'driver_reservation_requests_page.dart';

/// Composes the Driver routes within the repository scope supplied by the host.
class DriverHomePage extends ConsumerWidget {
  const DriverHomePage(
      {super.key,
      this.isPreview = false,
      this.driverPhotoUrl,
      this.reservationRepository});

  final bool isPreview;
  final String? driverPhotoUrl;
  final DriverReservationRepository? reservationRepository;

  Future<void> _openPublication(BuildContext context) =>
      Navigator.of(context).push<void>(MaterialPageRoute(
        builder: (_) => PublishTripPage(isPreview: isPreview),
      ));

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trips = ref.watch(myTripsProvider).valueOrNull ?? const <Trip>[];
    final now = DateTime.now();
    final upcoming = trips.where((trip) => trip.isUpcoming(now)).toList()
      ..sort((first, second) =>
          first.details.departureAt.compareTo(second.details.departureAt));
    final inProgress =
        trips.where((trip) => trip.status == TripStatus.inProgress);
    final ready = trips.where((trip) => trip.canStart(now)).toList()
      ..sort((first, second) =>
          second.details.departureAt.compareTo(first.details.departureAt));
    final featured =
        inProgress.firstOrNull ?? ready.firstOrNull ?? upcoming.firstOrNull;

    final requests = reservationRepository;
    return DriverDashboardPage(
      onRequests: requests == null
          ? null
          : () => Navigator.of(context).push<void>(MaterialPageRoute(
                builder: (_) => DriverReservationRequestsPage(
                    repository: requests, isPreview: isPreview),
              )),
      driverPhotoUrl: driverPhotoUrl,
      tripOverview: (
        featured: featured,
        upcoming: upcoming.length,
        inProgress: inProgress.length,
        completed:
            trips.where((trip) => trip.status == TripStatus.completed).length,
      ),
      onTripDetails: featured == null
          ? null
          : () => Navigator.of(context).push<void>(MaterialPageRoute(
                builder: (_) => TripDetailsPage(
                    trip: featured,
                    isPreview: isPreview,
                    backTooltip: 'Retour au Dashboard'),
              )),
      onPublish: () async {
        await _openPublication(context);
        if (context.mounted) ref.invalidate(myTripsProvider);
      },
      onTrips: () => Navigator.of(context).push<void>(MaterialPageRoute(
        builder: (_) =>
            MyTripsPage(isPreview: isPreview, onPublish: _openPublication),
      )),
      onVehicles: () => Navigator.of(context).push<void>(MaterialPageRoute(
        builder: (_) => VehiclesPage(isDemo: isPreview),
      )),
    );
  }
}
