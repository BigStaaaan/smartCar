import 'package:flutter/material.dart';

/// Model representing a single onboarding step / slide.
class OnboardingStepData {
  final String title;
  final String highlightedTitle;
  final String description;
  final int stepIndex;
  final IconData? badgeIcon;
  final String? badgeText;

  const OnboardingStepData({
    required this.title,
    required this.highlightedTitle,
    required this.description,
    required this.stepIndex,
    this.badgeIcon,
    this.badgeText,
  });

  static const List<OnboardingStepData> steps = [
    OnboardingStepData(
      title: 'Share the ride,\n',
      highlightedTitle: 'split the cost.',
      description:
          'Find verified students going your way and travel to campus safely and affordably.',
      stepIndex: 0,
      badgeIcon: Icons.verified_user_rounded,
      badgeText: 'Verified riders',
    ),
    OnboardingStepData(
      title: 'Connect with peers,\n',
      highlightedTitle: 'travel safely.',
      description:
          'Every driver and rider is verified with university credentials for maximum safety.',
      stepIndex: 1,
      badgeIcon: Icons.shield_rounded,
      badgeText: 'Campus verified',
    ),
    OnboardingStepData(
      title: 'Never be late,\n',
      highlightedTitle: 'sync timetables.',
      description:
          'Schedule carpools matching your daily lecture hours and save up to 60% on commutes.',
      stepIndex: 2,
      badgeIcon: Icons.schedule_rounded,
      badgeText: 'Timetable sync',
    ),
  ];
}
