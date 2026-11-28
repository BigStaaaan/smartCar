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
  final _universityEmailController = TextEditingController();
  final _universitySearchController = TextEditingController();

  String _accountType = 'student';
  List<Map<String, dynamic>> _universities = [];
  Map<String, dynamic>? _selectedUniversity;
  XFile? _card;
  Uint8List? _cardBytes;
  bool _loading = false;
  bool _isEditingDeclined = false;
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
    _loadInitialData();
  }

  @override
  void dispose() {
    _universityEmailController.dispose();
    _universitySearchController.dispose();
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

  Future<void> _loadInitialData() async {
    setState(() => _loading = true);
    try {
      final dio = await _dio();
      final results = await Future.wait([
        dio.get('/verification/status'),
        dio.get('/verification/universities'),
      ]);
      final reqData = results[0].data['request'];
      final uniList = List<Map<String, dynamic>>.from(
        (results[1].data['universities'] as List?) ?? [],
      );
      setState(() {
        _universities = uniList;
        _status = reqData is Map ? Map<String, dynamic>.from(reqData) : null;
        _prefillFromStatus();
        _error = null;
      });
    } catch (_) {
      setState(() => _error = 'Impossible de charger le statut de vérification.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _prefillFromStatus() {
    if (_status == null) return;
    final accType = _status!['accountType']?.toString().toLowerCase();
    if (accType == 'student' || accType == 'staff') {
      _accountType = accType!;
    }
    final email = _status!['universityEmail']?.toString();
    if (email != null && email.isNotEmpty) {
      _universityEmailController.text = email;
    }
    final uniId = _status!['universityId']?.toString();
    final uniName = _status!['university']?.toString();
    if (uniId != null) {
      final match = _universities.where((u) => u['id'] == uniId).toList();
      if (match.isNotEmpty) _selectedUniversity = match.first;
    } else if (uniName != null) {
      final match = _universities.where((u) => u['name'] == uniName).toList();
      if (match.isNotEmpty) _selectedUniversity = match.first;
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
      setState(() => _error = 'Le document doit faire moins de 5 Mo.');
      return;
    }
    setState(() {
      _card = card;
      _cardBytes = bytes;
      _error = null;
    });
  }

  Future<void> _openUniversityPicker() async {
    _universitySearchController.clear();
    final picked = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final query = _universitySearchController.text.trim().toLowerCase();
            final filtered = _universities.where((u) {
              final name = (u['name'] ?? '').toString().toLowerCase();
              return name.contains(query);
            }).toList();
            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.7,
              maxChildSize: 0.9,
              builder: (_, scrollController) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Sélectionner votre université',
                        style: AppTypography.headlineSm,
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _universitySearchController,
                        decoration: const InputDecoration(
                          hintText: 'Rechercher une université...',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (_) => setModalState(() {}),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: filtered.isEmpty
                            ? const Center(
                                child: Text('Aucune université trouvée.'),
                              )
                            : ListView.builder(
                                controller: scrollController,
                                itemCount: filtered.length,
                                itemBuilder: (_, index) {
                                  final uni = filtered[index];
                                  return ListTile(
                                    title: Text(uni['name'].toString()),
                                    trailing: _selectedUniversity?['id'] == uni['id']
                                        ? const Icon(Icons.check, color: AppColors.primary)
                                        : null,
                                    onTap: () => Navigator.of(ctx).pop(uni),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedUniversity = picked;
        _error = null;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedUniversity == null) {
      setState(() => _error = 'Veuillez sélectionner votre université.');
      return;
    }
    if (_card == null) {
      setState(() => _error = 'Veuillez importer votre carte universitaire.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final dio = await _dio();
      final form = FormData.fromMap({
        'accountType': _accountType,
        'universityId': _selectedUniversity!['id'],
        'university': _selectedUniversity!['name'],
        'universityEmail': _universityEmailController.text.trim(),
        'studentCard': kIsWeb
            ? MultipartFile.fromBytes(_cardBytes!, filename: _card!.name)
            : await MultipartFile.fromFile(_card!.path, filename: _card!.name),
      });
      await dio.post('/verification/request', data: form);
      _isEditingDeclined = false;
      await _loadInitialData();
      if (mounted) {
        await showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Vérification en cours'),
            content: const Text(
              'Votre demande de vérification a été envoyée. Notre équipe Support examine actuellement vos informations. Vous serez notifié dès qu\'une décision sera prise.',
            ),
            actions: [
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Compris'),
              ),
            ],
          ),
        );
      }
    } on DioException catch (error) {
      final data = error.response?.data;
      setState(() {
        _error = data is Map && data['error'] is String
            ? data['error'] as String
            : 'Impossible d\'envoyer la demande de vérification.';
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
    }
  }

  String _normalizedStatus() {
    final raw = _status?['status']?.toString().toLowerCase() ?? 'not_submitted';
    if (raw == 'approved') return 'approved';
    if (raw == 'pending') return 'pending';
    if (raw == 'declined' || raw == 'rejected' || raw == 'requires_resubmission') {
      return 'declined';
    }
    return 'not_submitted';
  }

  Widget _buildStatusBanner(String status) {
    if (status == 'pending') {
      final submittedAt = _status?['submittedAt']?.toString() ?? '';
      return Card(
        color: AppColors.surfaceContainerLow,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.hourglass_top_rounded, color: AppColors.primary, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text('Vérification en cours', style: AppTypography.headlineSm),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Votre demande de vérification a été envoyée. Notre équipe Support examine actuellement vos informations.',
                style: AppTypography.bodyMd,
              ),
              if (submittedAt.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Date de soumission : ${submittedAt.split('T').first}',
                  style: AppTypography.bodySm.copyWith(color: AppColors.onSurfaceVariant),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: _loading ? null : _loadInitialData,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Actualiser'),
                  ),
                  const SizedBox(width: 12),
                  TextButton.icon(
                    onPressed: _logout,
                    icon: const Icon(Icons.logout),
                    label: const Text('Se déconnecter'),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    if (status == 'approved') {
      return Card(
        color: AppColors.surfaceContainerLow,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.verified_rounded, color: Colors.green, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text('Identité vérifiée', style: AppTypography.headlineSm),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Félicitations ! Votre identité universitaire a été vérifiée. Vous pouvez maintenant accéder à toutes les fonctionnalités de SmartCar.',
                style: AppTypography.bodyMd,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => Navigator.of(context).pushReplacementNamed('/home'),
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Accéder à SmartCar'),
              ),
            ],
          ),
        ),
      );
    }

    if (status == 'declined' && !_isEditingDeclined) {
      final reason = _status?['rejectionReason']?.toString() ?? 'Document non conforme.';
      return Card(
        color: AppColors.errorContainer.withValues(alpha: 0.35),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text('Demande refusée', style: AppTypography.headlineSm),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Votre demande de vérification n\'a pas été acceptée. Consultez le motif du refus, corrigez vos informations et soumettez une nouvelle demande.',
                style: AppTypography.bodyMd,
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.error.withValues(alpha: 0.4)),
                ),
                child: Text(
                  'Motif : $reason',
                  style: AppTypography.bodyMd.copyWith(color: AppColors.error),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  FilledButton.icon(
                    onPressed: () => setState(() => _isEditingDeclined = true),
                    icon: const Icon(Icons.edit),
                    label: const Text('Corriger mes informations'),
                  ),
                  const SizedBox(width: 12),
                  TextButton.icon(
                    onPressed: _logout,
                    icon: const Icon(Icons.logout),
                    label: const Text('Se déconnecter'),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _isEditingDeclined
                ? 'Corriger et soumettre à nouveau'
                : 'Vérification de l\'identité universitaire',
            style: AppTypography.headlineMd,
          ),
          const SizedBox(height: 8),
          Text(
            'Veuillez renseigner vos informations universitaires et importer votre carte d\'étudiant ou de personnel.',
            style: AppTypography.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: 20),
          Text('Type de compte', style: AppTypography.labelMd),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'student', label: Text('Étudiant'), icon: Icon(Icons.school)),
              ButtonSegment(value: 'staff', label: Text('Personnel'), icon: Icon(Icons.badge)),
            ],
            selected: {_accountType},
            onSelectionChanged: (val) => setState(() => _accountType = val.first),
          ),
          const SizedBox(height: 16),
          Text('Université', style: AppTypography.labelMd),
          const SizedBox(height: 8),
          InkWell(
            onTap: _openUniversityPicker,
            borderRadius: BorderRadius.circular(12),
            child: InputDecorator(
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.account_balance),
                suffixIcon: Icon(Icons.arrow_drop_down),
              ),
              child: Text(
                _selectedUniversity?['name']?.toString() ?? 'Sélectionner une université',
                style: _selectedUniversity == null
                    ? AppTypography.bodyMd.copyWith(color: AppColors.onSurfaceVariant)
                    : AppTypography.bodyMd,
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _universityEmailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Adresse e-mail universitaire',
              hintText: 'prenom.nom@univ.dz',
              prefixIcon: Icon(Icons.alternate_email),
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              final email = (value ?? '').trim().toLowerCase();
              if (email.isEmpty || !email.contains('@') || !email.contains('.')) {
                return 'Veuillez saisir une adresse e-mail universitaire valide.';
              }
              final domains = (_selectedUniversity?['emailDomains'] as List?)
                      ?.map((e) => e.toString().toLowerCase())
                      .toList() ??
                  [];
              if (domains.isNotEmpty) {
                final emailDomain = email.split('@').last;
                final ok = domains.any((d) => emailDomain == d || emailDomain.endsWith('.$d'));
                if (!ok) {
                  return 'Domaine attendu : ${domains.join(', ')}';
                }
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          Text('Document d\'identification universitaire (JPG, PNG)', style: AppTypography.labelMd),
          const SizedBox(height: 8),
          if (_cardBytes != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: kIsWeb
                  ? Image.memory(_cardBytes!, height: 180, fit: BoxFit.cover)
                  : Image.file(File(_card!.path), height: 180, fit: BoxFit.cover),
            ),
            const SizedBox(height: 8),
          ],
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _loading ? null : () => _pickCard(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library_outlined),
                  label: Text(_card == null ? 'Importer une image' : 'Remplacer l\'image'),
                ),
              ),
              if (!kIsWeb) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _loading ? null : () => _pickCard(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt_outlined),
                    label: const Text('Prendre une photo'),
                  ),
                ),
              ],
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: 16),
            Text(_error!, style: AppTypography.bodySm.copyWith(color: AppColors.error)),
          ],
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _loading ? null : _submit,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: _loading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Soumettre pour vérification'),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
            label: const Text('Se déconnecter'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final status = _normalizedStatus();
    final showForm = status == 'not_submitted' || (status == 'declined' && _isEditingDeclined);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const SmartCarLogo(
          variant: SmartCarLogoVariant.horizontal,
          symbolSize: 28,
          wordmarkFontSize: 20,
        ),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
            tooltip: 'Se déconnecter',
          ),
        ],
      ),
      body: SafeArea(
        child: _loading && _status == null
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: showForm ? _buildForm() : _buildStatusBanner(status),
                  ),
                ),
              ),
      ),
    );
  }
}
