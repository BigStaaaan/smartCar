import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../vehicles/domain/vehicle.dart';
import '../../../vehicles/presentation/vehicle_provider.dart';
import '../../../vehicles/presentation/vehicle_theme.dart';
import '../../domain/entities/trip.dart';
import '../providers/trip_provider.dart';
import '../widgets/trip_publish_controls.dart';
import 'active_trip_page.dart';
import 'publish_trip_page.dart';

String tripDateLabel(DateTime departure) {
  const days = ['Lun.', 'Mar.', 'Mer.', 'Jeu.', 'Ven.', 'Sam.', 'Dim.'];
  const months = [
    'janv.',
    'févr.',
    'mars',
    'avr.',
    'mai',
    'juin',
    'juil.',
    'août',
    'sept.',
    'oct.',
    'nov.',
    'déc.',
  ];
  final local = departure.toLocal();
  final hours = local.hour.toString().padLeft(2, '0');
  final minutes = local.minute.toString().padLeft(2, '0');
  return '${days[local.weekday - 1]} ${local.day} ${months[local.month - 1]} ${local.year} · $hours:$minutes';
}

String tripStatusLabel(Trip trip, DateTime now) {
  return switch (trip.status) {
    TripStatus.published => trip.isUpcoming(now) ? 'Publié' : 'Prêt au départ',
    TripStatus.cancelled => 'Annulé',
    TripStatus.inProgress => 'En cours',
    TripStatus.completed => 'Terminé',
  };
}

String tripContributionLabel(Trip trip) {
  final amount = trip.details.contributionDh;
  return amount == null || amount == 0 ? 'Gratuit' : '$amount DH';
}

class TripDetailsPage extends ConsumerStatefulWidget {
  const TripDetailsPage({
    super.key,
    required this.trip,
    this.isPreview = false,
    this.backTooltip = 'Retour aux trajets',
    this.originCoordinates,
    this.destinationCoordinates,
  });

  final Trip trip;
  final bool isPreview;
  final String backTooltip;
  final String? originCoordinates;
  final String? destinationCoordinates;

  @override
  ConsumerState<TripDetailsPage> createState() => _TripDetailsPageState();
}

class _TripDetailsPageState extends ConsumerState<TripDetailsPage> {
  late Trip trip = widget.trip;
  bool _changingStatus = false;
  Timer? _departureTimer;

  @override
  void initState() {
    super.initState();
    _watchDeparture();
  }

  @override
  void dispose() {
    _departureTimer?.cancel();
    super.dispose();
  }

  void _watchDeparture() {
    _departureTimer?.cancel();
    final now = DateTime.now();
    if (trip.isUpcoming(now)) {
      _departureTimer = Timer(trip.details.departureAt.difference(now), () {
        setState(() {});
      });
    }
  }

  void _refreshTrip(Trip updatedTrip) {
    setState(() => trip = updatedTrip);
    _watchDeparture();
    ref.invalidate(myTripsProvider);
  }

  Future<void> _editTrip() async {
    if (!trip.isUpcoming(DateTime.now())) return;
    final updatedTrip = await Navigator.of(context).push<Trip>(
      MaterialPageRoute(
        builder: (_) =>
            PublishTripPage(isPreview: widget.isPreview, tripToEdit: trip),
      ),
    );
    if (mounted && updatedTrip != null) _refreshTrip(updatedTrip);
  }

