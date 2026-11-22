import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../home/presentation/pages/home_page.dart';

class EmailVerificationPage extends StatefulWidget {
  const EmailVerificationPage({super.key});

  @override
  State<EmailVerificationPage> createState() => _EmailVerificationPageState();
}

class _EmailVerificationPageState extends State<EmailVerificationPage> {
  bool _isLoading = false;
  String? _message;
  DateTime? _lastResendAt;

  Future<void> _resend() async {
    if (_lastResendAt != null &&
        DateTime.now().difference(_lastResendAt!) <
            const Duration(seconds: 60)) {
      setState(
        () => _message = 'Veuillez attendre avant de demander un nouveau lien.',
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.currentUser?.sendEmailVerification();
      _lastResendAt = DateTime.now();
      setState(
        () => _message =
            'Lien de verification renvoye sur votre adresse universitaire.',
      );
    } on FirebaseAuthException catch (error) {
      String message = error.message ?? 'Impossible de renvoyer le lien.';
      if (error.code == 'too-many-requests') {
        message =
            'Trop de demandes. Attendez quelques minutes avant de renvoyer.';
      }
      setState(() => _message = message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _checkVerification() async {
    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.currentUser?.reload();
      final user = FirebaseAuth.instance.currentUser;
      if (user?.emailVerified == true) {
        final idToken = await user?.getIdToken(true);
        if (idToken != null) {
          await Dio(
            BaseOptions(
              baseUrl: const String.fromEnvironment(
                'API_BASE_URL',
                defaultValue: kIsWeb
                    ? 'http://127.0.0.1:3000/api/v1'
                    : 'http://10.0.2.2:3000/api/v1',
              ),
            ),
          ).get(
            '/auth/verification-status',
            options: Options(
              headers: {'Authorization': 'Bearer $idToken'},
            ),
          );
        }
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(builder: (_) => const HomePage()),
        );
      } else {
        setState(
          () => _message =
              'Votre adresse universitaire nÃ¢â‚¬â„¢est pas encore verifiee.',
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = FirebaseAuth.instance.currentUser?.email ?? '';

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.gradientTop,
              AppColors.gradientMid,
              AppColors.gradientBottom,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.mark_email_unread_outlined,
                      size: 64,
                      color: AppColors.brandIndigo,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'VÃƒÂ©rifiez votre adresse universitaire',
                      textAlign: TextAlign.center,
                      style: AppTypography.headlineLg,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Nous avons envoyÃƒÂ© un lien de vÃƒÂ©rification ÃƒÂ  $email.',
                      textAlign: TextAlign.center,
                      style: AppTypography.bodyMd,
                    ),
                    if (_message != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _message!,
                        textAlign: TextAlign.center,
                        style: AppTypography.bodySm
                            .copyWith(color: AppColors.brandIndigo),
                      ),
                    ],
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _checkVerification,
                        child: const Text('JÃ¢â‚¬â„¢ai vÃƒÂ©rifiÃƒÂ© mon adresse'),
                      ),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton(
                      onPressed: _isLoading ? null : _resend,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        shape: const StadiumBorder(),
                      ),
                      child: const Text('Renvoyer le lien'),
                    ),
                    TextButton(
                      onPressed: () async {
                        await FirebaseAuth.instance.signOut();
                        if (context.mounted) {
                          Navigator.of(context).pop();
                        }
                      },
                      child: const Text('Changer dÃ¢â‚¬â„¢adresse / Retour'),
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
