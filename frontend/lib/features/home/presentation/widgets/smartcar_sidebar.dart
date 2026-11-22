import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../authentication/presentation/providers/auth_provider.dart';
import '../../../trips/presentation/pages/my_trips_page.dart';
import '../../../trips/presentation/pages/publish_trip_page.dart';
import '../../../university_verification/presentation/pages/university_verification_page.dart';
import '../../../vehicles/presentation/vehicles_page.dart';

class SmartCarSidebar extends ConsumerWidget {
  const SmartCarSidebar({
    super.key,
    required this.selectedLabel,
  });

  final String selectedLabel;

  static const _primary = Color(0xFF0096FF);
  static const _primaryDark = Color(0xFF0877C9);
  static const _canvas = Color(0xFFF7F9FC);
  static const _ink = Color(0xFF263238);
  static const _muted = Color(0xFF888888);
  static const _border = Color(0xFFE8EDF2);

  void _closeAndPush(BuildContext context, Widget page) {
    Navigator.of(context).pop();
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => page),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final isDriver = user?.activeMode == 'DRIVER';
    final firstName = user?.displayName?.trim().isNotEmpty == true
        ? user!.displayName!.trim().split(' ').first
        : 'Utilisateur';

    return Drawer(
      width: 292,
      backgroundColor: _canvas,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 16, 14),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: _primary,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x1A0096FF),
                          blurRadius: 14,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.directions_car_filled_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SmartCar',
                          style: GoogleFonts.plusJakartaSans(
                            color: _ink,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            height: 1,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'Bonjour, $firstName',
                          style: GoogleFonts.inter(
                            color: _muted,
                            fontSize: 12,
                            height: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                    color: _ink,
                    tooltip: 'Fermer',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
                children: [
                  _SidebarItem(
                    icon: Icons.space_dashboard_rounded,
                    label: 'Tableau de bord',
                    selected: selectedLabel == 'Tableau de bord',
                    onTap: () => Navigator.of(context).pop(),
                  ),
                  _SidebarItem(
                    icon: Icons.route_rounded,
                    label: 'Mes trajets',
                    selected: selectedLabel == 'Mes trajets',
                    onTap: () => _closeAndPush(context, const MyTripsPage()),
                  ),
                  _SidebarItem(
                    icon: Icons.verified_user_rounded,
                    label: 'Vérification universitaire',
                    selected: selectedLabel == 'Vérification universitaire',
                    onTap: () => _closeAndPush(
                      context,
                      const UniversityVerificationPage(),
                    ),
                  ),
                  if (isDriver) ...[
                    _SidebarItem(
                      icon: Icons.add_road_rounded,
                      label: 'Publier un trajet',
                      selected: selectedLabel == 'Publier un trajet',
                      onTap: () => _closeAndPush(
                        context,
                        const PublishTripPage(),
                      ),
                    ),
                    _SidebarItem(
                      icon: Icons.directions_car_rounded,
                      label: 'Mes véhicules',
                      selected: selectedLabel == 'Mes véhicules',
                      onTap: () => _closeAndPush(
                        context,
                        const VehiclesPage(),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: _ModeSwitchCard(
                isDriver: isDriver,
                isLoading: authState.isLoading,
                onSwitch: () async {
                  Navigator.of(context).pop();
                  await _switchMode(context, ref);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
              child: InkWell(
                onTap: () async {
                  await ref.read(authProvider.notifier).signOut();
                  if (!context.mounted) return;
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _border),
                    color: Colors.white,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.logout_rounded,
                        size: 19,
                        color: _ink,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Se déconnecter',
                        style: GoogleFonts.plusJakartaSans(
                          color: _ink,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _switchMode(BuildContext context, WidgetRef ref) async {
    final user = ref.read(authProvider).user;
    if (user == null) return;

    if (user.activeMode == 'DRIVER') {
      await ref.read(authProvider.notifier).switchMode('PASSENGER');
      return;
    }

    if (!user.isUniversityVerified) {
      if (!context.mounted) return;
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('Vérification requise'),
          content: const Text(
            'Votre compte doit être approuvé par l’administration avant de passer en mode conducteur.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Plus tard'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const UniversityVerificationPage(),
                  ),
                );
              },
              child: const Text('Voir la vérification'),
            ),
          ],
        ),
      );
      return;
    }

    if (user.role == 'DRIVER' && user.driverProfile != null) {
      await ref.read(authProvider.notifier).switchMode('DRIVER');
      return;
    }

    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text('Activer le mode conducteur'),
        content: const Text(
          'Complétez les informations du conducteur et du véhicule pour continuer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
            },
            child: const Text('Continuer'),
          ),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: selected ? const Color(0x140096FF) : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            height: 48,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Icon(
                    icon,
                    size: 21,
                    color: selected
                        ? const Color(0xFF0877C9)
                        : const Color(0xFF263238),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      label,
                      style: GoogleFonts.plusJakartaSans(
                        color: selected
                            ? const Color(0xFF0877C9)
                            : const Color(0xFF263238),
                        fontSize: 13,
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w600,
                      ),
                    ),
                  ),
                  if (selected)
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF0096FF),
                        shape: BoxShape.circle,
                      ),
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

class _ModeSwitchCard extends StatelessWidget {
  const _ModeSwitchCard({
    required this.isDriver,
    required this.isLoading,
    required this.onSwitch,
  });

  final bool isDriver;
  final bool isLoading;
  final VoidCallback onSwitch;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8EDF2)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D0096FF),
            blurRadius: 14,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0x1A0096FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isDriver
                      ? Icons.directions_car_rounded
                      : Icons.person_rounded,
                  color: const Color(0xFF0877C9),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isDriver ? 'Mode conducteur' : 'Mode passager',
                      style: GoogleFonts.plusJakartaSans(
                        color: const Color(0xFF263238),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      isDriver ? 'Gérer vos trajets' : 'Trouver un trajet',
                      style: GoogleFonts.inter(
                        color: const Color(0xFF888888),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: isLoading ? null : onSwitch,
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: const Color(0xFF0096FF),
                foregroundColor: Colors.white,
                shape: const StadiumBorder(),
              ),
              child: Text(
                isDriver
                    ? 'Passer en mode passager'
                    : 'Passer en mode conducteur',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
