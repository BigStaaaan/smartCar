import 'package:flutter/material.dart';

import '../../../vehicles/presentation/vehicle_theme.dart';

class TripNote extends StatelessWidget {
  const TripNote(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: Theme.of(context).textTheme.labelSmall,
      );
}

class TripPill extends StatelessWidget {
  const TripPill(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: driverHighlight),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          child: Text(text,
              style:
                  const TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
        ),
      );
}

class TripCircleButton extends StatelessWidget {
  const TripCircleButton(
      {super.key, required this.tooltip, this.onPressed, required this.child});
  final String tooltip;
  final VoidCallback? onPressed;
  final Widget child;

  @override
  Widget build(BuildContext context) => TripPress(
        amount: .90,
        child: Tooltip(
          message: tooltip,
          child: OutlinedButton(
            onPressed: onPressed,
            style: OutlinedButton.styleFrom(
              foregroundColor: driverText,
              fixedSize: const Size.square(38),
              minimumSize: Size.zero,
              padding: EdgeInsets.zero,
              side: const BorderSide(color: driverHighlight, width: 1.5),
              shape: const CircleBorder(),
            ),
            child: child,
          ),
        ),
      );
}

class TripDaySegment extends StatelessWidget {
  const TripDaySegment(
      {super.key, required this.selected, required this.onSelected});
  final int? selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) => Container(
        width: 126,
        height: 34,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          border: Border.all(color: driverHighlight),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            AnimatedAlign(
              duration: MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero
                  : const Duration(milliseconds: 400),
              curve: Curves.easeOutBack,
              alignment:
                  selected == 1 ? Alignment.centerRight : Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: .5,
                heightFactor: 1,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color:
                        selected == null ? Colors.transparent : driverHighlight,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            ),
            Row(children: [
              for (final (index, label) in ['Auj.', 'Demain'].indexed)
                Expanded(
                  child: Semantics(
                    button: true,
                    selected: selected == index,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(999),
                      onTap: () => onSelected(index),
                      child: Center(
                          child: Text(label,
                              style: const TextStyle(
                                  fontSize: 11, fontWeight: FontWeight.w700))),
                    ),
                  ),
                ),
            ]),
          ],
        ),
      );
}

class TripSeat extends StatelessWidget {
  const TripSeat(
      {super.key,
      required this.count,
      required this.filled,
      required this.selected,
      this.onPressed});
  final int count;
  final bool filled;
  final bool selected;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        key: ValueKey(selected),
        tween: Tween(begin: 0, end: 1),
        duration: selected && !MediaQuery.disableAnimationsOf(context)
            ? const Duration(milliseconds: 400)
            : Duration.zero,
        builder: (_, value, child) => Transform.scale(
          scale: 1 + .18 * (1 - (2 * value - 1).abs()),
          child: child,
        ),
        child: Semantics(
          selected: selected,
          child: OutlinedButton(
            onPressed: onPressed,
            style: OutlinedButton.styleFrom(
              minimumSize: Size.zero,
              fixedSize: const Size.square(46),
              padding: EdgeInsets.zero,
              backgroundColor: filled ? driverAccent : Colors.transparent,
              foregroundColor: filled ? driverOnAccent : driverText,
              side: BorderSide(
                  color: filled ? driverAccent : driverHighlight, width: 1.5),
              shape: const CircleBorder(),
              textStyle: const TextStyle(fontWeight: FontWeight.w800),
            ),
            child: Text('$count'),
          ),
        ),
      );
}

class TripSliderThumb extends SliderComponentShape {
  const TripSliderThumb();
  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) =>
      const Size.square(28);

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final canvas = context.canvas;
    canvas.drawCircle(center, 14, Paint()..color = driverAccent);
    canvas.drawCircle(center, 13, Paint()..color = driverSurface);
    canvas.drawCircle(center, 9, Paint()..color = driverAccent);
  }
}

class TripPress extends StatefulWidget {
  const TripPress({super.key, required this.child, this.amount = .96});
  final Widget child;
  final double amount;

  @override
  State<TripPress> createState() => _TripPressState();
}

class _TripPressState extends State<TripPress> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) => Listener(
        onPointerDown: (_) => setState(() => _pressed = true),
        onPointerUp: (_) => setState(() => _pressed = false),
        onPointerCancel: (_) => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: _pressed ? widget.amount : 1,
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 200),
          child: widget.child,
        ),
      );
}

class TripHalo extends StatelessWidget {
  const TripHalo({super.key, required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: SizedBox.square(
          dimension: 240,
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                color.withValues(alpha: .55),
                color.withValues(alpha: 0)
              ]),
            ),
          ),
        ),
      );
}

class TripVehicleDrawing extends StatelessWidget {
  const TripVehicleDrawing({super.key});

  @override
  Widget build(BuildContext context) =>
      const CustomPaint(painter: _VehiclePainter());
}

class _VehiclePainter extends CustomPainter {
  const _VehiclePainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.translate(0, (size.height - size.width * .45) / 2);
    canvas.scale(size.width / 200);
    final route = Path()
      ..moveTo(8, 60)
      ..quadraticBezierTo(8, 48, 22, 46)
      ..lineTo(52, 44)
      ..lineTo(72, 24)
      ..quadraticBezierTo(76, 20, 84, 20)
      ..lineTo(128, 20)
      ..quadraticBezierTo(136, 20, 142, 26)
      ..lineTo(162, 44)
      ..quadraticBezierTo(190, 46, 192, 60)
      ..lineTo(192, 68)
      ..lineTo(8, 68)
      ..close();
    final outline = Paint()
      ..color = driverText
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawPath(route, Paint()..color = driverSurface);
    canvas.drawPath(route, outline);
    final windows = Path()
      ..moveTo(62, 44)
      ..lineTo(78, 28)
      ..lineTo(100, 28)
      ..lineTo(100, 44)
      ..close()
      ..moveTo(106, 44)
      ..lineTo(106, 28)
      ..lineTo(128, 28)
      ..lineTo(144, 44)
      ..close();
    canvas.drawPath(windows, Paint()..color = driverOutline);
    canvas.drawPath(windows, outline);
    for (final x in [52.0, 150.0]) {
      canvas.drawCircle(Offset(x, 68), 13, Paint()..color = driverText);
      canvas.drawCircle(Offset(x, 68), 5, Paint()..color = driverHighlight);
    }
  }

  @override
  bool shouldRepaint(_VehiclePainter oldDelegate) => false;
}
