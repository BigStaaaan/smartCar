import 'package:flutter/material.dart';

import '../../../vehicles/presentation/vehicle_theme.dart';
import '../../domain/entities/trip.dart';
import '../widgets/trip_publish_controls.dart';

class ActiveTripPage extends StatelessWidget {
  const ActiveTripPage({
    super.key,
    required this.trip,
    required this.departureLabel,
    required this.vehicleLabel,
    required this.backTooltip,
    required this.onComplete,
  });

  final Trip trip;
  final String departureLabel;
  final String vehicleLabel;
  final String backTooltip;
  final void Function(BuildContext)? onComplete;

  @override
  Widget build(BuildContext context) {
    final passengers = trip.confirmedPassengerNames;
    return Theme(
      data: driverTheme(),
      child: Builder(
        builder: (context) => Scaffold(
          backgroundColor: driverSurface,
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(18, 22, 18, 32),
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TripCircleButton(
                          tooltip: backTooltip,
                          onPressed: () => Navigator.maybePop(context),
                          child: const Icon(Icons.chevron_left),
                        ),
                        const TripPill('En cours'),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text('Trajet en cours',
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 14),
                    DriverCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const TripNote('Départ'),
                          Text(trip.details.origin),
                          const SizedBox(height: 8),
                          const TripNote('Destination'),
                          Text(trip.details.destination),
                          const SizedBox(height: 8),
                          const TripNote('Date et heure prévues'),
                          Text(departureLabel),
                          const SizedBox(height: 8),
                          const TripNote('Véhicule utilisé'),
                          Text(vehicleLabel),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    DriverCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Passagers confirmés',
                              style: Theme.of(context).textTheme.titleSmall),
                          const SizedBox(height: 6),
                          if (passengers == null)
                            const TripNote('Liste des passagers indisponible')
                          else if (passengers.isEmpty)
                            const TripNote('Aucun passager confirmé')
                          else
                            for (final name in passengers)
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 3),
                                child: Text(name),
                              ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    FilledButton(
                      onPressed: onComplete == null
                          ? null
                          : () => onComplete!(context),
                      child: const Text('Terminer le trajet'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
