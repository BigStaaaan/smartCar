import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';

Future<void> showAuthErrorDialog(
  BuildContext context,
  String message, {
  String title = 'Une erreur est survenue',
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      icon: const Icon(
        Icons.error_outline_rounded,
        color: AppColors.error,
        size: 34,
      ),
      title: Text(
        title,
        textAlign: TextAlign.center,
        style: AppTypography.headlineSm.copyWith(fontWeight: FontWeight.w700),
      ),
      content: Text(
        message,
        textAlign: TextAlign.center,
        style: AppTypography.bodyMd,
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.brandIndigo,
            foregroundColor: Colors.white,
            minimumSize: const Size(120, 44),
            shape: const StadiumBorder(),
          ),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}
