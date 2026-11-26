import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../shared/widgets/smartcar_logo.dart';
import '../../../home/presentation/pages/home_page.dart';
import '../../../onboarding/presentation/pages/onboarding_page.dart';
import '../../../profile/presentation/pages/edit_profile_page.dart';
import '../providers/splash_provider.dart';

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _scaleAnimation = Tween<double>(begin: 0.94, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: Curves.easeOutCubic,
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (MediaQuery.disableAnimationsOf(context)) {
        _animController.value = 1.0;
      } else {
        _animController.forward();
      }
      ref.read(splashProvider.notifier).initialize();
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _navigateTo(SplashDestination destination) {
    if (_hasNavigated || !mounted) return;
    _hasNavigated = true;

    final Widget target = switch (destination) {
      SplashDestination.home => const HomePage(),
      SplashDestination.profileCompletion => const EditProfilePage(),
      SplashDestination.onboarding => const OnboardingPage(),
    };

    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => target),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<SplashState>(splashProvider, (previous, next) {
      if (next.status == SplashStatus.ready && next.destination != null) {
        _navigateTo(next.destination!);
      }
    });

    final splashState = ref.watch(splashProvider);

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
              AppColors.canvasGradientTop,
              AppColors.canvasGradientMid,
              AppColors.canvasGradientBottom,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: const SmartCarLogo(
                        variant: SmartCarLogoVariant.primary,
                        symbolSize: 88,
                        wordmarkFontSize: 32,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  if (splashState.status == SplashStatus.error) ...[
                    Text(
                      splashState.errorMessage ?? 'Initialization failed.',
                      textAlign: TextAlign.center,
                      style: AppTypography.bodySm.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ElevatedButton(
                          onPressed: () =>
                              ref.read(splashProvider.notifier).initialize(),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(120, 44),
                          ),
                          child: const Text('Retry'),
                        ),
                        const SizedBox(width: 12),
                        TextButton(
                          onPressed: () =>
                              _navigateTo(SplashDestination.onboarding),
                          child: const Text('Continue'),
                        ),
                      ],
                    ),
                  ] else ...[
                    const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: AppColors.secondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Your campus, your journey.',
                      style: AppTypography.bodySm.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
