import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../shared/widgets/smartcar_logo.dart';
import '../../../authentication/presentation/pages/login_page.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';
import '../../../profile/presentation/pages/edit_profile_page.dart';
import '../../../trips/presentation/pages/my_trips_page.dart';
import '../../../university_verification/presentation/pages/university_verification_page.dart';

class SmartCarSidebar extends ConsumerWidget {
  const SmartCarSidebar({
    super.key,
    required this.selectedLabel,
    this.isPersistent = false,
    this.onSwitchMode,
  });

  final String selectedLabel;
  final bool isPersistent;
  final VoidCallback? onSwitchMode;

  void _navigateTo(BuildContext context, Widget page) {
    if (!isPersistent) {
      Navigator.of(context).pop();
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => page),
    );
  }

  void _showPlaceholder(BuildContext context, String title) {
    if (!isPersistent) {
      Navigator.of(context).pop();
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$title is coming soon.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _confirmDisconnect(BuildContext context, WidgetRef ref) async {
    final shouldDisconnect = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        actionsAlignment: MainAxisAlignment.center,
        title: const Text('Disconnect'),
        content: const Text(
          'Are you sure you want to disconnect from your SmartCar account?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Stay Connected'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Disconnect'),
          ),
        ],
      ),
    );

    if (shouldDisconnect != true || !context.mounted) return;
    final navigator = Navigator.of(context, rootNavigator: true);
    final authNotifier = ref.read(authProvider.notifier);
    navigator.pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const LoginPage()),
      (_) => false,
    );
    try {
      await authNotifier.signOut();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    final rawName = user?.displayName?.trim() ?? '';
    final firstName =
        rawName.isNotEmpty ? rawName.split(RegExp(r'\s+')).first : 'Student';
    final email = user?.email ?? '';
    final photoUrl = user?.photoUrl;
    final isVerified = (user?.isUniversityVerified ?? false) ||
        (user?.isVerifiedStudent ?? false);
    final isDriver = user?.activeMode == 'DRIVER';

    final content = SafeArea(
      child: Column(
        children: [
          // Header: Logo + User Info
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const SmartCarLogo(
                      variant: SmartCarLogoVariant.horizontal,
                      symbolSize: 28,
                      wordmarkFontSize: 18,
                    ),
                    const Spacer(),
                    if (!isPersistent)
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded),
                        color: AppColors.onSurface,
                        tooltip: 'Close',
                      ),
                  ],
                ),
                const SizedBox(height: 18),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _navigateTo(context, const EditProfilePage()),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.surfaceStroke),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor:
                                AppColors.primary.withValues(alpha: 0.12),
                            backgroundImage:
                                (photoUrl != null && photoUrl.isNotEmpty)
                                    ? NetworkImage(photoUrl)
                                    : null,
                            child: (photoUrl == null || photoUrl.isEmpty)
                                ? Text(
                                    firstName.isNotEmpty
                                        ? firstName[0].toUpperCase()
                                        : 'S',
                                    style: AppTypography.bodyLg.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        firstName,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppTypography.bodyLg.copyWith(
                                          color: AppColors.onSurface,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    if (isVerified) ...[
                                      const SizedBox(width: 4),
                                      const Icon(
                                        Icons.verified_rounded,
                                        size: 16,
                                        color: AppColors.primary,
                                      ),
                                    ],
                                  ],
                                ),
                                if (email.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    email,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.bodySm.copyWith(
                                      color: AppColors.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right_rounded,
                            size: 18,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: AppColors.surfaceStroke),
          const SizedBox(height: 8),

          // Navigation Items (exact required order)
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              children: [
                _SidebarItem(
                  icon: Icons.person_outline_rounded,
                  label: 'profile',
                  selected: selectedLabel == 'profile',
                  onTap: () => _navigateTo(context, const EditProfilePage()),
                ),
                _SidebarItem(
                  icon: Icons.history_rounded,
                  label: 'History',
                  selected: selectedLabel == 'History',
                  onTap: () => _navigateTo(context, const MyTripsPage()),
                ),
                _SidebarItem(
                  icon: Icons.support_agent_rounded,
                  label: 'Support',
                  selected: selectedLabel == 'Support',
                  onTap: () => _showPlaceholder(context, 'Support'),
                ),
                _SidebarItem(
                  icon: Icons.help_outline_rounded,
                  label: 'FAQ',
                  selected: selectedLabel == 'FAQ',
                  onTap: () => _showPlaceholder(context, 'FAQ'),
                ),
                _SidebarItem(
                  icon: Icons.settings_rounded,
                  label: 'Settings',
                  selected: selectedLabel == 'Settings',
                  onTap: () => _showPlaceholder(context, 'Settings'),
                ),
                _SidebarItem(
                  icon: Icons.school_rounded,
                  label: 'Edu',
                  selected: selectedLabel == 'Edu',
                  onTap: () => _navigateTo(
                    context,
                    const UniversityVerificationPage(),
                  ),
                ),
              ],
            ),
          ),

          // Dedicated Passenger / Driver Mode Switch
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.surfaceStroke),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          isDriver
                              ? Icons.directions_car_rounded
                              : Icons.person_rounded,
                          color: AppColors.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          isDriver ? 'Driver Mode' : 'Passenger Mode',
                          style: AppTypography.bodyMd.copyWith(
                            color: AppColors.onSurface,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: FilledButton.icon(
                      onPressed: authState.isLoading
                          ? null
                          : () {
                              if (!isPersistent) {
                                Navigator.of(context).pop();
                              }
                              if (onSwitchMode != null) {
                                onSwitchMode!();
                              } else {
                                ref.read(authProvider.notifier).switchMode(
                                      isDriver ? 'PASSENGER' : 'DRIVER',
                                    );
                              }
                            },
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: Icon(
                        isDriver
                            ? Icons.person_rounded
                            : Icons.directions_car_rounded,
                        size: 18,
                      ),
                      label: Text(
                        isDriver
                            ? 'Switch to Passenger Mode'
                            : 'Switch to Driver Mode',
                        style: AppTypography.bodySm.copyWith(
                          color: AppColors.onPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Disconnect button under Passenger / Driver Mode
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
            child: SizedBox(
              width: double.infinity,
              height: 44,
              child: OutlinedButton.icon(
                onPressed: authState.isLoading
                    ? null
                    : () => _confirmDisconnect(context, ref),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.logout_rounded, size: 18),
                label: Text(
                  'Disconnect',
                  style: AppTypography.bodySm.copyWith(
                    color: AppColors.error,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    if (isPersistent) {
      return Container(
        width: 280,
        decoration: const BoxDecoration(
          color: AppColors.surfaceContainerLow,
          border: Border(
            right: BorderSide(color: AppColors.surfaceStroke),
          ),
        ),
        child: content,
      );
    }

    return Drawer(
      width: 292,
      backgroundColor: AppColors.surfaceContainerLow,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(24)),
      ),
      child: content,
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
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.primary.withValues(alpha: 0.12)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 22,
                  color: selected
                      ? AppColors.primary
                      : AppColors.onSurfaceVariant,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: AppTypography.bodyMd.copyWith(
                      color: selected
                          ? AppColors.primary
                          : AppColors.onSurface,
                      fontWeight:
                          selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
