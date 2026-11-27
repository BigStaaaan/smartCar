import 'dart:async';
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../../../trips/domain/entities/trip.dart';
import '../../../trips/presentation/pages/trip_details_page.dart';
import '../../../vehicles/presentation/vehicle_theme.dart';
import '../widgets/driver_avatar.dart';

/// An isolated Driver screen. Callbacks can be wired by the host when ready.
class DriverDashboardPage extends StatefulWidget {
  const DriverDashboardPage({
    super.key,
    this.onPublish,
    this.onTripDetails,
    this.onProfile,
    this.onTrips,
    this.onVehicles,
    this.onRequests,
    this.tripOverview,
    this.driverPhotoUrl,
    this.firstRiderPhotoUrl,
    this.secondRiderPhotoUrl,
  });

  final VoidCallback? onPublish;
  final VoidCallback? onTripDetails;
  final VoidCallback? onProfile;
  final VoidCallback? onTrips;
  final VoidCallback? onVehicles;
  final VoidCallback? onRequests;
  final ({
    Trip? featured,
    int upcoming,
    int inProgress,
    int completed
  })? tripOverview;
  final String? driverPhotoUrl;
  final String? firstRiderPhotoUrl;
  final String? secondRiderPhotoUrl;

  @override
  State<DriverDashboardPage> createState() => _DriverDashboardPageState();
}

