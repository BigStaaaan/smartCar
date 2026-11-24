import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_theme.dart';

const driverSurface = AppColors.background;
const driverText = AppColors.onSurface;
const driverAccent = AppColors.primary;
const driverOnAccent = AppColors.onPrimary;
const driverHighlight = AppColors.primaryContainer;
const driverOutline = AppColors.surfaceStroke;
const driverError = AppColors.error;

ThemeData driverTheme() {
  final theme = AppTheme.light;
  final text = theme.textTheme;
  return theme.copyWith(
    textTheme: text.copyWith(
      displaySmall: text.displayLarge,
      titleLarge: text.headlineMedium,
      titleSmall: text.headlineSmall,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: theme.elevatedButtonTheme.style,
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: driverText,
        backgroundColor: AppColors.surfaceContainerLowest,
        side: const BorderSide(color: driverOutline),
        shape: const StadiumBorder(),
      ),
    ),
  );
}

class DriverCard extends StatelessWidget {
  const DriverCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = 20,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double padding;

  @override
  Widget build(BuildContext context) => Card(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(padding: EdgeInsets.all(padding), child: child),
        ),
      );
}
