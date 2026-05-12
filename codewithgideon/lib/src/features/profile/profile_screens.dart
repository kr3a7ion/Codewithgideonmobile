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

const _settingsContactLinks =
    <({IconData icon, String title, String subtitle, String url})>[
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
        url:
            'https://api.whatsapp.com/message/NMQR2ZKNJTZBL1?autoload=1&app_absent=0',
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
                            title: 'Weekly Badges',
                            subtitle:
                                'Track every earned week and your next milestone',
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
            title: 'Loading badges...',
            message: 'Preparing your weekly milestone journey.',
          ),
        ),
      ),
      error: (error, _) => AppScreen(
        body: SafeArea(
          top: false,
          child: AppErrorState(
            compact: true,
            title: 'Badges unavailable',
            message: 'We could not build your weekly badge journey right now.',
            onRetry: () => ref.refresh(dashboardSnapshotProvider),
          ),
        ),
      ),
      data: (dashboard) {
        final badgeTimeline = _buildWeeklyBadgeTimeline(dashboard);
        final spotlight = _spotlightBadgeForTimeline(badgeTimeline);
        final completedWeeks = _completedWeeksForDashboard(dashboard);
        final totalWeeks = dashboard.totalProgramWeeks <= 0
            ? 1
            : dashboard.totalProgramWeeks;
        final progress = totalWeeks == 0 ? 0.0 : completedWeeks / totalWeeks;
        final remainingWeeks = (totalWeeks - completedWeeks).clamp(
          0,
          totalWeeks,
        );
        final earnedBadges = badgeTimeline
            .where((item) => item.earned)
            .toList();
        final nextBadge = badgeTimeline.firstWhere(
          (item) => !item.earned,
          orElse: () =>
              badgeTimeline.isEmpty ? _fallbackBadge() : badgeTimeline.last,
        );

        return AppScreen(
          body: SafeArea(
            top: false,
            bottom: false,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(22, 30, 22, 28),
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
                  decoration: BoxDecoration(
                    gradient: Theme.of(context).brightness == Brightness.dark
                        ? const LinearGradient(
                            colors: [
                              AppColors.deepBlueDark,
                              Color(0xFF102548),
                              AppColors.tealDark,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : const LinearGradient(
                            colors: [
                              Color(0xFF0E2C63),
                              Color(0xFF1C4986),
                              Color(0xFF117781),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: AppShadows.premium,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      PremiumPageHeader(
                        title: 'Journey Badges',
                        subtitle:
                            'A new badge drops at the end of each completed week, using your real cohort progress.',
                        onDark: true,
                        leading: PremiumIconButton(
                          icon: Icons.arrow_back_rounded,
                          onTap: () => context.pop(),
                          isDark: true,
                        ),
                      ),
                      const Gap(18),
                      Row(
                        children: [
                          Expanded(
                            child: _BadgeHeroStat(
                              label: 'Completed',
                              value: '$completedWeeks/$totalWeeks',
                            ),
                          ),
                          const Gap(10),
                          Expanded(
                            child: _BadgeHeroStat(
                              label: 'Earned',
                              value: '${earnedBadges.length}',
                            ),
                          ),
                          const Gap(10),
                          Expanded(
                            child: _BadgeHeroStat(
                              label: 'Next',
                              value: 'Wk ${nextBadge.week}',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Gap(18),
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 22),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF111C2E)
                        : Colors.white.withValues(alpha: 0.96),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: spotlight.color.withValues(alpha: 0.18),
                    ),
                  ),
                  child: Column(
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 160,
                            height: 160,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: spotlight.color.withValues(alpha: 0.18),
                            ),
                            child: const SizedBox.shrink(),
                          ),
                          Text(
                            spotlight.badge,
                            style: const TextStyle(fontSize: 68, height: 1),
                          ),
                        ],
                      ),
                      const Gap(18),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: spotlight.color.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: spotlight.color.withValues(alpha: 0.34),
                          ),
                        ),
                        child: Text(
                          'Week ${spotlight.week} · ${spotlight.tier}',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: spotlight.color,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ),
                      const Gap(12),
                      Text(
                        spotlight.title,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const Gap(8),
                      Text(
                        '"${spotlight.tagline}"',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: _muted(context),
                          height: 1.6,
                        ),
                      ),
                      const Gap(18),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? AppColors.darkSurface.withValues(alpha: 0.9)
                              : AppColors.muted.withValues(alpha: 0.72),
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: spotlight.color,
                                  width: 2,
                                ),
                                gradient: LinearGradient(
                                  colors: [
                                    spotlight.color.withValues(alpha: 0.26),
                                    spotlight.color.withValues(alpha: 0.08),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: const Text(
                                '👤',
                                style: TextStyle(fontSize: 18),
                              ),
                            ),
                            const Gap(12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    dashboard.profile.fullName,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(fontWeight: FontWeight.w800),
                                  ),
                                  const Gap(6),
                                  Wrap(
                                    spacing: 4,
                                    runSpacing: 4,
                                    children: earnedBadges.isEmpty
                                        ? [
                                            Text(
                                              spotlight.badge,
                                              style: const TextStyle(
                                                fontSize: 16,
                                              ),
                                            ),
                                          ]
                                        : [
                                            for (final badge in earnedBadges)
                                              Text(
                                                badge.badge,
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                ),
                                              ),
                                          ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Gap(18),
                Row(
                  children: [
                    Text(
                      'All $totalWeeks Weeks',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      completedWeeks == totalWeeks && totalWeeks > 0
                          ? 'Complete'
                          : '$remainingWeeks left',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: spotlight.color,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const Gap(8),
                Text(
                  'Each badge marks a completed week in your cohort journey.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: _muted(context)),
                ),
                const Gap(12),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final maxExtent = totalWeeks <= 4
                        ? 190.0
                        : totalWeeks <= 6
                        ? 156.0
                        : 132.0;
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: badgeTimeline.length,
                      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: maxExtent,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        mainAxisExtent: 154,
                      ),
                      itemBuilder: (context, index) {
                        final item = badgeTimeline[index];
                        final isSpotlight = item.week == spotlight.week;
                        return _WeekBadgeTile(
                          item: item,
                          isSpotlight: isSpotlight,
                        );
                      },
                    );
                  },
                ),
                const Gap(22),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF111C2E)
                        : Colors.white.withValues(alpha: 0.96),
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(
                      color: spotlight.color.withValues(alpha: 0.16),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Text(
                            'Session Progress',
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const Spacer(),
                          Text(
                            '${(progress * 100).round()}%',
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(
                                  color: spotlight.color,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                        ],
                      ),
                      const Gap(12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: progress.clamp(0, 1),
                          minHeight: 8,
                          backgroundColor:
                              Theme.of(context).brightness == Brightness.dark
                              ? AppColors.darkMuted
                              : AppColors.muted,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            spotlight.color,
                          ),
                        ),
                      ),
                      const Gap(12),
                      Text(
                        remainingWeeks == 0 && totalWeeks > 0
                            ? 'You cleared the full session and earned every weekly badge.'
                            : '$remainingWeeks week${remainingWeeks == 1 ? '' : 's'} remaining before you finish the journey.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: _muted(context),
                          height: 1.55,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
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

    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      showAppSnackBar(
        context,
        'We could not open that contact link right now.',
      );
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
                        'We love hearing from our students and community!',
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: _muted(context)),
                      ),
                      const Gap(18),
                      for (
                        var index = 0;
                        index < _settingsContactLinks.length;
                        index++
                      ) ...[
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
                              ?.copyWith(color: _muted(context), height: 1.6),
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

class _WeeklyBadgeMilestone {
  const _WeeklyBadgeMilestone({
    required this.week,
    required this.badge,
    required this.title,
    required this.tagline,
    required this.color,
    required this.tier,
    required this.earned,
  });

  final int week;
  final String badge;
  final String title;
  final String tagline;
  final Color color;
  final String tier;
  final bool earned;
}

class _WeeklyBadgeTemplate {
  const _WeeklyBadgeTemplate({
    required this.badge,
    required this.title,
    required this.tagline,
    required this.color,
    required this.tier,
  });

  final String badge;
  final String title;
  final String tagline;
  final Color color;
  final String tier;
}

const _allWeeklyBadgeTemplates = <_WeeklyBadgeTemplate>[
  _WeeklyBadgeTemplate(
    badge: '🌱',
    title: 'First Step',
    tagline: 'You showed up. That is where every serious journey begins.',
    color: Color(0xFF4ADE80),
    tier: 'Starter',
  ),
  _WeeklyBadgeTemplate(
    badge: '🔥',
    title: 'On Fire',
    tagline: 'Momentum is building and your weekly rhythm is real now.',
    color: Color(0xFFFB923C),
    tier: 'Ignited',
  ),
  _WeeklyBadgeTemplate(
    badge: '⚡',
    title: 'Live Wire',
    tagline: 'You are in the zone and your effort is starting to compound.',
    color: Color(0xFFFACC15),
    tier: 'Charged',
  ),
  _WeeklyBadgeTemplate(
    badge: '🏅',
    title: 'One Month Strong',
    tagline: 'A full month in. Your consistency is no longer accidental.',
    color: Color(0xFFC084FC),
    tier: 'Milestone',
  ),
  _WeeklyBadgeTemplate(
    badge: '💪',
    title: 'Crushing It',
    tagline: 'You keep showing up and the progress is starting to look loud.',
    color: Color(0xFFF472B6),
    tier: 'Crusher',
  ),
  _WeeklyBadgeTemplate(
    badge: '🌊',
    title: 'Halfway Hero',
    tagline:
        'Past the midpoint. You have carried this journey too far to stop.',
    color: Color(0xFF38BDF8),
    tier: 'Midpoint',
  ),
  _WeeklyBadgeTemplate(
    badge: '🎯',
    title: 'Locked In',
    tagline: 'Focused, consistent, and steadily turning effort into mastery.',
    color: Color(0xFFFB7185),
    tier: 'Focused',
  ),
  _WeeklyBadgeTemplate(
    badge: '🦅',
    title: 'Soaring',
    tagline: 'You are moving with confidence now and it shows in every week.',
    color: Color(0xFF818CF8),
    tier: 'Elevated',
  ),
  _WeeklyBadgeTemplate(
    badge: '💎',
    title: 'Diamond Grit',
    tagline: 'Pressure reveals the sharpest learners and you are proving it.',
    color: Color(0xFF67E8F9),
    tier: 'Diamond',
  ),
  _WeeklyBadgeTemplate(
    badge: '🚀',
    title: 'Launch Mode',
    tagline:
        'Final stretch energy. You are building toward a confident finish.',
    color: Color(0xFFA78BFA),
    tier: 'Launch',
  ),
  _WeeklyBadgeTemplate(
    badge: '⭐',
    title: 'Almost Legendary',
    tagline: 'One step left. You have done too much work to coast now.',
    color: Color(0xFFFBBF24),
    tier: 'Legend',
  ),
  _WeeklyBadgeTemplate(
    badge: '🏆',
    title: 'Champion',
    tagline: 'You completed the full session and earned every single week.',
    color: Color(0xFFF59E0B),
    tier: 'Champion',
  ),
];

List<_WeeklyBadgeMilestone> _buildWeeklyBadgeTimeline(
  StudentDashboardSnapshot dashboard,
) {
  final totalWeeks = dashboard.totalProgramWeeks <= 0
      ? 1
      : dashboard.totalProgramWeeks.clamp(1, 52);
  final completedWeeks = _completedWeeksForDashboard(dashboard);
  final templates = _templatesForProgramLength(totalWeeks);
  return List<_WeeklyBadgeMilestone>.generate(totalWeeks, (index) {
    final template = templates[index];
    return _WeeklyBadgeMilestone(
      week: index + 1,
      badge: template.badge,
      title: template.title,
      tagline: template.tagline,
      color: template.color,
      tier: template.tier,
      earned: index + 1 <= completedWeeks,
    );
  });
}

int _completedWeeksForDashboard(StudentDashboardSnapshot dashboard) {
  final now = DateTime.now();
  final completedWeeks = <int>{};
  for (final session in dashboard.unlockedSessions) {
    if (!session.endsAt.isAfter(now)) {
      completedWeeks.add(session.week);
    }
  }
  final completed = completedWeeks.length;
  return completed.clamp(0, dashboard.totalProgramWeeks);
}

List<_WeeklyBadgeTemplate> _templatesForProgramLength(int totalWeeks) {
  if (totalWeeks == 1) {
    return <_WeeklyBadgeTemplate>[_allWeeklyBadgeTemplates[11]];
  }
  if (totalWeeks == _allWeeklyBadgeTemplates.length) {
    return List<_WeeklyBadgeTemplate>.from(
      _allWeeklyBadgeTemplates,
      growable: false,
    );
  }
  if (totalWeeks > _allWeeklyBadgeTemplates.length) {
    return List<_WeeklyBadgeTemplate>.generate(totalWeeks, (index) {
      final ratio = index / (totalWeeks - 1);
      final mappedIndex = (ratio * (_allWeeklyBadgeTemplates.length - 1))
          .round()
          .clamp(0, _allWeeklyBadgeTemplates.length - 1);
      return _allWeeklyBadgeTemplates[mappedIndex];
    }, growable: false);
  }

  final indices = <int>[0];
  final middleCount = totalWeeks - 2;
  for (var i = 0; i < middleCount; i++) {
    final idx = (1 + ((i + 1) * 10) / (middleCount + 1)).round();
    indices.add(idx.clamp(1, 10));
  }
  indices.add(11);

  return indices
      .map((index) => _allWeeklyBadgeTemplates[index])
      .toList(growable: false);
}

_WeeklyBadgeMilestone _spotlightBadgeForTimeline(
  List<_WeeklyBadgeMilestone> timeline,
) {
  if (timeline.isEmpty) return _fallbackBadge();
  for (final item in timeline) {
    if (!item.earned) return item;
  }
  return timeline.last;
}

_WeeklyBadgeMilestone _fallbackBadge() {
  return const _WeeklyBadgeMilestone(
    week: 1,
    badge: '🌱',
    title: 'First Step',
    tagline:
        'Your weekly journey badges will appear here as your cohort progresses.',
    color: Color(0xFF4ADE80),
    tier: 'Starter',
    earned: false,
  );
}

class _BadgeHeroStat extends StatelessWidget {
  const _BadgeHeroStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.darkMutedForeground,
              fontWeight: FontWeight.w800,
            ),
          ),
          const Gap(6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _WeekBadgeTile extends StatelessWidget {
  const _WeekBadgeTile({required this.item, required this.isSpotlight});

  final _WeeklyBadgeMilestone item;
  final bool isSpotlight;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isSpotlight
        ? item.color.withValues(alpha: isDark ? 0.2 : 0.12)
        : item.earned
        ? (isDark ? const Color(0xFF111C2E) : Colors.white)
        : (isDark ? const Color(0xFF0D1727) : const Color(0xFFF4F7FB));
    final borderColor = isSpotlight
        ? item.color
        : item.earned
        ? item.color.withValues(alpha: 0.22)
        : Theme.of(context).dividerColor.withValues(alpha: 0.4);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            backgroundColor,
            item.color.withValues(
              alpha: isSpotlight
                  ? (isDark ? 0.12 : 0.06)
                  : item.earned
                  ? (isDark ? 0.07 : 0.03)
                  : 0.01,
            ),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: isSpotlight ? 1.4 : 1),
        boxShadow: isSpotlight
            ? [
                BoxShadow(
                  color: item.color.withValues(alpha: isDark ? 0.22 : 0.14),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
      child: Stack(
        children: [
          Positioned(
            top: 4,
            right: 4,
            child: Text(
              item.earned ? '✦' : '·',
              style: TextStyle(
                color: item.color.withValues(alpha: item.earned ? 0.9 : 0.32),
                fontSize: item.earned ? 12 : 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isSpotlight
                          ? item.color.withValues(alpha: 0.18)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: isSpotlight
                            ? item.color.withValues(alpha: 0.38)
                            : Theme.of(
                                context,
                              ).dividerColor.withValues(alpha: 0.22),
                      ),
                    ),
                    child: Text(
                      'Wk ${item.week}',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: isSpotlight ? item.color : _muted(context),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (item.earned)
                    Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: item.color.withValues(alpha: 0.92),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: item.color.withValues(alpha: 0.32),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const Spacer(),
              Text(
                item.badge,
                style: TextStyle(
                  fontSize: isSpotlight ? 30 : 28,
                  color: item.earned ? null : Colors.grey,
                ),
              ),
              const Gap(8),
              Text(
                item.tier,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: item.earned
                      ? _muted(context)
                      : _muted(context).withValues(alpha: 0.72),
                  fontWeight: FontWeight.w800,
                  height: 1.25,
                ),
              ),
              const Gap(8),
              Text(
                item.earned ? 'Earned' : 'Locked',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: item.earned
                      ? item.color
                      : _muted(context).withValues(alpha: 0.7),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