class _DriverDashboardPageState extends State<DriverDashboardPage>
    with TickerProviderStateMixin {
  // Prototype fixtures. Replace these with the Driver API response.
  static const _driver = 'Yassine';
  static const _origin = 'Gare Marrakech';
  static const _destination = 'Campus';
  static const _fare = 15;
  static const _availableSeats = 2;
  static const _metrics = [
    ('Trajets', 12.0),
    ('Passagers', 31.0),
    ('Note', 4.8)
  ];

  late final DateTime _demoCountdownEnd;
  late final Timer _timer;
  final _clock = ValueNotifier(DateTime.now());

  late final _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1180),
  );
  late final _route = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 5),
  );

  bool? _reduceMotion;

  @override
  void initState() {
    super.initState();
    _demoCountdownEnd = _clock.value.add(const Duration(hours: 2, minutes: 14));
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _clock.value = DateTime.now();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (_reduceMotion == reduceMotion) return;
    _reduceMotion = reduceMotion;
    if (reduceMotion) {
      _entrance.value = 1;
      _route.stop();
    } else {
      _entrance.forward();
      _route.repeat();
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    _clock.dispose();
    _entrance.dispose();
    _route.dispose();
    super.dispose();
  }

  Widget _reveal(int index, Widget child) {
    final start = index * 80 / 1180;
    final progress = _entrance.drive(
      CurveTween(
          curve:
              Interval(start, start + 700 / 1180, curve: Curves.easeOutCubic)),
    );
    return FadeTransition(
      opacity: progress,
      child: SlideTransition(
        position: progress
            .drive(Tween(begin: const Offset(0, .15), end: Offset.zero)),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = driverTheme();
    final display = theme.textTheme.displayLarge!;
    return Theme(
      data: theme,
      child: Scaffold(
        backgroundColor: driverSurface,
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Stack(
              fit: StackFit.expand,
              children: [
                const Positioned.fill(
                    child: DecoratedBox(
                        decoration:
                            BoxDecoration(gradient: driverCanvasGradient))),
                SafeArea(
                  child: Builder(builder: (context) {
                    final text = Theme.of(context).textTheme;
                    final overview = widget.tripOverview;
                    final featured = overview?.featured;
                    final details = featured?.details;
                    final contribution = details?.contributionDh;
                    final price = overview == null
                        ? '$_fare DH / place'
                        : (contribution == null || contribution == 0
                            ? 'Gratuit'
                            : '$contribution DH / place');
                    final metrics = overview == null
                        ? _metrics
                        : [
                            ('À venir', overview.upcoming.toDouble()),
                            ('En cours', overview.inProgress.toDouble()),
                            ('Terminés', overview.completed.toDouble()),
                          ];
                    return Stack(
                      children: [
                        SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(
                              driverPageMargin, 24, driverPageMargin, 110),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _reveal(
                                  0,
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text('Salam, $_driver',
                                              style: text.bodySmall),
                                          const SizedBox(height: 4),
                                          const _Pill('Mode Driver',
                                              live: true),
                                        ],
                                      ),
                                      DriverAvatar('Y',
                                          photoUrl: widget.driverPhotoUrl,
                                          background: driverAccent,
                                          foreground: driverOnAccent),
                                    ],
                                  )),
                              const SizedBox(height: 24),
                              if (overview == null || featured != null) ...[
                                _reveal(
                                    2,
                                    ValueListenableBuilder<DateTime>(
                                      valueListenable: _clock,
                                      builder: (_, now, child) {
                                        if (featured != null &&
                                            !featured.isUpcoming(now)) {
                                          return Text(
                                              tripStatusLabel(featured, now),
                                              style: display.copyWith(
                                                  fontSize: 40));
                                        }
                                        final remaining =
                                            (details?.departureAt ??
                                                    _demoCountdownEnd)
                                                .difference(now);
                                        final duration = remaining.isNegative
                                            ? Duration.zero
                                            : remaining;
                                        final minutes =
                                            (duration.inMinutes % 60)
                                                .toString()
                                                .padLeft(2, '0');
                                        final seconds =
                                            (duration.inSeconds % 60)
                                                .toString()
                                                .padLeft(2, '0');
                                        return Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text('Ton prochain départ dans',
                                                style: text.bodyMedium),
                                            FittedBox(
                                              fit: BoxFit.scaleDown,
                                              alignment: Alignment.centerLeft,
                                              child: Text(
                                                '${duration.inHours}:$minutes:$seconds',
                                                style: display.copyWith(
                                                    fontSize: 64),
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    )),
                                const SizedBox(height: 18),
                                _reveal(
                                    3,
                                    DriverCard(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          Wrap(
                                            alignment:
                                                WrapAlignment.spaceBetween,
                                            crossAxisAlignment:
                                                WrapCrossAlignment.center,
                                            spacing: 8,
                                            runSpacing: 6,
                                            children: [
                                              _Pill(details == null
                                                  ? 'Demain · 08:00'
                                                  : tripDateLabel(
                                                      details.departureAt)),
                                              Text(price,
                                                  style: text.titleSmall
                                                      ?.copyWith(
                                                          fontWeight:
                                                              FontWeight.w800)),
                                            ],
                                          ),
                                          SizedBox(
                                            height: 84,
                                            child: CustomPaint(
                                                painter: _RoutePainter(_route)),
                                          ),
                                          Row(
                                            children: [
                                              Expanded(
                                                  child: Text(
                                                      details?.origin ??
                                                          _origin,
                                                      style: text.titleSmall
                                                          ?.copyWith(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w800))),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                  child: Text(
                                                      details?.destination ??
                                                          _destination,
                                                      textAlign: TextAlign.end,
                                                      style: text.titleSmall
                                                          ?.copyWith(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w800))),
                                            ],
                                          ),
                                          const SizedBox(height: 12),
                                          Wrap(
                                            alignment:
                                                WrapAlignment.spaceBetween,
                                            crossAxisAlignment:
                                                WrapCrossAlignment.center,
                                            spacing: 10,
                                            runSpacing: 6,
                                            children: [
                                              if (overview == null)
                                                SizedBox(
                                                  width: 62,
                                                  height: 36,
                                                  child: Stack(children: [
                                                    DriverAvatar('S',
                                                        photoUrl: widget
                                                            .firstRiderPhotoUrl,
                                                        background:
                                                            driverOutline),
                                                    Positioned(
                                                        left: 26,
                                                        child: DriverAvatar('O',
                                                            photoUrl: widget
                                                                .secondRiderPhotoUrl)),
                                                  ]),
                                                ),
                                              Text(
                                                  details == null
                                                      ? '$_availableSeats places libres'
                                                      : '${details.seats} place${details.seats == 1 ? '' : 's'} proposée${details.seats == 1 ? '' : 's'}',
                                                  style: text.bodySmall),
                                              if (widget.onTripDetails
                                                  case final openDetails?)
                                                FilledButton(
                                                  style: FilledButton.styleFrom(
                                                      backgroundColor:
                                                          driverAccent,
                                                      foregroundColor:
                                                          driverOnAccent),
                                                  onPressed: openDetails,
                                                  child: const Text(
                                                      'Voir le trajet'),
                                                ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    )),
                              ] else
                                const DriverCard(
                                    child: Text(
                                        'Aucun trajet prêt, à venir ou en cours')),
                              const SizedBox(height: driverSectionGap),
                              _reveal(
                                  4,
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      for (final (index, (label, value))
                                          in metrics.indexed)
                                        Expanded(
                                          child: Padding(
                                            padding: EdgeInsets.only(
                                                right:
                                                    index == metrics.length - 1
                                                        ? 0
                                                        : 8),
                                            child: _Metric(
                                                label: label,
                                                value: value,
                                                animate:
                                                    !(_reduceMotion ?? false)),
                                          ),
                                        ),
                                    ],
                                  )),
                              const SizedBox(height: 24),
                              _reveal(
                                  5,
                                  Text('Données de démonstration',
                                      style: text.bodySmall)),
                            ],
                          ),
                        ),
                        Positioned(
                          left: 12,
                          right: 12,
                          bottom: 14,
                          child: _BottomBar(
                              onPublish: widget.onPublish,
                              onProfile: widget.onProfile,
                              onTrips: widget.onTrips,
                              onVehicles: widget.onVehicles,
                              onRequests: widget.onRequests),
                        ),
                      ],
                    );
                  }),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric(
      {required this.label, required this.value, required this.animate});

  final String label;
  final double value;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return DriverCard(
      padding: 10,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: animate ? 0 : value, end: value),
            duration: Duration(milliseconds: animate ? 1300 : 0),
            curve: Curves.easeOutCubic,
            builder: (_, current, child) => Text(
              current
                  .toStringAsFixed(label == 'Note' ? 1 : 0)
                  .replaceAll('.', ','),
              style: text.headlineSmall
                  ?.copyWith(fontSize: 26, fontWeight: FontWeight.w800),
            ),
          ),
          Text(label, style: text.bodySmall),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill(this.label, {this.live = false});

  final String label;
  final bool live;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: driverHighlight),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (live) ...[
              const DecoratedBox(
                decoration: BoxDecoration(
                    color: driverHighlight, shape: BoxShape.circle),
                child: SizedBox.square(dimension: 7),
              ),
              const SizedBox(width: 6),
            ],
            Flexible(
                child: Text(label,
                    style: Theme.of(context)
                        .textTheme
                        .labelSmall
                        ?.copyWith(fontWeight: FontWeight.w600))),
          ],
        ),
      );
}

