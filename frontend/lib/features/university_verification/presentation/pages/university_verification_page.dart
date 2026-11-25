import 'dart:io';

import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../shared/widgets/smartcar_logo.dart';

class UniversityVerificationPage extends StatefulWidget {
  const UniversityVerificationPage({super.key});

  @override
  State<UniversityVerificationPage> createState() =>
      _UniversityVerificationPageState();
}

class _UniversityVerificationPageState
    extends State<UniversityVerificationPage> {
  final _formKey = GlobalKey<FormState>();
  final _studentIdController = TextEditingController();
  final _universityController =
      TextEditingController(text: 'Universite Ibn Zohr');
  final _facultyController = TextEditingController();
  final _departmentController = TextEditingController();
  XFile? _card;
  bool _loading = false;
  String? _error;
  Map<String, dynamic>? _status;

  String get _baseUrl => const String.fromEnvironment(
        'API_BASE_URL',
        defaultValue: kIsWeb
            ? 'http://127.0.0.1:3000/api/v1'
            : 'http://10.0.2.2:3000/api/v1',
      );

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  @override
  void dispose() {
    _studentIdController.dispose();
    _universityController.dispose();
    _facultyController.dispose();
    _departmentController.dispose();
    super.dispose();
  }

  Future<Dio> _dio() async {
    final token =
        await FirebaseAuth.instance.currentUser?.getIdToken(true);
    return Dio(BaseOptions(
      baseUrl: _baseUrl,
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    ));
  }

  Future<void> _loadStatus() async {
    setState(() => _loading = true);
    try {
      final response = await (await _dio()).get('/verification/status');
      setState(() {
        _status = Map<String, dynamic>.from(response.data['request'] as Map);
        _error = null;
      });
    } catch (_) {
      setState(() => _error = 'Unable to load verification status.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickCard(ImageSource source) async {
    final card = await ImagePicker().pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1600,
    );
    if (card == null) return;
    final bytes = await card.readAsBytes();
    if (bytes.lengthInBytes > 5 * 1024 * 1024) {
      setState(() => _error = 'Student card must be smaller than 5 MB.');
      return;
    }
    setState(() {
      _card = card;
      _error = null;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_card == null) {
      setState(() => _error = 'Select a student card image.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final dio = await _dio();
      final form = FormData.fromMap({
        'studentId': _studentIdController.text.trim(),
        'university': _universityController.text.trim(),
        'faculty': _facultyController.text.trim(),
        'department': _departmentController.text.trim(),
        'studentCard': await MultipartFile.fromFile(
          _card!.path,
          filename: _card!.name,
        ),
      });
      await dio.post('/verification/request', data: form);
      await _loadStatus();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Verification request submitted')),
        );
      }
    } on DioException catch (error) {
      final data = error.response?.data;
      setState(() {
        _error = data is Map && data['error'] is String
            ? data['error'] as String
            : 'Verification request could not be submitted.';
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _statusView() {
    final status = _status?['status']?.toString() ?? 'NOT_SUBMITTED';
    final reason = _status?['rejectionReason']?.toString();
    final title = switch (status) {
      'PENDING' => 'Verification pending',
      'APPROVED' => 'University verified',
      'REJECTED' => 'Verification rejected',
      'REQUIRES_RESUBMISSION' => 'Resubmission required',
      _ => 'Submit student verification',
    };
    final description = switch (status) {
      'PENDING' => 'An administrator is reviewing your student card.',
      'APPROVED' => 'Your university membership has been approved.',
      'REJECTED' => reason ?? 'Your card was rejected.',
      'REQUIRES_RESUBMISSION' => reason ?? 'Please upload a clearer student card.',
      _ => 'Upload your student card to complete university verification.',
    };
    final allowResubmit =
        status == 'NOT_SUBMITTED' ||
        status == 'REJECTED' ||
        status == 'REQUIRES_RESUBMISSION';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTypography.headlineLg),
        const SizedBox(height: 8),
        Text(description, style: AppTypography.bodyMd),
        if (!allowResubmit) ...[
          const SizedBox(height: 18),
          if (_status?['submittedAt'] != null)
            Text('Submitted: ${_status!['submittedAt']}',
                style: AppTypography.caption),
          if (_status?['reviewedAt'] != null)
            Text('Reviewed: ${_status!['reviewedAt']}',
                style: AppTypography.caption),
        ],
        if (allowResubmit) ...[
          const SizedBox(height: 20),
          Form(
            key: _formKey,
            child: Column(
              children: [
                _textField(_studentIdController, 'Student ID / Apogee number'),
                _textField(_universityController, 'University'),
                _textField(_facultyController, 'Faculty'),
                _textField(_departmentController, 'Department', required: false),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _loading
                            ? null
                            : () => _pickCard(ImageSource.gallery),
                        icon: const Icon(Icons.photo_library_outlined),
                        label: const Text('Gallery'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _loading
                            ? null
                            : () => _pickCard(ImageSource.camera),
                        icon: const Icon(Icons.photo_camera_outlined),
                        label: const Text('Camera'),
                      ),
                    ),
                  ],
                ),
                if (_card != null) ...[
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: kIsWeb
                        ? Image.network(_card!.path,
                            height: 220, fit: BoxFit.cover)
                        : Image.file(File(_card!.path),
                            height: 220, fit: BoxFit.cover),
                  ),
                ],
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _submit,
                    child: _loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Submit verification'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _textField(
    TextEditingController controller,
    String label, {
    bool required = true,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        validator: required
            ? (value) =>
                value == null || value.trim().isEmpty ? 'Required' : null
            : null,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SmartCarLogo(
              variant: SmartCarLogoVariant.iconOnly,
              symbolSize: 28,
            ),
            SizedBox(width: 8),
            Text('University verification'),
          ],
        ),
      ),
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_error != null)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.errorContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _error!,
                      style: TextStyle(color: AppColors.onErrorContainer),
                    ),
                  ),
                _statusView(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
