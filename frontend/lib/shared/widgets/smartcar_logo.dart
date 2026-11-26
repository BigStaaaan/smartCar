import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';

enum SmartCarLogoVariant {
  primary,
  horizontal,
  iconOnly,
  monochromeWhite,
  monochromeDark,
}

/// Reusable SmartCar brand logo widget.
/// Renders the unified geometric symbol (navigation pin + car silhouette + route arc)
/// and wordmark using the project's Kinetic Campus design tokens.
class SmartCarLogo extends StatelessWidget {
  final SmartCarLogoVariant variant;
  final double symbolSize;
  final double wordmarkFontSize;

  const SmartCarLogo({
    super.key,
    this.variant = SmartCarLogoVariant.primary,
    this.symbolSize = 84,
    this.wordmarkFontSize = 30,
  });

  @override
  Widget build(BuildContext context) {
    final symbol = Semantics(
      label: 'SmartCar logo',
      image: true,
      child: CustomPaint(
        size: Size.square(symbolSize),
        painter: _SmartCarSymbolPainter(variant: variant),
      ),
    );

    if (variant == SmartCarLogoVariant.iconOnly) {
      return symbol;
    }

    final wordmark = _buildWordmark();

    if (variant == SmartCarLogoVariant.horizontal) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          symbol,
          SizedBox(width: symbolSize * 0.22),
          wordmark,
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        symbol,
        SizedBox(height: symbolSize * 0.16),
        wordmark,
      ],
    );
  }

  Widget _buildWordmark() {
    final isWhite = variant == SmartCarLogoVariant.monochromeWhite;
    final isDark = variant == SmartCarLogoVariant.monochromeDark;

    final baseStyle = AppTypography.displayLg.copyWith(
      fontSize: wordmarkFontSize,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.8,
      height: 1.1,
    );

    if (isWhite) {
      return Text('SmartCar', style: baseStyle.copyWith(color: Colors.white));
    }
    if (isDark) {
      return Text(
        'SmartCar',
        style: baseStyle.copyWith(color: AppColors.onSurface),
      );
    }

    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: 'Smart',
            style: baseStyle.copyWith(color: AppColors.onSurface),
          ),
          TextSpan(
            text: 'Car',
            style: baseStyle.copyWith(color: AppColors.secondary),
          ),
        ],
      ),
    );
  }
}

class _SmartCarSymbolPainter extends CustomPainter {
  final SmartCarLogoVariant variant;

  const _SmartCarSymbolPainter({required this.variant});

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 128.0;
    canvas.save();
    canvas.scale(scale, scale);

    final Color pinColor;
    final Color carColor;
    final Color windshieldColor;
    final Color routeColor;

    switch (variant) {
      case SmartCarLogoVariant.monochromeWhite:
        pinColor = Colors.white;
        carColor = AppColors.secondary;
        windshieldColor = Colors.white;
        routeColor = AppColors.secondary;
      case SmartCarLogoVariant.monochromeDark:
        pinColor = AppColors.onSurface;
        carColor = Colors.white;
        windshieldColor = AppColors.onSurface;
        routeColor = Colors.white;
      case SmartCarLogoVariant.primary:
      case SmartCarLogoVariant.horizontal:
      case SmartCarLogoVariant.iconOnly:
        pinColor = AppColors.secondary;
        carColor = Colors.white;
        windshieldColor = AppColors.primary;
        routeColor = AppColors.inversePrimary;
    }

    // 1. Navigation / location pin body
    final pinPath = Path()
      ..moveTo(64, 12)
      ..cubicTo(40.804, 12, 22, 30.804, 22, 54)
      ..cubicTo(22, 79.5, 52.5, 106.2, 61.2, 113.6)
      ..cubicTo(62.8, 115, 65.2, 115, 66.8, 113.6)
      ..cubicTo(75.5, 106.2, 106, 79.5, 106, 54)
      ..cubicTo(106, 30.804, 87.196, 12, 64, 12)
      ..close();
    canvas.drawPath(pinPath, Paint()..color = pinColor);

    // 2. Simplified geometric car silhouette
    final carPath = Path()
      ..moveTo(40, 58)
      ..lineTo(45.5, 43.5)
      ..cubicTo(46.7, 40.2, 49.8, 38, 53.3, 38)
      ..lineTo(74.7, 38)
      ..cubicTo(78.2, 38, 81.3, 40.2, 82.5, 43.5)
      ..lineTo(88, 58)
      ..lineTo(88, 67)
      ..cubicTo(88, 68.7, 86.7, 70, 85, 70)
      ..lineTo(81, 70)
      ..cubicTo(79.3, 70, 78, 68.7, 78, 67)
      ..lineTo(78, 65)
      ..lineTo(50, 65)
      ..lineTo(50, 67)
      ..cubicTo(50, 68.7, 48.7, 70, 47, 70)
      ..lineTo(43, 70)
      ..cubicTo(41.3, 70, 40, 68.7, 40, 67)
      ..close();
    canvas.drawPath(carPath, Paint()..color = carColor);

    // 3. Windshield
    final windshieldPath = Path()
      ..moveTo(48, 52)
      ..lineTo(51.2, 43.5)
      ..lineTo(76.8, 43.5)
      ..lineTo(80, 52)
      ..close();
    canvas.drawPath(windshieldPath, Paint()..color = windshieldColor);

    // 4. Route / connectivity arc
    final routePath = Path()
      ..moveTo(44, 79)
      ..cubicTo(53, 84, 75, 84, 84, 79);
    canvas.drawPath(
      routePath,
      Paint()
        ..color = routeColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SmartCarSymbolPainter oldDelegate) =>
      oldDelegate.variant != variant;
}
