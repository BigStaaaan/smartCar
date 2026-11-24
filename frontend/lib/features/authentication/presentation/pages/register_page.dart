import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../shared/widgets/smartcar_logo.dart';
import '../../../../core/validators/email_validator.dart';
import '../../../../core/validators/required_validator.dart';
import '../../../../core/widgets/auth_error_dialog.dart';
import '../../../home/presentation/pages/home_page.dart';
import '../../../email_verification/presentation/pages/email_verification_page.dart';
import '../providers/auth_provider.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _university = 'Faculté des Sciences d’Agadir';
  bool _obscurePassword = true;
  bool _acceptedTerms = false;
  XFile? _studentCard;
  bool _isPickingStudentCard = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  int get _passwordStrength {
    final password = _passwordController.text;
    if (password.isEmpty) return 0;
    var score = 0;
    if (password.length >= 8) score++;
    if (password.contains(RegExp(r'[A-Z]'))) score++;
    if (password.contains(RegExp(r'[0-9]'))) score++;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) score++;
    return score;
  }

  String get _strengthLabel {
    if (_passwordStrength <= 1) return 'Weak';
    if (_passwordStrength == 2) return 'Fair';
    if (_passwordStrength == 3) return 'Good';
    return 'Strong';
  }

  Future<Map<String, String>> _studentCardPayload() async {
    final card = _studentCard;
    if (card == null) return <String, String>{};
    final bytes = await card.readAsBytes();
    return <String, String>{
      'studentCard': base64Encode(bytes),
      'studentCardName': card.name,
      'studentCardMimeType': card.mimeType ?? 'image/jpeg',
    };
  }

  Future<void> _pickStudentCard() async {
    setState(() => _isPickingStudentCard = true);
    try {
      final card = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1600,
      );
      if (!mounted) return;
      if (card == null) return;
      final bytes = await card.readAsBytes();
      if (!mounted) return;
      if (bytes.lengthInBytes > 5 * 1024 * 1024) {
        await showAuthErrorDialog(
          context,
          'Your student ID card must be smaller than 5 MB.',
          title: 'Image Too Large',
        );
        return;
      }
      setState(() => _studentCard = card);
    } finally {
      if (mounted) setState(() => _isPickingStudentCard = false);
    }
  }

  Future<void> _handleSignUp() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    if (_studentCard == null) {
      await showAuthErrorDialog(
        context,
        'Please add a photo of your student ID card to submit the verification request.',
        title: 'Student Card Required',
      );
      return;
    }
    if (!_acceptedTerms) {
      await showAuthErrorDialog(
        context,
        'You must accept the carpooling rules before creating your account.',
        title: 'Terms Required',
      );
      return;
    }

    final cardPayload = await _studentCardPayload();
    final success = await ref.read(authProvider.notifier).signUpWithEmail(
          fullName: _nameController.text.trim(),
          university: _university,
          email: _emailController.text.trim(),
          password: _passwordController.text,
          accountType:
              EmailValidator.getAccountType(_emailController.text) ??
                  'STUDENT',
          studentCardPayload: cardPayload,
        );
    if (!mounted) return;
    if (success) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => const EmailVerificationPage(),
        ),
      );
    } else {
      final message =
          ref.read(authProvider).errorMessage ?? 'Account creation failed.';
      await showAuthErrorDialog(
        context,
        message,
        title: 'Account Creation Failed',
      );
    }
  }

  Future<void> _handleGoogleSignUp() async {
    if (_studentCard == null) {
      await showAuthErrorDialog(
        context,
        'Please add a photo of your student ID card before continuing.',
        title: 'Student Card Required',
      );
      return;
    }
    final cardPayload = await _studentCardPayload();
    final success = await ref
        .read(authProvider.notifier)
        .signInWithGoogle(studentCardPayload: cardPayload);
    if (!mounted) return;
    if (success) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const HomePage()),
      );
    } else {
      final message =
          ref.read(authProvider).errorMessage ?? 'Google Sign-In failed.';
      await showAuthErrorDialog(
        context,
        message,
        title: 'Google Sign-In Failed',
      );
    }
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: AppTypography.bodyMd.copyWith(
        color: AppColors.outline,
        fontSize: 12.5,
      ),
      filled: true,
      fillColor: Colors.white,
      prefixIcon: Padding(
        padding: const EdgeInsets.only(left: 12, right: 8),
        child: Icon(icon, size: 18, color: AppColors.outline),
      ),
      prefixIconConstraints: const BoxConstraints(minWidth: 38, minHeight: 24),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
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
        borderSide: const BorderSide(color: AppColors.brandIndigo, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
      ),
    );
  }

  Widget _fieldLabel(String label, {String? trailing}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTypography.labelSm.copyWith(
            color: AppColors.onSurface,
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (trailing != null)
          Text(
            trailing,
            style: AppTypography.caption.copyWith(
              color: AppColors.brandIndigo,
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final authState = ref.watch(authProvider);

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
              AppColors.gradientTop,
              AppColors.gradientMid,
              AppColors.gradientBottom,
            ],
          ),
        ),
        child: SafeArea(
          top: false,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: EdgeInsets.fromLTRB(16, topPadding + 10, 16, 16),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 480),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SmartCarLogo(
                              variant: SmartCarLogoVariant.horizontal,
                              symbolSize: 28,
                              wordmarkFontSize: 18,
                            ),
                            const SizedBox(height: 18),
                            Text.rich(
                              const TextSpan(
                                children: [
                                  TextSpan(text: 'Join '),
                                  TextSpan(
                                    text: 'SmartCar',
                                    style:
                                        TextStyle(color: AppColors.brandIndigo),
                                  ),
                                ],
                              ),
                              style: AppTypography.headlineLg.copyWith(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 7),
                            Text(
                              'Connect with verified classmates for safe,\naffordable daily rides.',
                              style: AppTypography.bodySm.copyWith(
                                color: AppColors.onSurfaceVariant,
                                fontSize: 12.5,
                                height: 1.35,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _fieldLabel('Full Legal Name'),
                            const SizedBox(height: 5),
                            Container(
                              height: 52,
                              decoration: _fieldBox,
                              child: TextFormField(
                                controller: _nameController,
                                validator: (value) =>
                                    value == null || value.trim().isEmpty
                                        ? 'Please enter your full name'
                                        : null,
                                decoration: _inputDecoration(
                                  hint: 'e.g. Alex Morgan',
                                  icon: Icons.person_outline_rounded,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            _fieldLabel('University Campus'),
                            const SizedBox(height: 5),
                            Container(
                              height: 52,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              decoration: _fieldBox,
                              child: Row(
                                children: [
                                  const Icon(Icons.school_outlined,
                                      size: 18, color: AppColors.outline),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        value: _university,
                                        isExpanded: true,
                                        icon: const Icon(
                                            Icons.keyboard_arrow_down_rounded,
                                            size: 18,
                                            color: AppColors.outline),
                                        style: AppTypography.bodyMd.copyWith(
                                            color: AppColors.onSurface,
                                            fontSize: 12.5),
                                        items: const [
                                          DropdownMenuItem(
                                            value:
                                                'Faculté des Sciences d’Agadir',
                                            child: Text(
                                                'Faculté des Sciences d’Agadir',
                                                overflow:
                                                    TextOverflow.ellipsis),
                                          ),
                                          DropdownMenuItem(
                                            value:
                                                'Faculté des Lettres et des Sciences Humaines d’Agadir',
                                            child: Text(
                                                'Faculté des Lettres et des Sciences Humaines d’Agadir',
                                                overflow:
                                                    TextOverflow.ellipsis),
                                          ),
                                          DropdownMenuItem(
                                            value:
                                                'Faculté des Sciences Juridiques, Économiques et Sociales d’Agadir',
                                            child: Text(
                                                'Faculté des Sciences Juridiques, Économiques et Sociales d’Agadir',
                                                overflow:
                                                    TextOverflow.ellipsis),
                                          ),
                                          DropdownMenuItem(
                                            value:
                                                'Faculté de Médecine et de Pharmacie d’Agadir',
                                            child: Text(
                                                'Faculté de Médecine et de Pharmacie d’Agadir',
                                                overflow:
                                                    TextOverflow.ellipsis),
                                          ),
                                          DropdownMenuItem(
                                            value:
                                                'École Supérieure de Technologie d’Agadir',
                                            child: Text(
                                                'École Supérieure de Technologie d’Agadir',
                                                overflow:
                                                    TextOverflow.ellipsis),
                                          ),
                                          DropdownMenuItem(
                                            value:
                                                'École Nationale des Sciences Appliquées d’Agadir',
                                            child: Text(
                                                'École Nationale des Sciences Appliquées d’Agadir',
                                                overflow:
                                                    TextOverflow.ellipsis),
                                          ),
                                          DropdownMenuItem(
                                            value:
                                                'École Nationale de Commerce et de Gestion d’Agadir',
                                            child: Text(
                                                'École Nationale de Commerce et de Gestion d’Agadir',
                                                overflow:
                                                    TextOverflow.ellipsis),
                                          ),
                                          DropdownMenuItem(
                                            value:
                                                'École Supérieure de l’Éducation et de la Formation d’Agadir',
                                            child: Text(
                                                'École Supérieure de l’Éducation et de la Formation d’Agadir',
                                                overflow:
                                                    TextOverflow.ellipsis),
                                          ),
                                        ],
                                        onChanged: (value) {
                                          if (value != null) {
                                            setState(() => _university = value);
                                          }
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            _fieldLabel('Campus Email', trailing: 'required'),
                            const SizedBox(height: 5),
                            Container(
                              height: 52,
                              decoration: _fieldBox,
                              child: TextFormField(
                                controller: _emailController,
                                validator: EmailValidator.validate,
                                keyboardType: TextInputType.emailAddress,
                                decoration: _inputDecoration(
                                  hint: 'usr.name@university.edu',
                                  icon: Icons.alternate_email_rounded,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            _fieldLabel('Create Password',
                                trailing: '8+ chars, 1 number'),
                            const SizedBox(height: 5),
                            Container(
                              height: 52,
                              decoration: _fieldBox,
                              child: TextFormField(
                                controller: _passwordController,
                                validator: RequiredValidator.validatePassword,
                                obscureText: _obscurePassword,
                                onChanged: (_) => setState(() {}),
                                decoration: _inputDecoration(
                                  hint: '••••••••••••',
                                  icon: Icons.lock_outline_rounded,
                                ).copyWith(
                                  suffixIcon: IconButton(
                                    onPressed: () => setState(() =>
                                        _obscurePassword = !_obscurePassword),
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                      size: 18,
                                      color: AppColors.outline,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 7),
                            Row(
                              children: [
                                for (var index = 0; index < 4; index++)
                                  Expanded(
                                    child: Container(
                                      height: 3,
                                      margin: EdgeInsets.only(
                                          right: index == 3 ? 0 : 5),
                                      decoration: BoxDecoration(
                                        color: _passwordStrength > index
                                            ? AppColors.brandIndigo
                                            : AppColors.outlineVariant,
                                        borderRadius:
                                            BorderRadius.circular(999),
                                      ),
                                    ),
                                  ),
                                const SizedBox(width: 8),
                                if (_passwordStrength > 0)
                                  Text(
                                    _strengthLabel,
                                    style: const TextStyle(
                                      color: AppColors.brandIndigo,
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _fieldLabel('Student Card', trailing: 'required'),
                            const SizedBox(height: 5),
                            InkWell(
                              onTap:
                                  _isPickingStudentCard ? null : _pickStudentCard,
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                width: double.infinity,
                                height: 68,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: _studentCard == null
                                        ? AppColors.outlineVariant
                                        : AppColors.brandIndigo,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryFixed,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: _isPickingStudentCard
                                          ? const Padding(
                                              padding: EdgeInsets.all(12),
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : Icon(
                                              _studentCard == null
                                                  ? Icons.upload_rounded
                                                  : Icons.check_circle_rounded,
                                              color: AppColors.brandIndigo,
                                            ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _studentCard == null
                                                ? 'Upload student card'
                                                : _studentCard!.name,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: AppTypography.labelSm
                                                .copyWith(
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            _studentCard == null
                                                ? 'JPG, PNG or WEBP - max 5 MB'
                                                : 'Ready for admin review',
                                            style: AppTypography.caption
                                                .copyWith(fontSize: 9.5),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(
                                      _studentCard == null
                                          ? Icons.chevron_right_rounded
                                          : Icons.sync_rounded,
                                      color: AppColors.outline,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 9),
                              decoration: BoxDecoration(
                                color: AppColors.primaryFixed,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 28,
                                    height: 28,
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.verified_user_outlined,
                                      size: 16,
                                      color: AppColors.brandIndigo,
                                    ),
                                  ),
                                  const SizedBox(width: 9),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text('Zero-Stranger Guarantee',
                                            style: AppTypography.labelSm
                                                .copyWith(
                                                    fontSize: 10.5,
                                                    fontWeight:
                                                        FontWeight.w800)),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Physical Student ID is visually synced before departure. You only share vehicles with verified peers.',
                                          style: AppTypography.caption.copyWith(
                                              fontSize: 9.5, height: 1.28),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            GestureDetector(
                              onTap: () => setState(
                                  () => _acceptedTerms = !_acceptedTerms),
                              behavior: HitTestBehavior.opaque,
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 18,
                                    height: 18,
                                    margin: const EdgeInsets.only(top: 1),
                                    decoration: BoxDecoration(
                                      color: _acceptedTerms
                                          ? AppColors.brandIndigo
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(5),
                                      border: Border.all(
                                        color: _acceptedTerms
                                            ? AppColors.brandIndigo
                                            : AppColors.outlineVariant,
                                      ),
                                    ),
                                    child: _acceptedTerms
                                        ? const Icon(Icons.check_rounded,
                                            size: 13, color: Colors.white)
                                        : null,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text.rich(
                                      const TextSpan(
                                        children: [
                                          TextSpan(
                                              text: 'I agree to the Carpool '),
                                          TextSpan(
                                            text: 'Guidelines',
                                            style: TextStyle(
                                                color: AppColors.brandIndigo,
                                                fontWeight: FontWeight.w700),
                                          ),
                                          TextSpan(
                                              text:
                                                  ', passenger etiquette code, and safety terms.'),
                                        ],
                                      ),
                                      style: AppTypography.caption.copyWith(
                                          fontSize: 9.5, height: 1.28),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton(
                                onPressed:
                                    authState.isLoading ? null : _handleSignUp,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.brandIndigo,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: const StadiumBorder(),
                                ),
                                child: authState.isLoading
                                    ? const SizedBox(
                                        width: 21,
                                        height: 21,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white),
                                      )
                                    : const FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              'Create Account',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            SizedBox(width: 8),
                                            Icon(
                                              Icons.arrow_forward_rounded,
                                              size: 18,
                                            ),
                                          ],
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            const Center(
                              child: Text(
                                'OR SIGN UP WITH',
                                style: TextStyle(
                                    color: AppColors.outline,
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w700),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Center(
                              child: SizedBox(
                                width: 220,
                                height: 46,
                                child: OutlinedButton(
                                  onPressed: authState.isLoading
                                      ? null
                                      : _handleGoogleSignUp,
                                  style: OutlinedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: AppColors.onSurface,
                                    side: const BorderSide(
                                        color: AppColors.outlineVariant),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        CustomPaint(
                                          size: const Size(18, 18),
                                          painter: _GoogleIconPainter(),
                                        ),
                                        const SizedBox(width: 10),
                                        const Text(
                                          'Continue with Google',
                                          style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Center(
                              child: TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: Text.rich(
                                  const TextSpan(
                                    children: [
                                      TextSpan(text: 'Already registered? '),
                                      TextSpan(
                                        text: 'Log in',
                                        style: TextStyle(
                                            color: AppColors.brandIndigo,
                                            fontWeight: FontWeight.w700),
                                      ),
                                    ],
                                  ),
                                  style: AppTypography.bodySm.copyWith(
                                      color: AppColors.onSurfaceVariant,
                                      fontSize: 12),
                                ),
                              ),
                            ),
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

const BoxDecoration _fieldBox = BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.all(Radius.circular(16)),
  boxShadow: [
    BoxShadow(
      color: Color(0x0D000000),
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ],
);


class _GoogleIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 24.0;
    canvas.save();
    canvas.scale(scale);
    canvas.drawPath(
      Path()
        ..moveTo(23.49, 12.275)
        ..cubicTo(23.49, 11.49, 23.415, 10.73, 23.3, 10)
        ..lineTo(12, 10)
        ..lineTo(12, 14.51)
        ..lineTo(18.47, 14.51)
        ..cubicTo(18.18, 15.99, 17.34, 17.25, 16.08, 18.1)
        ..lineTo(19.945, 21.1)
        ..cubicTo(22.2, 19.01, 23.49, 15.92, 23.49, 12.275)
        ..close(),
      Paint()..color = const Color(0xFF4285F4),
    );
    canvas.drawPath(
      Path()
        ..moveTo(12, 24)
        ..cubicTo(15.24, 24, 17.96, 22.92, 19.945, 21.1)
        ..lineTo(16.08, 18.1)
        ..cubicTo(15, 18.82, 13.62, 19.245, 12, 19.245)
        ..cubicTo(8.87, 19.245, 6.22, 17.13, 5.27, 14.29)
        ..lineTo(1.275, 17.38)
        ..cubicTo(3.255, 21.31, 7.31, 24, 12, 24)
        ..close(),
      Paint()..color = const Color(0xFF34A853),
    );
    canvas.drawPath(
      Path()
        ..moveTo(5.27, 14.29)
        ..cubicTo(5.02, 13.57, 4.89, 12.8, 4.89, 12)
        ..cubicTo(4.89, 11.2, 5.02, 10.43, 5.27, 9.71)
        ..lineTo(1.275, 6.62)
        ..cubicTo(0.46, 8.24, 0, 10.06, 0, 12)
        ..cubicTo(0, 13.94, 0.46, 15.76, 1.275, 17.38)
        ..lineTo(5.27, 14.29)
        ..close(),
      Paint()..color = const Color(0xFFFBBC05),
    );
    canvas.drawPath(
      Path()
        ..moveTo(12, 4.755)
        ..cubicTo(13.77, 4.755, 15.35, 5.36, 16.6, 6.555)
        ..lineTo(20.025, 3.13)
        ..cubicTo(17.95, 1.19, 15.23, 0, 12, 0)
        ..cubicTo(7.31, 0, 3.255, 2.69, 1.275, 6.62)
        ..lineTo(5.27, 9.71)
        ..cubicTo(6.22, 6.87, 8.87, 4.755, 12, 4.755)
        ..close(),
      Paint()..color = const Color(0xFFEA4335),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
