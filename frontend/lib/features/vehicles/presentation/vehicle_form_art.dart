import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'vehicle_theme.dart';

class VehicleScanFrame extends StatefulWidget {
  const VehicleScanFrame({super.key});

  @override
  State<VehicleScanFrame> createState() => _VehicleScanFrameState();
}

class _VehicleScanFrameState extends State<VehicleScanFrame>
    with SingleTickerProviderStateMixin {
  late final _progress = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _progress.stop();
      _progress.value = .5;
    } else if (!_progress.isAnimating) {
      _progress.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _progress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _progress,
        builder: (context, child) => CustomPaint(
          painter: _ScanPainter(Curves.easeInOut.transform(_progress.value)),
          child: child,
        ),
        child: const Center(
          child: Text('Préparation de l’image…', textAlign: TextAlign.center),
        ),
      );
}

class VehicleDashedFrame extends StatelessWidget {
  const VehicleDashedFrame({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => CustomPaint(
        painter: const _ScanPainter(null),
        child: child,
      );
}

class _ScanPainter extends CustomPainter {
  const _ScanPainter(this.progress);

  final double? progress;

  @override
  void paint(Canvas canvas, Size size) {
    final frame = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(1, 1, size.width - 2, size.height - 2),
        const Radius.circular(16),
      ));
    final dash = Paint()
      ..color = driverHighlight
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final metric = frame.computeMetrics().single;
    for (double i = 0; i < metric.length; i += 11) {
      canvas.drawPath(
          metric.extractPath(i, math.min(i + 6, metric.length)), dash);
    }
    final scan = progress;
    if (scan == null) return;
    final y = 14 + (size.height - 28) * scan;
    final line = Path()
      ..moveTo(15, y)
      ..lineTo(size.width - 15, y);
    canvas.drawPath(
      line,
      Paint()
        ..color = driverHighlight.withValues(alpha: .72)
        ..strokeWidth = 8
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5)
        ..style = PaintingStyle.stroke,
    );
    canvas.drawPath(line, dash..strokeWidth = 3);
  }

  @override
  bool shouldRepaint(_ScanPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class VehicleSaveCheck extends StatelessWidget {
  const VehicleSaveCheck({super.key});

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 1150),
        builder: (context, progress, child) => CustomPaint(
          size: const Size.square(112),
          painter: _CheckPainter(progress),
        ),
      );
}

class _CheckPainter extends CustomPainter {
  const _CheckPainter(this.progress);

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final pen = Paint()
      ..color = driverHighlight
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawArc(Rect.fromCircle(center: center, radius: 49), -math.pi / 2,
        2 * math.pi * (progress / .72).clamp(0.0, 1.0), false, pen);
    final check = Path()
      ..moveTo(center.dx - 20, center.dy + 1)
      ..lineTo(center.dx - 6, center.dy + 15)
      ..lineTo(center.dx + 22, center.dy - 15);
    final line = check.computeMetrics().single;
    final fraction = ((progress - .55) / .45).clamp(0.0, 1.0);
    canvas.drawPath(
        line.extractPath(0, line.length * fraction), pen..color = driverAccent);
  }

  @override
  bool shouldRepaint(_CheckPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
