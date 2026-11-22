import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../vehicles/domain/vehicle.dart';
import '../../../vehicles/presentation/vehicle_provider.dart';
import '../../../vehicles/presentation/vehicle_theme.dart';
import '../../domain/entities/trip.dart';
import '../providers/trip_provider.dart';
import '../widgets/trip_publish_controls.dart';
import 'trip_details_page.dart';

enum _TripFilter { upcoming, past, cancelled }

class MyTripsPage extends ConsumerStatefulWidget {
  const MyTripsPage({
    super.key,
    this.isPreview = false,
    this.onPublish,
    this.coordinateLabels,
  });

  final bool isPreview;
  final Future<void> Function(BuildContext context)? onPublish;
  final ({String? origin, String? destination}) Function(Trip trip)?
      coordinateLabels;

  @override
  ConsumerState<MyTripsPage> createState() => _MyTripsPageState();
}

class _MyTripsPageState extends ConsumerState<MyTripsPage> {
  _TripFilter _filter = _TripFilter.upcoming;

  List<Trip> _visibleTrips(List<Trip> trips, DateTime now) {
    final matching = trips
        .where((trip) => switch (_filter) {
              _TripFilter.upcoming =>
                trip.isUpcoming(now) || trip.status == TripStatus.inProgress,
              _TripFilter.past =>
                trip.status == TripStatus.completed || trip.canStart(now),
              _TripFilter.cancelled => trip.status == TripStatus.cancelled,
            })
        .toList();
    matching.sort((first, second) => _filter == _TripFilter.upcoming
        ? first.details.departureAt.compareTo(second.details.departureAt)
        : second.details.departureAt.compareTo(first.details.departureAt));
    return matching;
  }

  Future<void> _openPublication(BuildContext context) async {
    await widget.onPublish?.call(context);
    if (!mounted) return;
    setState(() => _filter = _TripFilter.upcoming);
    ref.invalidate(myTripsProvider);
  }

  void _openDetails(BuildContext context, Trip trip) {
    final coordinates = widget.coordinateLabels?.call(trip);
    final reduced = MediaQuery.disableAnimationsOf(context);
    Navigator.of(context).push(PageRouteBuilder<void>(
      transitionDuration:
          reduced ? Duration.zero : const Duration(milliseconds: 500),
      reverseTransitionDuration:
          reduced ? Duration.zero : const Duration(milliseconds: 250),
      pageBuilder: (context, animation, secondaryAnimation) => TripDetailsPage(
        trip: trip,
        isPreview: widget.isPreview,
        originCoordinates: coordinates?.origin,
        destinationCoordinates: coordinates?.destination,
      ),
      transitionsBuilder: (context, animation, secondaryAnimation, child) =>
          FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: animation.drive(Tween(begin: .97, end: 1.0)),
          child: child,
        ),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final trips = ref.watch(myTripsProvider);
    final vehicles =
        ref.watch(vehiclesProvider).valueOrNull ?? const <Vehicle>[];
    final vehicleNames = {
      for (final vehicle in vehicles) vehicle.id: vehicle.name
    };
    final now = DateTime.now();
    final count =
        trips.valueOrNull?.where((trip) => trip.isUpcoming(now)).length;
    return Theme(
      data: vehicleTheme(),
      child: Builder(
          builder: (context) => Scaffold(
                backgroundColor: vehicleCream,
                body: SafeArea(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 480),
                      child: Stack(children: [
                        const Positioned(
                            top: -70,
                            right: -70,
                            child: TripHalo(color: vehicleTeal)),
                        const Positioned(
                            bottom: 30,
                            left: -80,
                            child: TripHalo(color: vehicleBlue)),
                        Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(18, 22, 18, 14),
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(children: [
                                        if (Navigator.canPop(context)) ...[
                                          TripCircleButton(
                                            tooltip: 'Retour',
                                            onPressed: () =>
                                                Navigator.maybePop(context),
                                            child:
                                                const Icon(Icons.chevron_left),
                                          ),
                                          const SizedBox(width: 8),
                                        ],
                                        Expanded(
                                            child: Text(
                                          'Mes trajets',
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleLarge
                                              ?.copyWith(
                                                fontSize: 30,
                                                height: 1,
                                                letterSpacing: -1.2,
                                              ),
                                        )),
                                        if (count != null)
                                          TripPill('$count à venir'),
                                      ]),
                                      if (widget.isPreview) ...[
                                        const SizedBox(height: 4),
                                        const TripNote('Aperçu local'),
                                      ],
                                      const SizedBox(height: 14),
                                      _TripsTabs(
                                        selected: _filter,
                                        onSelected: (next) =>
                                            setState(() => _filter = next),
                                      ),
                                    ]),
                              ),
                              Expanded(
                                child: AnimatedSwitcher(
                                  duration:
                                      MediaQuery.disableAnimationsOf(context)
                                          ? Duration.zero
                                          : const Duration(milliseconds: 220),
                                  child: trips.when(
                                    loading: () => const Center(
                                      key: ValueKey('loading'),
                                      child: CircularProgressIndicator(),
                                    ),
                                    error: (error, stackTrace) => Center(
                                      key: const ValueKey('error'),
                                      child: TextButton(
                                        onPressed: () =>
                                            ref.invalidate(myTripsProvider),
                                        child: const Text(
                                            'Impossible de charger les trajets. Réessayer'),
                                      ),
                                    ),
                                    data: (allTrips) {
                                      final visible =
                                          _visibleTrips(allTrips, now);
                                      return ListView.separated(
                                        key: ValueKey(_filter),
                                        padding: const EdgeInsets.fromLTRB(
                                            18, 0, 18, 18),
                                        itemCount: visible.isEmpty
                                            ? 1
                                            : visible.length,
                                        separatorBuilder: (context, index) =>
                                            const SizedBox(height: 10),
                                        itemBuilder: (context, index) {
                                          if (visible.isEmpty) {
                                            return const TripOliveCard(
                                              child: _TripsEmpty(),
                                            );
                                          }
                                          final trip = visible[index];
                                          return TweenAnimationBuilder<double>(
                                            key: ValueKey(trip.id),
                                            tween: Tween(begin: 0, end: 1),
                                            duration:
                                                MediaQuery.disableAnimationsOf(
                                                        context)
                                                    ? Duration.zero
                                                    : Duration(
                                                        milliseconds: 700 +
                                                            math.min(index, 5) *
                                                                80),
                                            curve: Curves.easeOutCubic,
                                            child: _TripCard(
                                              trip: trip,
                                              date: tripDateLabel(
                                                  trip.details.departureAt),
                                              status:
                                                  tripStatusLabel(trip, now),
                                              vehicle: vehicleNames[
                                                      trip.details.vehicleId] ??
                                                  'Véhicule indisponible',
                                              onTap: () =>
                                                  _openDetails(context, trip),
                                            ),
                                            builder: (_, value, child) =>
                                                Opacity(
                                              opacity: value,
                                              child: Transform.translate(
                                                  offset: Offset(
                                                      0, 16 * (1 - value)),
                                                  child: child),
                                            ),
                                          );
                                        },
                                      );
                                    },
                                  ),
                                ),
                              ),
                              if (widget.onPublish != null)
                                Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(18, 4, 18, 16),
                                  child: TripPress(
                                    child: FilledButton(
                                      onPressed: () =>
                                          _openPublication(context),
                                      child: const Text('Publier un trajet'),
                                    ),
                                  ),
                                ),
                            ]),
                      ]),
                    ),
                  ),
                ),
              )),
    );
  }
}