  Future<void> _confirmStatusChange(
    BuildContext themedContext, {
    required String action,
    required String confirmation,
    required Future<Trip> Function(String id) changeStatus,
    String dismissLabel = 'Retour',
    String? description,
  }) async {
    if (_changingStatus) return;
    setState(() => _changingStatus = true);
    try {
      final confirmed = await showDialog<bool>(
        context: themedContext,
        builder: (context) => AlertDialog(
          title: Text('$action ?'),
          content: description == null ? null : Text(description),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(dismissLabel)),
            FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(confirmation)),
          ],
        ),
      );
      if (!mounted || confirmed != true) return;
      final updatedTrip = await changeStatus(trip.id);
      if (mounted) _refreshTrip(updatedTrip);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Changement de statut impossible. Réessayez.')),
        );
      }
    } finally {
      if (mounted) setState(() => _changingStatus = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vehicles =
        ref.watch(vehiclesProvider).valueOrNull ?? const <Vehicle>[];
    final details = trip.details;
    final originCoordinates = details.origin == widget.trip.details.origin
        ? widget.originCoordinates
        : null;
    final destinationCoordinates =
        details.destination == widget.trip.details.destination
            ? widget.destinationCoordinates
            : null;
    final vehicle = vehicles
        .where((vehicle) => vehicle.id == details.vehicleId)
        .firstOrNull;
    final now = DateTime.now();
    if (trip.status == TripStatus.inProgress) {
      return ActiveTripPage(
        trip: trip,
        departureLabel: tripDateLabel(details.departureAt),
        vehicleLabel: vehicle?.name ?? 'Véhicule indisponible',
        backTooltip: widget.backTooltip,
        onComplete: _changingStatus
            ? null
            : (context) => _confirmStatusChange(
                  context,
                  action: 'Terminer le trajet',
                  confirmation: 'Confirmer la fin du trajet',
                  changeStatus: ref.read(tripRepositoryProvider).complete,
                ),
      );
    }
    return Theme(
      data: driverTheme(),
      child: Builder(
          builder: (context) => Scaffold(
                backgroundColor: driverSurface,
                body: SafeArea(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 480),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(
                            driverPageMargin, 24, driverPageMargin, 32),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  TripCircleButton(
                                    tooltip: widget.backTooltip,
                                    onPressed: () =>
                                        Navigator.maybePop(context),
                                    child: const Icon(Icons.chevron_left),
                                  ),
                                  TripPill(tripStatusLabel(trip, now)),
                                ]),
                            const SizedBox(height: driverSectionGap),
                            Text.rich(
                              TextSpan(children: [
                                TextSpan(text: details.origin),
                                TextSpan(
                                    text: ' → ',
                                    style: Theme.of(context)
                                        .textTheme
                                        .displaySmall
                                        ?.copyWith(fontSize: 26)),
                                TextSpan(text: details.destination),
                              ]),
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                      fontSize: 26,
                                      height: 1.08,
                                      letterSpacing: -.8),
                            ),
                            const SizedBox(height: 5),
                            TripNote(tripDateLabel(details.departureAt)),
                            const SizedBox(height: driverSectionGap),
                            DriverCard(
                              child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    const TripNote('Schéma du trajet'),
                                    const SizedBox(height: 4),
                                    SizedBox(
                                      height: 97,
                                      child: TweenAnimationBuilder<double>(
                                        tween: Tween(begin: 0, end: 1),
                                        duration:
                                            MediaQuery.disableAnimationsOf(
                                                    context)
                                                ? Duration.zero
                                                : const Duration(
                                                    milliseconds: 1700),
                                        curve: Curves.easeOutCubic,
                                        builder: (_, progress, child) =>
                                            CustomPaint(
                                          painter: _TripRoutePainter(progress),
                                        ),
                                      ),
                                    ),
                                    if (originCoordinates
                                        case final coordinates?)
                                      TripNote('Départ · $coordinates'),
                                    if (destinationCoordinates
                                        case final coordinates?)
                                      TripNote('Destination · $coordinates'),
                                  ]),
                            ),
                            const SizedBox(height: driverSectionGap),
                            DriverCard(
                              child: Row(children: [
                                const SizedBox(
                                    width: 64,
                                    height: 36,
                                    child: TripVehicleDrawing()),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const TripNote('Véhicule utilisé'),
                                        Text(
                                            vehicle?.name ??
                                                'Véhicule indisponible',
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w800)),
                                        if (vehicle != null)
                                          TripNote(vehicle
                                              .details.registrationNumber),
                                      ]),
                                ),
                              ]),
                            ),
                            const SizedBox(height: driverSectionGap),
                            DriverCard(
                              child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Row(children: [
                                      const Expanded(
                                          child: Text('Places proposées',
                                              style: TextStyle(
                                                  fontWeight:
                                                      FontWeight.w800))),
                                      Text('${details.seats}',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w800)),
                                    ]),
                                    const SizedBox(height: 9),
                                    const Divider(
                                        height: 1, color: driverOutline),
                                    const SizedBox(height: 9),
                                    Row(children: [
                                      const Expanded(
                                          child: TripNote(
                                              'Contribution / passager')),
                                      Text(tripContributionLabel(trip),
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w800)),
                                    ]),
                                  ]),
                            ),
                            if (trip.isUpcoming(now)) ...[
                              const SizedBox(height: driverSectionGap),
                              Row(children: [
                                Expanded(
                                    child: OutlinedButton(
                                        onPressed:
                                            _changingStatus ? null : _editTrip,
                                        child: const Text('Modifier'))),
                                const SizedBox(width: 10),
                                Expanded(
                                    child: OutlinedButton(
                                        onPressed: _changingStatus
                                            ? null
                                            : () => _confirmStatusChange(
                                                  context,
                                                  action: 'Annuler le trajet',
                                                  confirmation:
                                                      'Confirmer l’annulation',
                                                  dismissLabel:
                                                      'Conserver le trajet',
                                                  description:
                                                      'Le trajet restera visible dans les trajets annulés.',
                                                  changeStatus: ref
                                                      .read(
                                                          tripRepositoryProvider)
                                                      .cancel,
                                                ),
                                        child:
                                            const Text('Annuler le trajet'))),
                              ]),
                            ],
                            if (trip.canStart(now)) ...[
                              const SizedBox(height: driverSectionGap),
                              FilledButton(
                                onPressed: _changingStatus
                                    ? null
                                    : () => _confirmStatusChange(
                                          context,
                                          action: 'Démarrer le trajet',
                                          confirmation:
                                              'Confirmer le démarrage',
                                          changeStatus: ref
                                              .read(tripRepositoryProvider)
                                              .start,
                                        ),
                                child: const Text('Démarrer le trajet'),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              )),
    );
  }
}

class _TripRoutePainter extends CustomPainter {
  const _TripRoutePainter(this.progress);

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final start = Offset(centerX, 12);
    final end = Offset(centerX, size.height - 12);
    final pen = Paint()
      ..color = driverAccent
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2;
    final visibleEnd = start.dy + (end.dy - start.dy) * progress;
    for (double y = start.dy + 9; y < visibleEnd - 6; y += 8) {
      final dashEnd = (y + 4).clamp(y, visibleEnd - 6).toDouble();
      canvas.drawLine(Offset(centerX, y), Offset(centerX, dashEnd), pen);
    }
    canvas.drawCircle(start, 5, Paint()..color = driverAccent);
    if (progress >= 1) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: end, width: 14, height: 9),
          const Radius.circular(4.5),
        ),
        Paint()..color = driverAccent,
      );
    }
  }

  @override
  bool shouldRepaint(_TripRoutePainter oldDelegate) =>
      oldDelegate.progress != progress;
}
