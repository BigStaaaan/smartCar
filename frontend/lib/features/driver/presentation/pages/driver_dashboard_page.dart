import 'dart:async';
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../trips/domain/entities/trip.dart';
import '../../../trips/presentation/pages/trip_details_page.dart';
import '../widgets/driver_avatar.dart';

const _cream = Color(0xffeee7d7);
const _ink = Color(0xff232715);
const _olive = Color(0xff4f5330);
const _teal = Color(0xff8ccfc9);
const _blue = Color(0xffb7c8e0);

/// An isolated Driver screen. Callbacks can be wired by the host when ready.
class DriverDashboardPage extends StatefulWidget {
  const DriverDashboardPage({
    super.key,
    this.onPublish,
    this.onTripDetails,
    this.onProfile,
    this.onTrips,
    this.onVehicles,
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
  late final _ambient = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 14),
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
      _ambient.stop();
    } else {
      _entrance.forward();
      _route.repeat();
      _ambient.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    _clock.dispose();
    _entrance.dispose();
    _route.dispose();
    _ambient.dispose();
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
    final baseTheme = Theme.of(context);
    final display = GoogleFonts.instrumentSerif(color: _ink, height: .95);
    return Theme(
      data: baseTheme.copyWith(
        colorScheme: ColorScheme.fromSeed(seedColor: _olive, surface: _cream),
        textTheme: baseTheme.textTheme.copyWith(
          bodySmall: GoogleFonts.bricolageGrotesque(
              textStyle: baseTheme.textTheme.bodySmall, color: _ink),
          bodyMedium: GoogleFonts.bricolageGrotesque(
              textStyle: baseTheme.textTheme.bodyMedium, color: _ink),
          labelSmall: GoogleFonts.bricolageGrotesque(
              textStyle: baseTheme.textTheme.labelSmall,
              color: _ink,
              fontWeight: FontWeight.w600),
          labelLarge: GoogleFonts.bricolageGrotesque(
              textStyle: baseTheme.textTheme.labelLarge,
              fontWeight: FontWeight.w600),
          titleSmall: GoogleFonts.bricolageGrotesque(
              textStyle: baseTheme.textTheme.titleSmall,
              color: _ink,
              fontWeight: FontWeight.w800),
          headlineSmall: GoogleFonts.bricolageGrotesque(
              textStyle: baseTheme.textTheme.headlineSmall,
              color: _ink,
              fontWeight: FontWeight.w800),
        ),
      ),
      child: Scaffold(
        backgroundColor: _cream,
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Stack(
              fit: StackFit.expand,
              children: [
                IgnorePointer(
                  child: AnimatedBuilder(
                    animation: _ambient,
                    builder: (_, child) => Transform.translate(
                      offset: Offset(-30 * _ambient.value, 40 * _ambient.value),
                      child: child,
                    ),
                    child: const Stack(
                      fit: StackFit.expand,
                      children: [
                        Positioned(
                            top: -70,
                            right: -60,
                            child: _Halo(color: _teal, size: 240)),
                        Positioned(
                            bottom: 60,
                            left: -80,
                            child: _Halo(color: _blue, size: 220)),
                      ],
                    ),
                  ),
                ),
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
                        ListView(
                          padding: const EdgeInsets.fromLTRB(18, 22, 18, 110),
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
                                        const _Pill('Mode Driver', live: true),
                                      ],
                                    ),
                                    DriverAvatar('Y',
                                        photoUrl: widget.driverPhotoUrl,
                                        background: _olive,
                                        foreground: _cream),
                                  ],
                                )),
                            const SizedBox(height: 20),
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
                                            style:
                                                display.copyWith(fontSize: 46));
                                      }
                                      final remaining = (details?.departureAt ??
                                              _demoCountdownEnd)
                                          .difference(now);
                                      final duration = remaining.isNegative
                                          ? Duration.zero
                                          : remaining;
                                      final minutes = (duration.inMinutes % 60)
                                          .toString()
                                          .padLeft(2, '0');
                                      final seconds = (duration.inSeconds % 60)
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
                                                  fontSize: 84),
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  )),
                              const SizedBox(height: 18),
                              _reveal(
                                  3,
                                  _Card(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        Wrap(
                                          alignment: WrapAlignment.spaceBetween,
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
                                                    details?.origin ?? _origin,
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
                                          alignment: WrapAlignment.spaceBetween,
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
                                                      background: _blue),
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
                                                    backgroundColor: _olive,
                                                    foregroundColor: _cream),
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
                              const _Card(
                                  child: Text(
                                      'Aucun trajet prêt, à venir ou en cours')),
                            const SizedBox(height: 14),
                            _reveal(
                                4,
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    for (final (index, (label, value))
                                        in metrics.indexed)
                                      Expanded(
                                        child: Padding(
                                          padding: EdgeInsets.only(
                                              right: index == metrics.length - 1
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
                            const SizedBox(height: 20),
                            _reveal(
                                5,
                                Text('Données de démonstration',
                                    style: text.bodySmall)),
                          ],
                        ),
                        Positioned(
                          left: 12,
                          right: 12,
                          bottom: 14,
                          child: _BottomBar(
                              onPublish: widget.onPublish,
                              onProfile: widget.onProfile,
                              onTrips: widget.onTrips,
                              onVehicles: widget.onVehicles),
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

class _Halo extends StatelessWidget {
  const _Halo({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox.square(
        dimension: size,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(colors: [
              color.withValues(alpha: .62),
              color.withValues(alpha: 0)
            ]),
          ),
        ),
      );
}

class _Card extends StatelessWidget {
  const _Card({required this.child, this.padding = 14});

  final Widget child;
  final double padding;

  @override
  Widget build(BuildContext context) => Container(
        padding: EdgeInsets.all(padding),
        decoration: BoxDecoration(
          color: _blue.withValues(alpha: .24),
          border: Border.all(color: _blue.withValues(alpha: .70)),
          borderRadius: BorderRadius.circular(22),
        ),
        child: child,
      );
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
    return _Card(
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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          border: Border.all(color: _teal),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (live) ...[
              const DecoratedBox(
                decoration: BoxDecoration(color: _teal, shape: BoxShape.circle),
                child: SizedBox.square(dimension: 7),
              ),
              const SizedBox(width: 6),
            ],
            Text(label,
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(fontWeight: FontWeight.w600)),
          ],
        ),
      );
}

class _BottomBar extends StatelessWidget {
  const _BottomBar(
      {this.onPublish, this.onProfile, this.onTrips, this.onVehicles});

  final VoidCallback? onPublish;
  final VoidCallback? onProfile;
  final VoidCallback? onTrips;
  final VoidCallback? onVehicles;

  @override
  Widget build(BuildContext context) => Stack(
        alignment: Alignment.bottomCenter,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
              child: Container(
                height: 62,
                decoration: BoxDecoration(
                  color: _cream.withValues(alpha: .88),
                  border: Border.all(color: _blue.withValues(alpha: .80)),
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
                backgroundColor: _olive,
                disabledBackgroundColor: _olive,
                foregroundColor: _cream,
                disabledForegroundColor: _cream.withValues(alpha: .72),
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
                    color: selected ? _ink : _ink.withValues(alpha: .55)),
                const SizedBox(height: 2),
                Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall),
                const SizedBox(height: 3),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 450),
                  width: selected ? 16 : 0,
                  height: 3,
                  decoration: BoxDecoration(
                      color: _teal, borderRadius: BorderRadius.circular(3)),
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
      ..color = _olive
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
    canvas.drawCircle(const Offset(14, 62), 6, Paint()..color = _cream);
    canvas.drawCircle(const Offset(14, 62), 6, stroke);
    canvas.drawCircle(const Offset(288, 18), 7, Paint()..color = _teal);
    canvas.drawCircle(const Offset(288, 18), 7, stroke);
    final point = metric.getTangentForOffset(metric.length * progress.value);
    if (point != null) {
      canvas.drawCircle(point.position, 5, Paint()..color = _olive);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_RoutePainter oldDelegate) =>
      oldDelegate.progress != progress;
}
