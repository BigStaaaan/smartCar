import 'dart:ui';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../shared/widgets/smartcar_logo.dart';
import '../../../authentication/presentation/pages/login_page.dart';
import '../providers/onboarding_provider.dart';
import 'onboarding_step.dart';

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  late final PageController _pageController;
  late final TapGestureRecognizer _termsRecognizer;
  late final TapGestureRecognizer _privacyRecognizer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _termsRecognizer = TapGestureRecognizer()..onTap = _showTermsDialog;
    _privacyRecognizer = TapGestureRecognizer()..onTap = _showPrivacyDialog;
  }

  @override
  void dispose() {
    _pageController.dispose();
    _termsRecognizer.dispose();
    _privacyRecognizer.dispose();
    super.dispose();
  }

  void _onGetStarted() {
    ref.read(onboardingProvider.notifier).complete();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => const LoginPage(),
      ),
    );
  }

  void _showTermsDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Terms of Service'),
        content: const Text(
          'By using SmartCar, you agree to respect campus carpooling safety rules, '
          'maintain university student verification, and share ride costs fairly.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy Policy'),
        content: const Text(
          'SmartCar protects your university credentials and student data. '
          'Your location is only shared during active trip matching.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final topPadding = mediaQuery.padding.top;
    final bottomPadding = mediaQuery.padding.bottom;
    final currentIndex = ref.watch(onboardingProvider).currentPage;
    const steps = OnboardingStepData.steps;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Cinematic Campus + Students + Car Background ──
          Positioned.fill(
            child: Image.asset(
              'assets/images/welcome_background.jpg',
              fit: BoxFit.cover,
              alignment: Alignment.center,
            ),
          ),

          // ── Dark Transparent Gradient Overlay ──
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.0, 0.42, 0.72, 1.0],
                  colors: [
                    AppColors.onSurface.withValues(alpha: 0.45),
                    AppColors.onPrimaryFixed.withValues(alpha: 0.38),
                    AppColors.onSurface.withValues(alpha: 0.78),
                    AppColors.onSurface.withValues(alpha: 0.90),
                  ],
                ),
              ),
            ),
          ),

          // ── Foreground Content ──
          SafeArea(
            top: false,
            bottom: false,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          20,
                          topPadding + 14,
                          20,
                          bottomPadding + 16,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Spacer(flex: 3),

                            // ── Centered Official SmartCar Logo (White) ──
                            const SmartCarLogo(
                              variant: SmartCarLogoVariant.monochromeWhite,
                              symbolSize: 98,
                              wordmarkFontSize: 34,
                            ),

                            const SizedBox(height: 28),

                            // ── 3-Slide Swipeable Onboarding Content ──
                            SizedBox(
                              height: 250,
                              child: PageView.builder(
                                controller: _pageController,
                                physics: const ClampingScrollPhysics(),
                                itemCount: steps.length,
                                onPageChanged: (index) {
                                  ref
                                      .read(onboardingProvider.notifier)
                                      .setPage(index);
                                },
                                itemBuilder: (context, index) {
                                  final step = steps[index];
                                  return Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text.rich(
                                        TextSpan(
                                          children: [
                                            TextSpan(text: step.title),
                                            TextSpan(
                                              text: step.highlightedTitle,
                                              style: TextStyle(
                                                color: AppColors.inversePrimary,
                                                fontFamily:
                                                    AppTypography.fontHeadline,
                                              ),
                                            ),
                                          ],
                                        ),
                                        textAlign: TextAlign.center,
                                        style: AppTypography.headlineMd.copyWith(
                                          color: Colors.white,
                                          fontSize: 26,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: -0.5,
                                          height: 1.18,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      ConstrainedBox(
                                        constraints:
                                            const BoxConstraints(maxWidth: 290),
                                        child: Text(
                                          step.description,
                                          textAlign: TextAlign.center,
                                          style: AppTypography.bodyMd.copyWith(
                                            color: Colors.white
                                                .withValues(alpha: 0.88),
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.w400,
                                            height: 1.45,
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),

                            const Spacer(flex: 1),

                            const SizedBox(height: 12),

                            // ── Smooth Animated Page Indicators ──
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(steps.length, (index) {
                                final isActive = index == currentIndex;
                                return GestureDetector(
                                  onTap: () {
                                    _pageController.animateToPage(
                                      index,
                                      duration:
                                          const Duration(milliseconds: 300),
                                      curve: Curves.easeOutCubic,
                                    );
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 250),
                                    curve: Curves.easeOutCubic,
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 3,
                                    ),
                                    width: isActive ? 22 : 6,
                                    height: 5,
                                    decoration: BoxDecoration(
                                      color: isActive
                                          ? AppColors.primary
                                          : Colors.white.withValues(alpha: 0.4),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                  ),
                                );
                              }),
                            ),

                            const SizedBox(height: 20),

                            // ── Glassmorphism Get Started Button ──
                            _GetStartedButton(onPressed: _onGetStarted),

                            const SizedBox(height: 16),

                            // ── Footer ──
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 220),
                              child: Text.rich(
                                TextSpan(
                                  children: [
                                    const TextSpan(
                                      text: 'By continuing you accept our ',
                                    ),
                                    TextSpan(
                                      text: 'Terms',
                                      recognizer: _termsRecognizer,
                                      style: const TextStyle(
                                        decoration: TextDecoration.underline,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const TextSpan(text: ' & '),
                                    TextSpan(
                                      text: 'Privacy Policy',
                                      recognizer: _privacyRecognizer,
                                      style: const TextStyle(
                                        decoration: TextDecoration.underline,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                                textAlign: TextAlign.center,
                                style: AppTypography.caption.copyWith(
                                  color: Colors.white.withValues(alpha: 0.78),
                                  fontSize: 10.5,
                                  height: 1.35,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GLASSMORPHISM GET STARTED BUTTON
// ─────────────────────────────────────────────────────────────────────────────
class _GetStartedButton extends StatefulWidget {
  final VoidCallback onPressed;

  const _GetStartedButton({required this.onPressed});

  @override
  State<_GetStartedButton> createState() => _GetStartedButtonState();
}

class _GetStartedButtonState extends State<_GetStartedButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      widthFactor: 0.92,
      child: AnimatedScale(
        scale: _isPressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            boxShadow: [
              BoxShadow(
                color: AppColors.secondary.withValues(alpha: 0.28),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.72),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.32),
                    width: 1,
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(999),
                    onHighlightChanged: (highlighted) {
                      setState(() {
                        _isPressed = highlighted;
                      });
                    },
                    onTap: widget.onPressed,
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Get Started',
                            style: AppTypography.labelMd.copyWith(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.arrow_forward_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
