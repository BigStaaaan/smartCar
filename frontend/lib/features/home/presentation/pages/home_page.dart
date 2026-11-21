import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(authProvider.notifier).refreshProfile());
  }

  Future<void> _verifyUniversity() async {
    final success =
        await ref.read(authProvider.notifier).verifyUniversity();
    if (!mounted) return;
    final message = ref.read(authProvider).errorMessage ??
        (success
            ? 'University verification completed.'
            : 'University verification failed.');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success ? AppColors.success : AppColors.error,
      ),
    );
  }

  Future<void> _switchMode() async {
    final user = ref.read(authProvider).user;
    if (user == null) return;

    if (user.activeMode == 'DRIVER') {
      final success =
          await ref.read(authProvider.notifier).switchMode('PASSENGER');
      if (!mounted) return;
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Passenger Mode activated')),
        );
      }
      return;
    }

    if (!user.isUniversityVerified) {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('University verification required'),
          content: const Text(
            'Verify your university email before activating Driver Mode.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await _verifyUniversity();
              },
              child: const Text('Verify university'),
            ),
          ],
        ),
      );
      return;
    }

    if (user.role == 'DRIVER' && user.driverProfile != null) {
      final success =
          await ref.read(authProvider.notifier).switchMode('DRIVER');
      if (!mounted) return;
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Driver Mode activated')),
        );
      }
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => _DriverActivationDialog(
        onSubmit: () async {
          Navigator.of(dialogContext).pop();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final isDriver = user?.activeMode == 'DRIVER';

    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: Drawer(
        backgroundColor: AppColors.surfaceContainerLowest,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SmartCar',
                  style: AppTypography.headlineMd,
                ),
                const SizedBox(height: 6),
                Text(
                  user?.displayName ?? user?.email ?? 'Campus carpool',
                  style: AppTypography.bodySm,
                ),
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDriver
                        ? AppColors.primaryFixed
                        : AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isDriver
                            ? Icons.directions_car_rounded
                            : Icons.person_rounded,
                        color: AppColors.brandIndigo,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isDriver ? 'Driver Mode' : 'Passenger Mode',
                              style: AppTypography.labelMd,
                            ),
                            Text(
                              isDriver
                                  ? 'Publish and manage trips'
                                  : 'Find rides and book seats',
                              style: AppTypography.caption,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: authState.isLoading ? null : _switchMode,
                    icon: Icon(
                      isDriver
                          ? Icons.person_rounded
                          : Icons.directions_car_rounded,
                    ),
                    label: Text(
                      isDriver
                          ? 'Switch to Passenger Mode'
                          : user?.role == 'DRIVER'
                              ? 'Switch to Driver Mode'
                              : 'Switch to Driver Mode',
                    ),
                  ),
                ),
                const Spacer(),
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.logout_rounded),
                  title: const Text('Sign out'),
                  onTap: () async {
                    await ref.read(authProvider.notifier).signOut();
                    if (context.mounted) {
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      appBar: AppBar(
        title: Text(
          isDriver ? 'Driver Dashboard' : 'Passenger Dashboard',
          style: AppTypography.headlineSm,
        ),
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      body: isDriver ? const _DriverDashboard() : const _PassengerDashboard(),
    );
  }
}

class _PassengerDashboard extends StatelessWidget {
  const _PassengerDashboard();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('Find a campus ride', style: AppTypography.headlineLg),
        const SizedBox(height: 8),
        Text(
          'Browse trips, reserve seats and manage your ride history.',
          style: AppTypography.bodyMd,
        ),
        const SizedBox(height: 20),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.route_rounded, color: AppColors.brandIndigo),
              SizedBox(height: 12),
              Text('No trips available yet'),
            ],
          ),
        ),
      ],
    );
  }
}

class _DriverDashboard extends StatelessWidget {
  const _DriverDashboard();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('Manage campus trips', style: AppTypography.headlineLg),
        const SizedBox(height: 8),
        Text(
          'Publish trips, adjust available seats and respond to reservations.',
          style: AppTypography.bodyMd,
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.add_rounded),
            label: const Text('Publish a trip'),
          ),
        ),
      ],
    );
  }
}

class _DriverActivationDialog extends ConsumerStatefulWidget {
  const _DriverActivationDialog({required this.onSubmit});

  final VoidCallback onSubmit;

  @override
  ConsumerState<_DriverActivationDialog> createState() =>
      _DriverActivationDialogState();
}

class _DriverActivationDialogState
    extends ConsumerState<_DriverActivationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _licenseController = TextEditingController();
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  final _registrationController = TextEditingController();
  final _seatsController = TextEditingController(text: '3');

  @override
  void dispose() {
    _licenseController.dispose();
    _brandController.dispose();
    _modelController.dispose();
    _registrationController.dispose();
    _seatsController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final success =
        await ref.read(authProvider.notifier).activateDriver({
      'drivingLicense': _licenseController.text,
      'vehicleBrand': _brandController.text,
      'vehicleModel': _modelController.text,
      'vehicleRegistration': _registrationController.text,
      'availableSeats': int.parse(_seatsController.text),
    });
    if (!mounted) return;
    if (success) {
      widget.onSubmit();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Driver Mode activated')),
      );
    } else {
      final message = ref.read(authProvider).errorMessage ??
          'Driver information could not be saved.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authProvider).isLoading;
    return AlertDialog(
      title: const Text('Activate Driver Mode'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _DriverField(
                controller: _licenseController,
                label: 'Driving license',
              ),
              _DriverField(
                controller: _brandController,
                label: 'Vehicle brand',
              ),
              _DriverField(
                controller: _modelController,
                label: 'Vehicle model',
              ),
              _DriverField(
                controller: _registrationController,
                label: 'Vehicle registration',
              ),
              _DriverField(
                controller: _seatsController,
                label: 'Available seats',
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: isLoading ? null : _submit,
          child: isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Activate'),
        ),
      ],
    );
  }
}

class _DriverField extends StatelessWidget {
  const _DriverField({
    required this.controller,
    required this.label,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String label;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Required';
          }
          if (keyboardType == TextInputType.number) {
            final seats = int.tryParse(value);
            if (seats == null || seats < 1 || seats > 8) {
              return 'Enter 1 to 8 seats';
            }
          }
          return null;
        },
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
