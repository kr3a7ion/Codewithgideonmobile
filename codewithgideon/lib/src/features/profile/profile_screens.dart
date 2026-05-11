import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/state/app_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_controls.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/states/app_state_widgets.dart';
import '../home/models/student_dashboard_snapshot.dart';

const _settingsContactLinks = <({
  IconData icon,
  String title,
  String subtitle,
  String url,
})>[
  (
    icon: Icons.camera_alt_outlined,
    title: 'Instagram',
    subtitle: '@c0dewithgideon',
    url: 'https://www.instagram.com/c0dewithgideon',
  ),
  (
    icon: Icons.music_note_rounded,
    title: 'TikTok',
    subtitle: '@codewithgideon',
    url: 'https://www.tiktok.com/@codewithgideon',
  ),
  (
    icon: Icons.chat_bubble_outline_rounded,
    title: 'WhatsApp',
    subtitle: 'Direct chat with the team',
    url: 'https://api.whatsapp.com/message/NMQR2ZKNJTZBL1?autoload=1&app_absent=0',
  ),
];

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final dashboardState = ref.watch(dashboardSnapshotProvider);

    return dashboardState.when(
      loading: () => const DoubleBackToExitScope(
        child: SafeArea(
          top: false,
          child: AppLoadingState(
            compact: true,
            title: 'Loading your profile...',
            message: 'Syncing your student details and cohort access.',
          ),
        ),
      ),
      error: (error, _) => DoubleBackToExitScope(
        child: SafeArea(
          top: false,
          child: AppErrorState(
            compact: true,
            title: 'Profile unavailable',
            message: 'We could not load your profile right now.',
            onRetry: () => ref.refresh(dashboardSnapshotProvider),
          ),
        ),
      ),
      data: (dashboard) {
        final profile = dashboard.profile;
        final initials = _initialsFromName(profile.fullName);
        final progressPercent = (dashboard.progressPercent * 100).round();
        final joinedLabel = DateFormat('MMM d, y').format(profile.joinedAt);
        final memberStatus = dashboard.hasAnyPending
            ? 'Pending access'
            : 'Active member';
        final memberStatusColor = dashboard.hasAnyPending
            ? AppColors.orangeLight
            : AppColors.tealLight;

        return DoubleBackToExitScope(
          child: Stack(
            children: [
              const AppAtmosphereBackdrop(),
              SafeArea(
                top: false,
                bottom: false,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(22, 30, 22, 130),
                  children: [
                    AppCard(
                      padding: EdgeInsets.zero,
                      radius: 34,
                      color: Theme.of(
                        context,
                      ).cardColor.withValues(alpha: 0.88),
                      shadow: AppShadows.premium,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.deepBlueDark,
                              AppColors.deepBlue,
                              AppColors.tealDark,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(34),
                        ),
                        padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 78,
                                  height: 78,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.12),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white.withValues(
                                        alpha: 0.14,
                                      ),
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    initials.isEmpty ? 'C' : initials,
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall
                                        ?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w800,
                                        ),
                                  ),
                                ),
                                const Gap(16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _ProfileHeadlinePill(
                                        label: memberStatus,
                                        color: memberStatusColor,
                                      ),
                                      const Gap(12),
                                      Text(
                                        profile.fullName,
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineSmall
                                            ?.copyWith(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w800,
                                            ),
                                      ),
                                      const Gap(6),
                                      Text(
                                        profile.email,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              color: Colors.white.withValues(
                                                alpha: 0.76,
                                              ),
                                            ),
                                      ),
                                      const Gap(4),
                                      Text(
                                        '${dashboard.path.title} • ${dashboard.activeCohort.label}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: Colors.white.withValues(
                                                alpha: 0.68,
                                              ),
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Gap(12),

                                PremiumIconButton(
                                  icon: Icons.settings_rounded,
                                  isDark: true,
                                  onTap: () => context.push('/settings'),
                                ),
                              ],
                            ),
                            const Gap(22),
                            AdaptiveWrap(
                              minItemWidth: 110,
                              spacing: 10,
                              runSpacing: 10,
                              children: [
                                _ProfileHeroStat(
                                  label: 'Weeks unlocked',
                                  value:
                                      '${dashboard.paidWeeks}/${dashboard.totalProgramWeeks}',
                                  accent: AppColors.orangeLight,
                                ),
                                _ProfileHeroStat(
                                  label: 'Progress',
                                  value: '$progressPercent%',
                                  accent: AppColors.tealLight,
                                ),
                                _ProfileHeroStat(
                                  label: 'Email',
                                  value: authState.isEmailVerified
                                      ? 'Verified'
                                      : 'Pending',
                                  accent: authState.isEmailVerified
                                      ? AppColors.tealLight
                                      : AppColors.orangeLight,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Gap(16),
                    AppCard(
                      radius: 28,
                      color: Theme.of(
                        context,
                      ).cardColor.withValues(alpha: 0.82),
                      child: Column(
                        children: [
                          _ProfileDetailRow(
                            label: 'Member since',
                            value: joinedLabel,
                            icon: Icons.calendar_today_outlined,
                          ),
                          const Gap(18),
                          _ProfileDetailRow(
                            label: 'Phone',
                            value: profile.phone,
                            icon: Icons.call_outlined,
                          ),
                          const Gap(18),
                          _ProfileDetailRow(
                            label: 'Current cohort',
                            value: dashboard.activeCohort.label,
                            icon: Icons.groups_2_outlined,
                          ),
                        ],
                      ),
                    ),
                    const Gap(16),
                    AppCard(
                      radius: 28,
                      color: Theme.of(
                        context,
                      ).cardColor.withValues(alpha: 0.82),
                      child: Column(
                        children: [
                          
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
                            subtitle:
                                'Notifications, theme, and app preferences',
                            onTap: () => context.push('/settings'),
                          ),
                        ],
                      ),
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

class CertificatesScreen extends ConsumerWidget {
  const CertificatesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardState = ref.watch(dashboardSnapshotProvider);

    return dashboardState.when(
      loading: () => const AppScreen(
        body: SafeArea(
          top: false,
          child: AppLoadingState(
            compact: true,
            title: 'Loading achievements...',
            message: 'Building your cohort milestone timeline.',
          ),
        ),
      ),
      error: (error, _) => AppScreen(
        body: SafeArea(
          top: false,
          child: AppErrorState(
            compact: true,
            title: 'Achievements unavailable',
            message: 'We could not load your cohort progress right now.',
            onRetry: () => ref.refresh(dashboardSnapshotProvider),
          ),
        ),
      ),
      data: (dashboard) {
        final achievements = _buildCohortAchievements(dashboard);

        return AppScreen(
          body: SafeArea(
            top: false,
            bottom: false,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(22, 30, 22, 28),
              children: [
                PremiumPageHeader(
                  title: 'Achievements',
                  subtitle:
                      'Milestones are now generated from your real cohort access, sessions, and progress.',
                  leading: PremiumIconButton(
                    icon: Icons.arrow_back_rounded,
                    onTap: () => context.pop(),
                  ),
                ),
                const Gap(16),
                for (final item in achievements) ...[
                  AppCard(
                    radius: 28,
                    color: Theme.of(context).cardColor.withValues(alpha: 0.82),
                    border: Border.all(
                      color: item.unlocked
                          ? item.accent.withValues(alpha: 0.18)
                          : AppColors.deepBlue.withValues(alpha: 0.06),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: item.accent.withValues(
                              alpha: item.unlocked ? 0.14 : 0.08,
                            ),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          alignment: Alignment.center,
                          child: Icon(item.icon, color: item.accent),
                        ),
                        const Gap(14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      item.title,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w800,
                                          ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: item.accent.withValues(
                                        alpha: item.unlocked ? 0.14 : 0.08,
                                      ),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      item.unlocked ? 'Unlocked' : 'In view',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall
                                          ?.copyWith(
                                            color: item.accent,
                                            fontWeight: FontWeight.w800,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                              const Gap(8),
                              Text(
                                item.description,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: _muted(context),
                                      height: 1.55,
                                    ),
                              ),
                            ],
                          ),
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
      },
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

  Future<void> _openContactLink(BuildContext context, String rawUrl) async {
    final uri = Uri.tryParse(rawUrl);
    if (uri == null) {
      showAppSnackBar(context, 'This contact link is not ready yet.');
      return;
    }

    final launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
    if (!launched && context.mounted) {
      showAppSnackBar(context, 'We could not open that contact link right now.');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final controller = ref.read(settingsProvider.notifier);

    return AppScreen(
      body: Stack(
        children: [
          const AppAtmosphereBackdrop(),
          SafeArea(
            top: false,
            bottom: false,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(22, 30, 22, 28),
              children: [
                PremiumPageHeader(
                  title: 'Settings',
                  subtitle: '',
                  leading: PremiumIconButton(
                    icon: Icons.arrow_back_rounded,
                    onTap: () => context.pop(),
                  ),
                ),
                const Gap(18),
                AppCard(
                  radius: 30,
                  color: Theme.of(context).cardColor.withValues(alpha: 0.84),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Preferences',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Gap(8),
                      Text(
                        'Keep the app quiet, bright, or distraction-free based on how you learn best.',
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: _muted(context)),
                      ),
                      const Gap(18),
                      _SettingsToggleTile(
                        icon: Icons.notifications_none_rounded,
                        title: 'Notifications',
                        subtitle: settings.notifications
                            ? 'Live class updates and mentor replies are enabled.'
                            : 'Class and mentor alerts are currently paused.',
                        accent: AppColors.teal,
                        trailing: Switch.adaptive(
                          value: settings.notifications,
                          onChanged: (_) => controller.toggleNotifications(),
                        ),
                      ),
                      const Gap(14),
                      _SettingsToggleTile(
                        icon: Icons.dark_mode_outlined,
                        title: 'Appearance',
                        subtitle: settings.darkMode
                            ? 'Dark theme is active for a low-glare experience.'
                            : 'Light theme is active for a crisp studio feel.',
                        accent: AppColors.deepBlueLight,
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Stay Connected',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Gap(8),
                      Text(
                        'Reach CodeWithGideon through the same social channels listed on the web experience.',
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: _muted(context)),
                      ),
                      const Gap(18),
                      for (var index = 0;
                          index < _settingsContactLinks.length;
                          index++) ...[
                        _ProfileAction(
                          icon: _settingsContactLinks[index].icon,
                          title: _settingsContactLinks[index].title,
                          subtitle: _settingsContactLinks[index].subtitle,
                          onTap: () => _openContactLink(
                            context,
                            _settingsContactLinks[index].url,
                          ),
                        ),
                        if (index != _settingsContactLinks.length - 1)
                          const Divider(height: 18),
                      ],
                    ],
                  ),
                ),
                const Gap(18),
                AppCard(
                  radius: 28,
                  color: Theme.of(context).cardColor.withValues(alpha: 0.82),
                  child: _ProfileAction(
                    icon: Icons.privacy_tip_outlined,
                    title: 'Privacy Policy',
                    subtitle:
                        'See how CodeWithGideon collects, protects, and uses your information.',
                    onTap: () => context.push('/privacy'),
                  ),
                ),
                const Gap(22),
                AppButton(
                  label: 'Logout',
                  variant: AppButtonVariant.danger,
                  leading: const Icon(
                    Icons.logout_rounded,
                    color: Colors.white,
                  ),
                  onPressed: () async {
                    await ref.read(authControllerProvider.notifier).logout();
                    if (!context.mounted) return;
                    context.go('/welcome');
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileHeadlinePill extends StatelessWidget {
  const _ProfileHeadlinePill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _ProfileHeroStat extends StatelessWidget {
  const _ProfileHeroStat({
    required this.label,
    required this.value,
    required this.accent,
  });

  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.7),
              fontWeight: FontWeight.w700,
            ),
          ),
          const Gap(8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: accent,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileDetailRow extends StatelessWidget {
  const _ProfileDetailRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.teal.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
          ),
          alignment: Alignment.center,
          child: Icon(icon, color: AppColors.tealDark, size: 20),
        ),
        const Gap(12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: _muted(context),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Gap(4),
              Text(
                value,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ],
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

class _SettingsToggleTile extends StatelessWidget {
  const _SettingsToggleTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.accent,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget trailing;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : AppColors.muted.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, color: accent),
          ),
          const Gap(14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
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
          const Gap(12),
          trailing,
        ],
      ),
    );
  }
}

Color _muted(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark
      ? AppColors.darkMutedForeground
      : AppColors.mutedForeground;
}

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sections = const [
      (
        'Introduction',
        'CodeWithGideon is committed to protecting your personal information and using it responsibly. This policy explains what information we collect, how we use it, and your rights.',
      ),
      (
        'Information We Collect',
        'We may collect your name and email during registration, payment-related information processed securely by third-party providers, and app usage data that helps us improve the learning experience.',
      ),
      (
        'How We Use Your Information',
        'We use your information to create and manage your account, process weekly billing and enrollment, communicate important updates, and improve our app and services.',
      ),
      (
        'Data Protection',
        'We do not sell your personal data. Payments are handled by trusted third-party processors, and we take reasonable steps to secure the information entrusted to us.',
      ),
    ];

    return AppScreen(
      body: Stack(
        children: [
          const AppAtmosphereBackdrop(),
          SafeArea(
            top: false,
            bottom: false,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(22, 30, 22, 28),
              children: [
                PremiumPageHeader(
                  title: 'Privacy Policy',
                  subtitle: 'Your privacy matters to us.',
                  leading: PremiumIconButton(
                    icon: Icons.arrow_back_rounded,
                    onTap: () => context.pop(),
                  ),
                ),
                const Gap(18),
                AppCard(
                  radius: 32,
                  color: Theme.of(context).cardColor.withValues(alpha: 0.84),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final section in sections) ...[
                        Text(
                          section.$1,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const Gap(10),
                        Text(
                          section.$2,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: _muted(context),
                                height: 1.6,
                              ),
                        ),
                        if (section != sections.last) const Gap(22),
                      ],
                      const Gap(22),
                      Text(
                        'This policy may be updated occasionally. Continued use of our services means you accept the updated policy. Last updated: February 2024.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: _muted(context),
                          fontStyle: FontStyle.italic,
                          height: 1.55,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
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

class _CohortAchievement {
  const _CohortAchievement({
    required this.title,
    required this.description,
    required this.icon,
    required this.accent,
    required this.unlocked,
  });

  final String title;
  final String description;
  final IconData icon;
  final Color accent;
  final bool unlocked;
}

List<_CohortAchievement> _buildCohortAchievements(
  StudentDashboardSnapshot dashboard,
) {
  final unlockedWeeks = dashboard.unlockedSessions.length;
  final totalWeeks = dashboard.totalProgramWeeks;
  final halfwayWeek = totalWeeks == 0 ? 0 : (totalWeeks / 2).ceil();
  final hasRecordings = dashboard.recordedSessions.isNotEmpty;
  final currentWeek = unlockedWeeks.clamp(1, totalWeeks == 0 ? 1 : totalWeeks);
  final currentModule = _syllabusTitleForWeek(dashboard, currentWeek);
  final midpointModule = _syllabusTitleForWeek(dashboard, halfwayWeek);
  final finalWeek = totalWeeks == 0 ? 1 : totalWeeks;
  final finalModule = _syllabusTitleForWeek(dashboard, finalWeek);

  return [
    _CohortAchievement(
      title: 'Path Chosen',
      description:
          'You are enrolled in ${dashboard.path.title} with ${dashboard.course.title} as your active learning track.',
      icon: Icons.route_outlined,
      accent: AppColors.deepBlue,
      unlocked: dashboard.path.title.trim().isNotEmpty,
    ),
    _CohortAchievement(
      title: 'Foundation Module',
      description: unlockedWeeks > 0
          ? 'You have started the path with ${_syllabusTitleForWeek(dashboard, 1)} and your first live cohort week is unlocked.'
          : 'Your first module, ${_syllabusTitleForWeek(dashboard, 1)}, unlocks when your opening week is published.',
      icon: Icons.lock_open_outlined,
      accent: AppColors.teal,
      unlocked: unlockedWeeks > 0,
    ),
    _CohortAchievement(
      title: 'Current Path Stage',
      description: unlockedWeeks > 0
          ? 'You currently have $unlockedWeeks of $totalWeeks weeks unlocked and are working through $currentModule.'
          : 'Your active path stage will appear here once your first cohort week is available.',
      icon: Icons.flag_outlined,
      accent: AppColors.orange,
      unlocked: unlockedWeeks > 0,
    ),
    _CohortAchievement(
      title: 'Midpoint Milestone',
      description: halfwayWeek > 0 && unlockedWeeks >= halfwayWeek
          ? 'You have reached the midpoint of ${dashboard.path.title}, landing in $midpointModule.'
          : 'The midpoint milestone unlocks around week $halfwayWeek when you reach $midpointModule.',
      icon: Icons.trending_up_rounded,
      accent: AppColors.tealDark,
      unlocked: halfwayWeek > 0 && unlockedWeeks >= halfwayWeek,
    ),
    _CohortAchievement(
      title: 'Recorded Revision Trail',
      description: hasRecordings
          ? '${dashboard.recordedSessions.length} replay${dashboard.recordedSessions.length == 1 ? '' : 's'} are published for revision along your path.'
          : 'Recorded lessons will appear here when your cohort team publishes revision material.',
      icon: Icons.video_library_outlined,
      accent: AppColors.purple,
      unlocked: hasRecordings,
    ),
    _CohortAchievement(
      title: 'Final Stretch',
      description: dashboard.paidWeeks >= totalWeeks && totalWeeks > 0
          ? 'You have full paid access through the final stage of the path, ending in $finalModule.'
          : 'You currently have ${dashboard.paidWeeks} of $totalWeeks weeks funded before reaching the final stage, $finalModule.',
      icon: Icons.workspace_premium_outlined,
      accent: AppColors.deepBlueLight,
      unlocked: dashboard.paidWeeks >= totalWeeks && totalWeeks > 0,
    ),
  ];
}

String _syllabusTitleForWeek(StudentDashboardSnapshot dashboard, int week) {
  for (final item in dashboard.course.syllabus) {
    if (item.week == week) return item.title;
  }
  return 'Week $week';
}
