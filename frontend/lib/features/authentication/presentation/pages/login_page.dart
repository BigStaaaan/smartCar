import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/validators/email_validator.dart';
import '../../../../core/validators/required_validator.dart';
import '../../../../core/widgets/auth_error_dialog.dart';
import '../../../home/presentation/pages/home_page.dart';
import '../providers/auth_provider.dart';
import 'register_page.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _staySignedIn = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    // Dismiss keyboard
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final authNotifier = ref.read(authProvider.notifier);
    authNotifier.setRememberMe(_staySignedIn);

    final success = await authNotifier.signInWithEmail(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (context) => const HomePage(),
        ),
      );
    } else {
      final errorMessage =
          ref.read(authProvider).errorMessage ?? 'Login failed. Please try again.';
      await showAuthErrorDialog(context, errorMessage, title: 'Connexion impossible');
    }
  }

  Future<void> _handleGoogleSignIn() async {
    FocusScope.of(context).unfocus();

    final authNotifier = ref.read(authProvider.notifier);
    final success = await authNotifier.signInWithGoogle();

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (context) => const HomePage(),
        ),
      );
    } else {
      final errorMessage =
          ref.read(authProvider).errorMessage ?? 'Google Sign-In failed.';
      await showAuthErrorDialog(
        context,
        errorMessage,
        title: 'Connexion Google impossible',
      );
    }
  }

  void _handleForgotPassword() {
    final email = _emailController.text.trim();
    showDialog<void>(
      context: context,
      builder: (context) {
        final resetController = TextEditingController(text: email);
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Reset Password',
            style: AppTypography.headlineSm.copyWith(fontWeight: FontWeight.w700),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Enter your verified campus email to receive a password recovery link.',
                style: AppTypography.bodyMd,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: resetController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: 'yourname@university.edu',
                  prefixIcon: const Icon(Icons.mail_outline_rounded),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final targetEmail = resetController.text.trim();
                if (targetEmail.isNotEmpty) {
                  await ref
                      .read(authProvider.notifier)
                      .sendPasswordReset(targetEmail);
                  if (context.mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Password reset email sent to $targetEmail',
                        ),
                        backgroundColor: AppColors.brandIndigo,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandIndigo,
                minimumSize: const Size(100, 40),
                shape: const StadiumBorder(),
              ),
              child: const Text('Send Link'),
            ),
          ],
        );
      },
    );
  }

  void _navigateToSignUp() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => const RegisterPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final topPadding = MediaQuery.of(context).padding.top;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: [0.0, 0.45, 1.0],
            colors: [
              AppColors.gradientTop,    // #B7ACEB
              AppColors.gradientMid,    // #E6E1F8
              AppColors.gradientBottom, // #F7F5FD
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
                        22,
                        topPadding + 14,
                        22,
                        bottomPadding + 20,
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ── Section A: Top Header ──
                            const _SmartCarHeader(),

                            // Top flexible space to balance and vertically center the content
                            const Spacer(),

                            const SizedBox(height: 12),

                            // ── Section B: Welcome Text ──
                            Text(
                              'Welcome back!',
                              style: AppTypography.headlineLg.copyWith(
                                color: AppColors.onSurface,
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.6,
                              ),
                            ),

                            const SizedBox(height: 10),

                            Text.rich(
                              TextSpan(
                                children: [
                                  const TextSpan(text: 'Use your verified '),
                                  TextSpan(
                                    text: '.edu',
                                    style: TextStyle(
                                      color: AppColors.brandIndigo,
                                      fontWeight: FontWeight.w700,
                                      fontFamily: AppTypography.fontBody,
                                    ),
                                  ),
                                  const TextSpan(
                                    text:
                                        ' email to coordinate carpools, split gas, and cruise campus together safely.',
                                  ),
                                ],
                              ),
                              style: AppTypography.bodyMd.copyWith(
                                color: AppColors.onSurfaceVariant,
                                fontSize: 13.5,
                                height: 1.48,
                              ),
                            ),

                            const SizedBox(height: 22),

                            // Subtle Divider
                            Container(
                              height: 1,
                              color: const Color(0x22464552),
                            ),

                            const SizedBox(height: 20),

                            // ── Section C: Campus Email Field ──
                            _FieldLabel(label: 'Campus Email'),
                            const SizedBox(height: 8),
                            _CampusEmailInput(
                              controller: _emailController,
                              validator: EmailValidator.validate,
                            ),

                            const SizedBox(height: 16),

                            // ── Section D: Password Field with Forgot Password ──
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Flexible(child: _FieldLabel(label: 'Password')),
                                GestureDetector(
                                  onTap: _handleForgotPassword,
                                  child: Text(
                                    'Forgot password?',
                                    style: AppTypography.bodySm.copyWith(
                                      color: AppColors.brandIndigo,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            _PasswordInput(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              validator: RequiredValidator.validatePassword,
                              onToggleVisibility: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),

                            const SizedBox(height: 16),

                            // ── Section E: Remember Me Switch ──
                            _RememberMeRow(
                              value: _staySignedIn,
                              onChanged: (val) {
                                setState(() {
                                  _staySignedIn = val;
                                });
                              },
                            ),

                            const SizedBox(height: 22),

                            // ── Section F: Log In Button ──
                            _LogInButton(
                              isLoading: authState.isLoading,
                              onPressed: _handleLogin,
                            ),

                            const SizedBox(height: 22),

                            // ── Section G: Social Authentication ──
                            Center(
                              child: Text(
                                'Or continue securely with',
                                style: AppTypography.bodySm.copyWith(
                                  color: AppColors.onSurfaceVariant,
                                  fontSize: 12.5,
                                ),
                              ),
                            ),

                            const SizedBox(height: 12),

                            Center(
                              child: _GoogleSignInButton(
                                onPressed: authState.isLoading
                                    ? null
                                    : _handleGoogleSignIn,
                              ),
                            ),

                            const SizedBox(height: 24),

                            // ── Section H: Sign Up Footer ──
                            Center(
                              child: _SignUpFooter(onSignUpTap: _navigateToSignUp),
                            ),

                            // Bottom flexible space to keep the content centered vertically
                            const Spacer(),
                          ],
                        ),
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
// HEADER COMPONENT
// ─────────────────────────────────────────────────────────────────────────────
class _SmartCarHeader extends StatelessWidget {
  const _SmartCarHeader();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        'SmartCar',
        style: AppTypography.headlineSm.copyWith(
          color: AppColors.onSurface,
          fontSize: 18,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.4,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FIELD LABEL
// ─────────────────────────────────────────────────────────────────────────────
class _FieldLabel extends StatelessWidget {
  final String label;

  const _FieldLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: AppTypography.labelMd.copyWith(
        color: AppColors.onSurface,
        fontSize: 14,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CAMPUS EMAIL INPUT FIELD
// ─────────────────────────────────────────────────────────────────────────────
class _CampusEmailInput extends StatelessWidget {
  final TextEditingController controller;
  final FormFieldValidator<String>? validator;

  const _CampusEmailInput({
    required this.controller,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        validator: validator,
        keyboardType: TextInputType.emailAddress,
        style: AppTypography.bodyMd.copyWith(
          color: AppColors.onSurface,
          fontSize: 14,
        ),
        decoration: InputDecoration(
          hintText: 'yourname@university.edu',
          hintStyle: AppTypography.bodyMd.copyWith(
            color: const Color(0xFF9A9AAA),
            fontSize: 14,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 15,
          ),
          prefixIcon: const Padding(
            padding: EdgeInsets.only(left: 14, right: 10),
            child: Icon(
              Icons.mail_outline_rounded,
              color: Color(0xFF777684),
              size: 20,
            ),
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 44,
            minHeight: 24,
          ),
          suffixIcon: Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFEAE8FC),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.verified_rounded,
                    color: AppColors.brandIndigo,
                    size: 13,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    '.edu',
                    style: AppTypography.labelSm.copyWith(
                      color: AppColors.brandIndigo,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          suffixIconConstraints: const BoxConstraints(
            minWidth: 40,
            minHeight: 24,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(
              color: AppColors.brandIndigo,
              width: 1.5,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(
              color: AppColors.error,
              width: 1.5,
            ),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(
              color: AppColors.error,
              width: 1.5,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PASSWORD INPUT FIELD
// ─────────────────────────────────────────────────────────────────────────────
class _PasswordInput extends StatelessWidget {
  final TextEditingController controller;
  final bool obscureText;
  final VoidCallback onToggleVisibility;
  final FormFieldValidator<String>? validator;

  const _PasswordInput({
    required this.controller,
    required this.obscureText,
    required this.onToggleVisibility,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        validator: validator,
        obscureText: obscureText,
        style: AppTypography.bodyMd.copyWith(
          color: AppColors.onSurface,
          fontSize: 14,
        ),
        decoration: InputDecoration(
          hintText: '••••••••••••',
          hintStyle: const TextStyle(
            color: Color(0xFF9A9AAA),
            fontSize: 14,
            letterSpacing: 1.5,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 15,
          ),
          prefixIcon: const Padding(
            padding: EdgeInsets.only(left: 14, right: 10),
            child: Icon(
              Icons.lock_outline_rounded,
              color: Color(0xFF777684),
              size: 20,
            ),
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 44,
            minHeight: 24,
          ),
          suffixIcon: IconButton(
            icon: Icon(
              obscureText
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              color: const Color(0xFF777684),
              size: 20,
            ),
            onPressed: onToggleVisibility,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(
              color: AppColors.brandIndigo,
              width: 1.5,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(
              color: AppColors.error,
              width: 1.5,
            ),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(
              color: AppColors.error,
              width: 1.5,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// REMEMBER ME SWITCH
// ─────────────────────────────────────────────────────────────────────────────
class _RememberMeRow extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _RememberMeRow({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          // Custom Pill Toggle Switch
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            width: 44,
            height: 24,
            padding: const EdgeInsets.all(2.5),
            decoration: BoxDecoration(
              color: value ? AppColors.brandIndigo : const Color(0xFFC7C5D4),
              borderRadius: BorderRadius.circular(999),
            ),
            child: AnimatedAlign(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              alignment:
                  value ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: 19,
                height: 19,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x24000000),
                      blurRadius: 4,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Stay signed in on this phone',
              style: AppTypography.bodyMd.copyWith(
                color: AppColors.onSurface,
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// LOG IN BUTTON
// ─────────────────────────────────────────────────────────────────────────────
class _LogInButton extends StatefulWidget {
  final bool isLoading;
  final VoidCallback onPressed;

  const _LogInButton({
    required this.isLoading,
    required this.onPressed,
  });

  @override
  State<_LogInButton> createState() => _LogInButtonState();
}

class _LogInButtonState extends State<_LogInButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _isPressed ? 0.98 : 1.0,
      duration: const Duration(milliseconds: 100),
      child: Container(
        width: double.infinity,
        height: 54,
        decoration: BoxDecoration(
          color: AppColors.brandIndigo,
          borderRadius: BorderRadius.circular(999),
          boxShadow: const [
            BoxShadow(
              color: Color(0x333A3FE5),
              blurRadius: 14,
              offset: Offset(0, 5),
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
            onTap: widget.isLoading ? null : widget.onPressed,
            child: Center(
              child: widget.isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Log In',
                          style: AppTypography.labelMd.copyWith(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: 19,
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GOOGLE SIGN IN BUTTON
// ─────────────────────────────────────────────────────────────────────────────
class _GoogleSignInButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const _GoogleSignInButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onPressed,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomPaint(
                size: const Size(18, 18),
                painter: _GoogleIconPainter(),
              ),
              const SizedBox(width: 10),
              Text(
                'Google',
                style: AppTypography.labelMd.copyWith(
                  color: AppColors.onSurface,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SIGN UP FOOTER
// ─────────────────────────────────────────────────────────────────────────────
class _SignUpFooter extends StatelessWidget {
  final VoidCallback onSignUpTap;

  const _SignUpFooter({required this.onSignUpTap});

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: "Don't have an account? ",
            style: AppTypography.bodySm.copyWith(
              color: AppColors.onSurfaceVariant,
              fontSize: 13,
            ),
          ),
          WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: GestureDetector(
              onTap: onSignUpTap,
              child: Text(
                'Create one',
                style: AppTypography.bodySm.copyWith(
                  color: AppColors.brandIndigo,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PRECISE GOOGLE VECTOR LOGO PAINTER
// ─────────────────────────────────────────────────────────────────────────────
class _GoogleIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 24.0;
    canvas.save();
    canvas.scale(scale);

    // Blue Path
    final bluePaint = Paint()..color = const Color(0xFF4285F4);
    final bluePath = Path()
      ..moveTo(23.49, 12.275)
      ..cubicTo(23.49, 11.49, 23.415, 10.73, 23.3, 10)
      ..lineTo(12, 10)
      ..lineTo(12, 14.51)
      ..lineTo(18.47, 14.51)
      ..cubicTo(18.18, 15.99, 17.34, 17.25, 16.08, 18.1)
      ..lineTo(19.945, 21.1)
      ..cubicTo(22.2, 19.01, 23.49, 15.92, 23.49, 12.275)
      ..close();
    canvas.drawPath(bluePath, bluePaint);

    // Green Path
    final greenPaint = Paint()..color = const Color(0xFF34A853);
    final greenPath = Path()
      ..moveTo(12, 24)
      ..cubicTo(15.24, 24, 17.96, 22.92, 19.945, 21.1)
      ..lineTo(16.08, 18.1)
      ..cubicTo(15, 18.82, 13.62, 19.245, 12, 19.245)
      ..cubicTo(8.87, 19.245, 6.22, 17.13, 5.27, 14.29)
      ..lineTo(1.275, 17.38)
      ..cubicTo(3.255, 21.31, 7.31, 24, 12, 24)
      ..close();
    canvas.drawPath(greenPath, greenPaint);

    // Yellow Path
    final yellowPaint = Paint()..color = const Color(0xFFFBBC05);
    final yellowPath = Path()
      ..moveTo(5.27, 14.29)
      ..cubicTo(5.02, 13.57, 4.89, 12.8, 4.89, 12)
      ..cubicTo(4.89, 11.2, 5.02, 10.43, 5.27, 9.71)
      ..lineTo(1.275, 6.62)
      ..cubicTo(0.46, 8.24, 0, 10.06, 0, 12)
      ..cubicTo(0, 13.94, 0.46, 15.76, 1.275, 17.38)
      ..lineTo(5.27, 14.29)
      ..close();
    canvas.drawPath(yellowPath, yellowPaint);

    // Red Path
    final redPaint = Paint()..color = const Color(0xFFEA4335);
    final redPath = Path()
      ..moveTo(12, 4.755)
      ..cubicTo(13.77, 4.755, 15.35, 5.36, 16.6, 6.555)
      ..lineTo(20.025, 3.13)
      ..cubicTo(17.95, 1.19, 15.23, 0, 12, 0)
      ..cubicTo(7.31, 0, 3.255, 2.69, 1.275, 6.62)
      ..lineTo(5.27, 9.71)
      ..cubicTo(6.22, 6.87, 8.87, 4.755, 12, 4.755)
      ..close();
    canvas.drawPath(redPath, redPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
