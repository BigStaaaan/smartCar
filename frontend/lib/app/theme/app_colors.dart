import 'package:flutter/material.dart';

/// Kinetic Campus Design System Color Tokens (from DESIGN.md)
abstract final class AppColors {
  // Brand & Accent Colors
  static const primary = Color(0xFF5352B7);
  static const onPrimary = Color(0xFFFFFFFF);
  static const primaryContainer = Color(0xFF8C8CF5);
  static const onPrimaryContainer = Color(0xFF211C86);
  static const inversePrimary = Color(0xFFC2C1FF);

  static const secondary = Color(0xFF3A3FE5);
  static const onSecondary = Color(0xFFFFFFFF);
  static const secondaryContainer = Color(0xFF565CFE);
  static const onSecondaryContainer = Color(0xFFFAF7FF);

  static const tertiary = Color(0xFF5A5B83);
  static const onTertiary = Color(0xFFFFFFFF);
  static const tertiaryContainer = Color(0xFF9393BE);
  static const onTertiaryContainer = Color(0xFF2A2C50);

  // Surfaces & Backgrounds
  static const background = Color(0xFFFBF8FF);
  static const onBackground = Color(0xFF1B1B20);
  static const surface = Color(0xFFFBF8FF);
  static const onSurface = Color(0xFF1B1B20);
  static const onSurfaceVariant = Color(0xFF464552);

  static const surfaceDim = Color(0xFFDCD9E0);
  static const surfaceBright = Color(0xFFFBF8FF);
  static const surfaceContainerLowest = Color(0xFFFFFFFF);
  static const surfaceContainerLow = Color(0xFFF6F2FA);
  static const surfaceContainer = Color(0xFFF0ECF4);
  static const surfaceContainerHigh = Color(0xFFEAE7EE);
  static const surfaceContainerHighest = Color(0xFFE4E1E9);
  static const surfaceVariant = Color(0xFFE4E1E9);

  // Inverse Surfaces
  static const inverseSurface = Color(0xFF303035);
  static const inverseOnSurface = Color(0xFFF3EFF7);

  // Outlines & Borders
  static const outline = Color(0xFF777684);
  static const outlineVariant = Color(0xFFC7C5D4);
  static const surfaceStroke = Color(0xFFDAD8E3);

  // Status & Error
  static const error = Color(0xFFBA1A1A);
  static const onError = Color(0xFFFFFFFF);
  static const errorContainer = Color(0xFFFFDAD6);
  static const onErrorContainer = Color(0xFF93000A);
  static const success = Color(0xFF22C55E);
  static const warning = Color(0xFFF59E0B);

  // Fixed Tonal Colors
  static const primaryFixed = Color(0xFFE2DFFF);
  static const primaryFixedDim = Color(0xFFC2C1FF);
  static const onPrimaryFixed = Color(0xFF0B006B);
  static const onPrimaryFixedVariant = Color(0xFF3A399E);

  static const secondaryFixed = Color(0xFFE1E0FF);
  static const secondaryFixedDim = Color(0xFFBFC1FF);
  static const onSecondaryFixed = Color(0xFF03006D);
  static const onSecondaryFixedVariant = Color(0xFF2223D3);

  static const tertiaryFixed = Color(0xFFE1E0FF);
  static const tertiaryFixedDim = Color(0xFFC3C3F0);
  static const onTertiaryFixed = Color(0xFF16183B);
  static const onTertiaryFixedVariant = Color(0xFF424369);

  // Canvas Mobile Gradient
  static const canvasGradientTop = Color(0xFFB7ACEB);
  static const canvasGradientMid = Color(0xFFE6E1F8);
  static const canvasGradientBottom = Color(0xFFF7F5FD);

  // Aliases for onboarding & components
  static const brandPurple = primary;
  static const brandIndigo = secondary;
  static const gradientTop = canvasGradientTop;
  static const gradientMid = canvasGradientMid;
  static const gradientBottom = canvasGradientBottom;
  static const cardGradientStart = Color(0xFFEDE8FF);
  static const cardGradientMid = Color(0xFFF6F4FF);
  static const cardGradientEnd = Color(0xFFDDD7FF);
}
