import 'package:flutter/material.dart';

import '../features/onboarding/presentation/pages/onboarding_page.dart';
import 'theme/app_theme.dart';

class SmartCarApp extends StatelessWidget {
  const SmartCarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SmartCar',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const OnboardingPage(),
    );
  }
}