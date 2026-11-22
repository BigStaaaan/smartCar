import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../authentication/presentation/pages/login_page.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  late final TapGestureRecognizer _termsRecognizer;
  late final TapGestureRecognizer _privacyRecognizer;

  @override
  void initState() {
    super.initState();
    _termsRecognizer = TapGestureRecognizer()..onTap = _showTermsDialog;
    _privacyRecognizer = TapGestureRecognizer()..onTap = _showPrivacyDialog;
  }

  @override
  void dispose() {
    _termsRecognizer.dispose();
    _privacyRecognizer.dispose();
    super.dispose();
  }

  void _onGetStarted() {
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

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: [0.0, 0.55, 1.0],
            colors: [
              Color(0xFFB7ACEB), // Soft lavender / light purple at top
              Color(0xFFE6E1F8), // Smooth mid-tone transition
              Color(0xFFF7F5FD), // Very light lavender / almost white at bottom
            ],
          ),
        ),
        child: SafeArea(
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
                          // ── Top Header: Application Name at top-left ──
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Padding(
                              padding: const EdgeInsets.only(left: 4),
                              child: Text(
                                'SmartCar',
                                style: AppTypography.headlineSm.copyWith(
                                  color: const Color(0xFF1B1B20),
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.4,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 12),

                          // ── Center Illustration ──
                          Expanded(
                            flex: 6,
                            child: Center(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxHeight: 280,
                                  maxWidth: 280,
                                ),
                                child: Image.asset(
                                  'assets/images/illustrations/welcome-screen-ilustration.png',
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // ── Main Content: Headings & Description ──
                          // Main Heading (Bricolage Grotesque)
                          Text.rich(
                            TextSpan(
                              children: [
                                const TextSpan(text: 'Share the ride,\n'),
                                TextSpan(
                                  text: 'split the cost.',
                                  style: TextStyle(
                                    color: const Color(0xFF403DEB),
                                    fontFamily: AppTypography.fontHeadline,
                                  ),
                                ),
                              ],
                            ),
                            textAlign: TextAlign.center,
                            style: AppTypography.headlineMd.copyWith(
                              color: const Color(0xFF1B1B20),
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.4,
                              height: 1.2,
                            ),
                          ),

                          const SizedBox(height: 10),

                          // Description (Be Vietnam Pro)
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 240),
                            child: Text(
                              'Find verified students going your way and '
                              'travel to campus safely and affordably.',
                              textAlign: TextAlign.center,
                              style: AppTypography.bodySm.copyWith(
                                color: const Color(0xFF5A5968),
                                fontSize: 11.5,
                                fontWeight: FontWeight.w400,
                                height: 1.45,
                              ),
                            ),
                          ),

                          const SizedBox(height: 14),

                          // ── Onboarding Indicators ──
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Active Indicator (pill)
                              Container(
                                width: 22,
                                height: 5,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF403DEB),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                              ),
                              const SizedBox(width: 6),
                              // Inactive Indicator 1
                              Container(
                                width: 5,
                                height: 5,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFC7C5D4),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              // Inactive Indicator 2
                              Container(
                                width: 5,
                                height: 5,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFC7C5D4),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          // ── Get Started Button ──
                          _GetStartedButton(onPressed: _onGetStarted),

                          const SizedBox(height: 16),

                          // ── Footer (Be Vietnam Pro) ──
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
                                      color: Color(0xFF5A5968),
                                    ),
                                  ),
                                  const TextSpan(text: ' & '),
                                  TextSpan(
                                    text: 'Privacy Policy',
                                    recognizer: _privacyRecognizer,
                                    style: const TextStyle(
                                      decoration: TextDecoration.underline,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF5A5968),
                                    ),
                                  ),
                                ],
                              ),
                              textAlign: TextAlign.center,
                              style: AppTypography.caption.copyWith(
                                color: const Color(0xFF6B6B7B),
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
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GET STARTED BUTTON
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
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFF403DEB),
            borderRadius: BorderRadius.circular(999),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33403DEB),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
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
    );
  }
}