class _TripsTabs extends StatelessWidget {
  const _TripsTabs({required this.selected, required this.onSelected});

  final _TripFilter selected;
  final ValueChanged<_TripFilter> onSelected;

  @override
  Widget build(BuildContext context) => Container(
        constraints: const BoxConstraints(minHeight: 37),
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: vehicleTeal),
        ),
        child: Stack(children: [
          Positioned.fill(
            child: AnimatedAlign(
              duration: MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero
                  : const Duration(milliseconds: 400),
              curve: Curves.easeOutCubic,
              alignment: Alignment(selected.index.toDouble() - 1, 0),
              child: FractionallySizedBox(
                widthFactor: 1 / 3,
                heightFactor: 1,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: vehicleTeal,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            ),
          ),
          Row(children: [
            for (final (index, label)
                in ['À venir', 'Passés', 'Annulés'].indexed)
              Expanded(
                child: Semantics(
                  selected: selected.index == index,
                  button: true,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(999),
                    onTap: () => onSelected(_TripFilter.values[index]),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 3),
                      child: Text(
                        label,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ),
              ),
          ]),
        ]),
      );
}

class _TripsEmpty extends StatelessWidget {
  const _TripsEmpty();

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(children: [
          Text('Rien ici',
              style: Theme.of(context)
                  .textTheme
                  .displaySmall
                  ?.copyWith(fontSize: 30)),
          const TripNote('Aucun trajet dans cette catégorie'),
        ]),
      );
}

class _TripCard extends StatelessWidget {
  const _TripCard({
    required this.trip,
    required this.date,
    required this.status,
    required this.vehicle,
    required this.onTap,
  });

  final Trip trip;
  final String date;
  final String status;
  final String vehicle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => TripOliveCard(
        onTap: onTap,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Flexible(child: TripPill(date)),
            const SizedBox(width: 6),
            TripPill(status),
          ]),
          const SizedBox(height: 10),
          Text(trip.details.origin,
              style: const TextStyle(fontWeight: FontWeight.w800)),
          const TripNote('↓'),
          Text(trip.details.destination,
              style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 5),
          TripNote(vehicle),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(
                          child: TripNote(
                              '${trip.details.seats} places proposées')),
                      const SizedBox(width: 8),
                      Text(tripContributionLabel(trip),
                          style: const TextStyle(fontWeight: FontWeight.w800)),
                    ]),
                    const SizedBox(height: 6),
                    Container(
                      height: 4,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: vehicleBlue.withValues(alpha: .62),
                      ),
                    ),
                  ]),
            ),
            const SizedBox(width: 7),
            const Icon(Icons.chevron_right, size: 18),
          ]),
        ]),
      );
}
