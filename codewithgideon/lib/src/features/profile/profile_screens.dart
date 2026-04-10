import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/data/demo_data.dart';
import '../../core/state/app_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_controls.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/states/app_state_widgets.dart';
import '../home/models/student_dashboard_snapshot.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardState = ref.watch(dashboardSnapshotProvider);

    return dashboardState.when(
      loading: () => const SafeArea(
        top: false,
        child: AppLoadingState(
          compact: true,
          title: 'Loading your profile...',
          message: 'Syncing your student details and cohort access.',
        ),
      ),
      error: (error, _) => SafeArea(
        top: false,
        child: AppErrorState(
          compact: true,
          title: 'Profile unavailable',
          message: 'We could not load your profile right now.',
          onRetry: () => ref.refresh(dashboardSnapshotProvider),
        ),
      ),
      data: (dashboard) {
        final profile = dashboard.profile;
        final initials = _initialsFromName(profile.fullName);

        return SafeArea(
          top: false,
          bottom: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(22, 30, 22, 130),
            children: [
              PremiumPageHeader(
                title: 'Profile',
                subtitle:
                    'Your learning identity, cohort access, and account details in one premium view.',
                trailing: PremiumIconButton(
                  icon: Icons.settings_rounded,
                  onTap: () => context.push('/settings'),
                ),
              ),
              const Gap(12),
              AppCard(
                radius: 30,
                color: Theme.of(context).cardColor.withValues(alpha: 0.82),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 74,
                          height: 74,
                          decoration: const BoxDecoration(
                            gradient: AppGradients.accent,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            initials.isEmpty ? 'C' : initials,
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
                        const Gap(16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                profile.fullName,
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              const Gap(6),
                              Text(
                                profile.email,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(color: _muted(context)),
                              ),
                              const Gap(4),
                              Text(
                                '${dashboard.path.title} • ${dashboard.activeCohort.label}',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: _muted(context)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Gap(18),
                    AdaptiveWrap(
                      minItemWidth: 150,
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _InfoTile(
                          label: 'Phone',
                          value: profile.phone,
                          icon: Icons.call_outlined,
                        ),
                        _InfoTile(
                          label: 'Joined',
                          value: DateFormat(
                            'MMM d, y',
                          ).format(profile.joinedAt),
                          icon: Icons.event_available_rounded,
                        ),
                        _InfoTile(
                          label: 'Weeks Paid',
                          value:
                              '${profile.weeksToCommit}/${dashboard.totalProgramWeeks}',
                          icon: Icons.timelapse_rounded,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Gap(16),
              AppCard(
                radius: 28,
                color: Theme.of(context).cardColor.withValues(alpha: 0.82),
                child: Column(
                  children: [
                    _ProfileAction(
                      icon: Icons.edit_outlined,
                      title: 'Edit profile',
                      subtitle: 'Update your name and phone number',
                      onTap: () => context.push('/profile/edit'),
                    ),
                    const Divider(height: 22),
                    _ProfileAction(
                      icon: Icons.workspace_premium_outlined,
                      title: 'Certificates',
                      subtitle: 'See badges and progress milestones',
                      onTap: () => context.push('/certificates'),
                    ),
                    const Divider(height: 22),
                    _ProfileAction(
                      icon: Icons.settings_outlined,
                      title: 'Settings',
                      subtitle: 'Notifications, theme, and app preferences',
                      onTap: () => context.push('/settings'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class CertificatesScreen extends StatelessWidget {
  const CertificatesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScreen(
      body: SafeArea(
        top: false,
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 30, 22, 28),
          children: [
            PremiumPageHeader(
              title: 'Achievements',
              subtitle: 'Your milestones, certificates, and earned progress.',
              leading: PremiumIconButton(
                icon: Icons.arrow_back_rounded,
                onTap: () => context.pop(),
              ),
            ),
            const Gap(16),
            for (final item in DemoData.certificates) ...[
              AppCard(
                radius: 28,
                color: Theme.of(context).cardColor.withValues(alpha: 0.82),
                child: Column(
                  children: [
                    Text(
                      item.title,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Gap(8),
                    Text(
                      'Instructor: ${item.instructor}',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: _muted(context)),
                    ),
                    const Gap(4),
                    Text(
                      'Issued ${item.issueDate}',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: _muted(context)),
                    ),
                  ],
                ),
              ),
              const Gap(12),
            ],
          ],
        ),
      ),
    );
  }
}

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final authState = ref.read(authControllerProvider);
    final dashboard = _dashboardSnapshotOrNull(
      ref.read(dashboardSnapshotProvider),
    );
    _nameController = TextEditingController(
      text: dashboard?.profile.fullName ?? authState.session?.email ?? '',
    );
    _phoneController = TextEditingController(
      text: dashboard?.profile.phone ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final session = ref.read(authControllerProvider).session;
    if (session == null) return;
    setState(() => _isSaving = true);
    await ref
        .read(studentRepositoryProvider)
        .updateStudentProfile(
          uid: session.uid,
          fullName: _nameController.text,
          phone: _phoneController.text,
        );
    ref.invalidate(dashboardSnapshotProvider);
    if (!mounted) return;
    setState(() => _isSaving = false);
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final dashboard = _dashboardSnapshotOrNull(
      ref.watch(dashboardSnapshotProvider),
    );

    return AppScreen(
      body: SafeArea(
        top: false,
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 30, 22, 28),
          children: [
            PremiumPageHeader(
              title: 'Edit Profile',
              subtitle: 'Keep your personal details polished and up to date.',
              leading: PremiumIconButton(
                icon: Icons.arrow_back_rounded,
                onTap: () => context.pop(),
              ),
            ),
            const Gap(20),
            AppCard(
              radius: 28,
              color: Theme.of(context).cardColor.withValues(alpha: 0.82),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppTextField(label: 'Full name', controller: _nameController),
                  const Gap(16),
                  AppTextField(
                    label: 'Phone number',
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                  ),
                  const Gap(16),
                  Text(
                    'Email',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Gap(10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).inputDecorationTheme.fillColor,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Text(
                      dashboard?.profile.email ?? '',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyLarge?.copyWith(color: _muted(context)),
                    ),
                  ),
                  const Gap(20),
                  AppButton(
                    label: 'Save changes',
                    isLoading: _isSaving,
                    onPressed: _isSaving ? null : _save,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final controller = ref.read(settingsProvider.notifier);

    return AppScreen(
      body: SafeArea(
        top: false,
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 30, 22, 28),
          children: [
            PremiumPageHeader(
              title: 'Settings',
              subtitle: 'Tune notifications, appearance, and everyday app behavior.',
              leading: PremiumIconButton(
                icon: Icons.arrow_back_rounded,
                onTap: () => context.pop(),
              ),
            ),
            const Gap(18),
            AppCard(
              radius: 28,
              color: Theme.of(context).cardColor.withValues(alpha: 0.82),
              child: Column(
                children: [
                  _SettingsRow(
                    icon: Icons.notifications_none_rounded,
                    title: 'Notifications',
                    subtitle: 'Live class updates and admin approvals',
                    trailing: Switch.adaptive(
                      value: settings.notifications,
                      onChanged: (_) => controller.toggleNotifications(),
                    ),
                  ),
                  const Divider(height: 22),
                  _SettingsRow(
                    icon: Icons.dark_mode_outlined,
                    title: 'Dark mode',
                    subtitle: settings.darkMode
                        ? 'Currently using the dark theme'
                        : 'Currently using the light theme',
                    trailing: Switch.adaptive(
                      value: settings.darkMode,
                      onChanged: (_) => controller.toggleDarkMode(),
                    ),
                  ),
                ],
              ),
            ),
            const Gap(18),
            AppCard(
              radius: 28,
              color: Theme.of(context).cardColor.withValues(alpha: 0.82),
              child: Column(
                children: [
                  BrandWordmark(
                    height: 22,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.darkForeground
                        : AppColors.deepBlueDark,
                  ),
                  const Gap(6),
                  Text(
                    'Version 1.0.0',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: _muted(context)),
                  ),
                ],
              ),
            ),
            const Gap(20),
            AppButton(
              label: 'Logout',
              variant: AppButtonVariant.danger,
              leading: const Icon(Icons.logout_rounded, color: Colors.white),
              onPressed: () async {
                await ref.read(authControllerProvider.notifier).logout();
                if (!context.mounted) return;
                context.go('/welcome');
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkMuted.withValues(alpha: 0.82)
            : AppColors.muted.withValues(alpha: 0.76),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.tealDark),
          const Gap(10),
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: _muted(context),
              fontWeight: FontWeight.w600,
            ),
          ),
          const Gap(6),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _ProfileAction extends StatelessWidget {
  const _ProfileAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.teal.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: AppColors.tealDark),
            ),
            const Gap(14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Gap(4),
                  Text(
                    subtitle,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: _muted(context)),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.deepBlue.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: AppColors.deepBlue),
        ),
        const Gap(14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const Gap(4),
              Text(
                subtitle,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: _muted(context)),
              ),
            ],
          ),
        ),
        const Gap(12),
        trailing,
      ],
    );
  }
}

Color _muted(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark
      ? AppColors.darkMutedForeground
      : AppColors.mutedForeground;
}

String _initialsFromName(String value) {
  final parts = value
      .split(' ')
      .where((part) => part.trim().isNotEmpty)
      .take(2);
  return parts.map((part) => part.trim().substring(0, 1).toUpperCase()).join();
}

StudentDashboardSnapshot? _dashboardSnapshotOrNull(
  AsyncValue<StudentDashboardSnapshot> value,
) {
  return value.maybeWhen(data: (snapshot) => snapshot, orElse: () => null);
}
