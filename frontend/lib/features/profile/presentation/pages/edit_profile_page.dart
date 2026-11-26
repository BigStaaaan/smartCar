import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../shared/widgets/smartcar_logo.dart';

class EditProfilePage extends StatelessWidget {
  const EditProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SmartCarLogo(
              variant: SmartCarLogoVariant.iconOnly,
              symbolSize: 28,
            ),
            const SizedBox(width: 8),
            Text('Complete Profile', style: AppTypography.headlineSm),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: Text(
          'Complete your student profile to continue.',
          style: AppTypography.bodyMd,
        ),
      ),
    );
  }
}
