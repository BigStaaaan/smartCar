import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../shared/widgets/smartcar_logo.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';
import '../../../trips/presentation/pages/my_trips_page.dart';
import '../../../university_verification/presentation/pages/university_verification_page.dart';

class SmartCarSidebar extends ConsumerWidget {
  const SmartCarSidebar({
    super.key,
    required this.selectedLabel,
    this.isPersistent = false,
  });

  final String selectedLabel;
  final bool isPersistent;

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
                Container(
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
                        backgroundColor: AppColors.primary.withValues(alpha: 0.12),
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
                    ],
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
                  icon: Icons.space_dashboard_rounded,
                  label: 'Dashboard',
                  selected: selectedLabel == 'Dashboard',
                  onTap: () {
                    if (!isPersistent) Navigator.of(context).pop();
                  },
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
