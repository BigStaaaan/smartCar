import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';

class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final illustrationHeight = (constraints.maxHeight * 0.43).clamp(
              240.0,
              360.0,
            );

            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(24, 18, 24, 24 + bottomInset),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 42,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _BrandMark(),
                    const SizedBox(height: 18),
                    SizedBox(
                      height: illustrationHeight,
                      child: const _WelcomeIllustration(),
                    ),
                    const SizedBox(height: 22),
                    const _PageIndicator(),
                    const SizedBox(height: 26),
                    Text(
                      'Chaque trajet compte',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.displaySmall?.copyWith(
                        fontSize: 30,
                        height: 1.08,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Partagez vos trajets entre membres de l’UIZ, '
                      'simplement et en toute confiance.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: AppColors.charcoal.withValues(alpha: 0.7),
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 28),
                    ElevatedButton(
                      onPressed: () {},
                      child: const Text('Commencer'),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.alt_route_rounded,
            color: Colors.white,
            size: 21,
          ),
        ),
        const SizedBox(width: 9),
        const Text(
          'SmartCar',
          style: TextStyle(
            color: AppColors.charcoal,
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 23,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.8,
          ),
        ),
      ],
    );
  }
}

class _PageIndicator extends StatelessWidget {
  const _PageIndicator();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 34,
          height: 6,
          decoration: const ShapeDecoration(
            color: AppColors.primary,
            shape: StadiumBorder(),
          ),
        ),
        const SizedBox(width: 8),
        ...List.generate(
          2,
          (_) => Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Container(
              width: 25,
              height: 6,
              decoration: const ShapeDecoration(
                color: AppColors.border,
                shape: StadiumBorder(),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _WelcomeIllustration extends StatelessWidget {
  const _WelcomeIllustration();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _WelcomeIllustrationPainter(),
      child: const SizedBox.expand(),
    );
  }
}

class _WelcomeIllustrationPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 342;
    canvas.save();
    canvas.scale(scale, scale);
    final width = size.width / scale;
    final height = size.height / scale;

    final parkPaint = Paint()..color = AppColors.illustrationBlue;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(width / 2, height * 0.48),
        width: 300,
        height: 210,
      ),
      parkPaint,
    );

    final roadPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.82)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    final route = Path()
      ..moveTo(48, height * 0.62)
      ..cubicTo(95, height * 0.47, 150, height * 0.72, 198, height * 0.49)
      ..cubicTo(234, height * 0.32, 262, height * 0.4, 298, height * 0.28);
    canvas.drawPath(route, roadPaint);

    final routeAccent = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    final accentRoute = Path()
      ..moveTo(54, height * 0.6)
      ..cubicTo(92, height * 0.49, 142, height * 0.66, 184, height * 0.5)
      ..cubicTo(210, height * 0.4, 230, height * 0.41, 254, height * 0.33);
    canvas.drawPath(accentRoute, routeAccent);

    _drawTrees(canvas, height);
    _drawPhone(canvas, height);
    _drawCar(canvas, height);

    final pinPaint = Paint()..color = AppColors.darkBlue;
    canvas.drawCircle(Offset(214, height * 0.43), 7, pinPaint);
    canvas.drawCircle(
      Offset(214, height * 0.43),
      3,
      Paint()..color = Colors.white,
    );

    canvas.restore();
  }

  void _drawTrees(Canvas canvas, double height) {
    final trunk = Paint()..color = const Color(0xFF7DB9D9);
    final leaves = Paint()..color = const Color(0xFF8DD2B8);
    for (final x in [46.0, 82.0, 282.0, 310.0]) {
      canvas.drawRect(
        Rect.fromLTWH(x - 2, height * 0.45, 4, height * 0.22),
        trunk,
      );
      canvas.drawCircle(Offset(x, height * 0.42), 16, leaves);
      canvas.drawCircle(Offset(x - 10, height * 0.46), 12, leaves);
      canvas.drawCircle(Offset(x + 10, height * 0.46), 12, leaves);
    }
  }

  void _drawPhone(Canvas canvas, double height) {
    final phone = RRect.fromRectAndRadius(
      Rect.fromLTWH(116, height * 0.08, 112, height * 0.6),
      const Radius.circular(20),
    );
    canvas.drawRRect(phone, Paint()..color = AppColors.charcoal);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(122, height * 0.105, 100, height * 0.55),
        const Radius.circular(15),
      ),
      Paint()..color = const Color(0xFFEAF7FF),
    );

    final map = Paint()..color = const Color(0xFFB8E3F8);
    canvas.drawRect(Rect.fromLTWH(122, height * 0.16, 100, height * 0.3), map);
    final mapLine = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..strokeWidth = 2;
    for (var i = 0; i < 4; i++) {
      canvas.drawLine(
        Offset(120 + i * 27, height * 0.16),
        Offset(150 + i * 20, height * 0.46),
        mapLine,
      );
    }
    canvas.drawCircle(
      Offset(180, height * 0.31),
      10,
      Paint()..color = AppColors.primary,
    );
    canvas.drawCircle(
      Offset(180, height * 0.31),
      4,
      Paint()..color = Colors.white,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(122, height * 0.46, 100, height * 0.2),
        const Radius.circular(15),
      ),
      Paint()..color = Colors.white,
    );
    canvas.drawRect(
      Rect.fromLTWH(134, height * 0.51, 53, 5),
      Paint()..color = AppColors.charcoal.withValues(alpha: 0.2),
    );
    canvas.drawRect(
      Rect.fromLTWH(134, height * 0.56, 35, 5),
      Paint()..color = AppColors.primary.withValues(alpha: 0.45),
    );
  }

  void _drawCar(Canvas canvas, double height) {
    final carPaint = Paint()..color = Colors.white;
    final windowPaint = Paint()
      ..color = AppColors.darkBlue.withValues(alpha: 0.85);
    final outline = Paint()
      ..color = AppColors.charcoal
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final body = Path()
      ..moveTo(190, height * 0.79)
      ..quadraticBezierTo(198, height * 0.68, 220, height * 0.68)
      ..lineTo(245, height * 0.68)
      ..quadraticBezierTo(260, height * 0.68, 273, height * 0.78)
      ..lineTo(292, height * 0.81)
      ..quadraticBezierTo(298, height * 0.83, 296, height * 0.88)
      ..lineTo(190, height * 0.88)
      ..close();
    canvas.drawPath(body, carPaint);
    canvas.drawPath(body, outline);
    canvas.drawPath(
      Path()
        ..moveTo(220, height * 0.69)
        ..lineTo(234, height * 0.69)
        ..lineTo(243, height * 0.78)
        ..lineTo(216, height * 0.78)
        ..close(),
      windowPaint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(238, height * 0.69)
        ..lineTo(248, height * 0.7)
        ..quadraticBezierTo(259, height * 0.72, 268, height * 0.78)
        ..lineTo(246, height * 0.78)
        ..close(),
      windowPaint,
    );
    for (final x in [210.0, 272.0]) {
      canvas.drawCircle(
        Offset(x, height * 0.88),
        9,
        Paint()..color = AppColors.charcoal,
      );
      canvas.drawCircle(
        Offset(x, height * 0.88),
        4,
        Paint()..color = AppColors.border,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