class _BottomBar extends StatelessWidget {
  const _BottomBar(
      {this.onPublish,
      this.onProfile,
      this.onTrips,
      this.onVehicles,
      this.onRequests});

  final VoidCallback? onPublish;
  final VoidCallback? onProfile;
  final VoidCallback? onTrips;
  final VoidCallback? onVehicles;
  final VoidCallback? onRequests;

  @override
  Widget build(BuildContext context) => Stack(
        alignment: Alignment.bottomCenter,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                height: 62,
                decoration: BoxDecoration(
                  color: driverFrostedSurface.withValues(alpha: .85),
                  border:
                      Border.all(color: driverOutline.withValues(alpha: .80)),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  children: [
                    const _BarItem(
                        icon: Icons.home_outlined,
                        label: 'Accueil',
                        selected: true),
                    _BarItem(
                        icon: Icons.alt_route_outlined,
                        label: 'Trajets',
                        onTap: onTrips),
                    const Spacer(),
                    if (onRequests != null)
                      _BarItem(
                          icon: Icons.inbox_outlined,
                          label: 'Demandes',
                          onTap: onRequests),
                    _BarItem(
                        icon: onVehicles == null
                            ? Icons.person_outline
                            : Icons.directions_car_outlined,
                        label: onVehicles == null ? 'Profil' : 'Véhicules',
                        onTap: onVehicles ?? onProfile),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 34),
            child: IconButton(
              onPressed: onPublish,
              tooltip: 'Publier un trajet',
              style: IconButton.styleFrom(
                fixedSize: const Size.square(46),
                backgroundColor: driverAccent,
                disabledBackgroundColor: driverAccent,
                foregroundColor: driverOnAccent,
                disabledForegroundColor: driverSurface.withValues(alpha: .72),
              ),
              icon: const Icon(Icons.add),
            ),
          ),
        ],
      );
}

class _BarItem extends StatelessWidget {
  const _BarItem(
      {required this.icon,
      required this.label,
      this.selected = false,
      this.onTap});

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Expanded(
        child: Semantics(
          selected: selected,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(30),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon,
                    size: 20,
                    color: selected
                        ? driverText
                        : driverText.withValues(alpha: .55)),
                const SizedBox(height: 2),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(label,
                        maxLines: 1,
                        style: Theme.of(context).textTheme.labelSmall),
                  ),
                ),
                const SizedBox(height: 3),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 450),
                  width: selected ? 16 : 0,
                  height: 3,
                  decoration: BoxDecoration(
                      color: driverHighlight,
                      borderRadius: BorderRadius.circular(3)),
                ),
              ],
            ),
          ),
        ),
      );
}

class _RoutePainter extends CustomPainter {
  _RoutePainter(this.progress) : super(repaint: progress);

  final Animation<double> progress;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(0, size.height / 2 - 42);
    canvas.scale(size.width / 300, 1);
    final path = Path()
      ..moveTo(14, 62)
      ..cubicTo(70, 80, 100, 8, 160, 36)
      ..cubicTo(220, 64, 250, 70, 288, 18);
    final metric = path.computeMetrics().single;
    final stroke = Paint()
      ..color = driverAccent
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.5;
    for (double start = progress.value * 26 - 26;
        start < metric.length;
        start += 13) {
      canvas.drawPath(
          metric.extractPath(start.clamp(0.0, metric.length),
              (start + 6).clamp(0.0, metric.length)),
          stroke);
    }
    canvas.drawCircle(const Offset(14, 62), 6, Paint()..color = driverSurface);
    canvas.drawCircle(const Offset(14, 62), 6, stroke);
    canvas.drawCircle(
        const Offset(288, 18), 7, Paint()..color = driverHighlight);
    canvas.drawCircle(const Offset(288, 18), 7, stroke);
    final point = metric.getTangentForOffset(metric.length * progress.value);
    if (point != null) {
      canvas.drawCircle(point.position, 5, Paint()..color = driverAccent);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_RoutePainter oldDelegate) =>
      oldDelegate.progress != progress;
}
