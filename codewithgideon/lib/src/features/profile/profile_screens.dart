import 'dart:math' as math;

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
import 'badge_medal.dart';

const _contactLinks =
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
        url: 'https://wa.me/message/NMQR2ZKNJTZBL1',
      ),
    ];

Future<void> _openContactLink(BuildContext context, String rawUrl) async {
  final uri = Uri.tryParse(rawUrl);
  if (uri == null) {
    showAppSnackBar(context, 'This contact link is not ready yet.');
    return;
  }

  try {
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      showAppSnackBar(
        context,
        'We could not open that contact link right now.',
      );
    }
  } catch (_) {
    if (!context.mounted) return;
    showAppSnackBar(context, 'We could not open that contact link right now.');
  }
}

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final dashboardState = ref.watch(dashboardSnapshotProvider);

    return dashboardState.when(
      loading: () => const DoubleBackToExitScope(
        child: SafeArea(
          child: AppLoadingState(
            compact: true,
            title: 'Loading your profile...',
            message: 'Syncing your student details and cohort access.',
          ),
        ),
      ),
      error: (error, _) => DoubleBackToExitScope(
        child: SafeArea(
          child: AppErrorState(
            compact: true,
            title: 'Profile unavailable',
            message: 'We could not load your profile right now.',
            onRetry: () => ref.refresh(dashboardSnapshotProvider),
          ),
        ),
      ),
      data: (dashboard) {
        final theme = Theme.of(context);
        final profile = dashboard.profile;
        final initials = _initialsFromName(profile.fullName);
        final badges = _buildWeeklyBadgeTimeline(dashboard);
        final earned = badges.where((badge) => badge.earned).length;

        return DoubleBackToExitScope(
          child: SafeArea(
            bottom: false,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
              children: [
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      shape: BoxShape.circle,
                      boxShadow: AppShadows.card,
                    ),
                    child: CircleAvatar(
                      radius: 38,
                      backgroundColor: AppColors.teal,
                      child: Text(
                        initials.isEmpty ? 'C' : initials,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
                const Gap(12),
                Text(
                  profile.fullName,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Gap(4),
                Text(
                  '${dashboard.path.title} · ${dashboard.activeCohort.label}',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: _muted(context),
                  ),
                ),
                const Gap(20),
                _YourWeeksCard(dashboard: dashboard),
                const Gap(22),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Badges',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.push('/certificates'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.teal,
                      ),
                      child: Text('$earned of ${badges.length}'),
                    ),
                  ],
                ),
                const Gap(6),
                Row(
                  children: [
                    for (final badge in badges.take(4))
                      Expanded(
                        child: InkWell(
                          onTap: () => context.push('/certificates'),
                          borderRadius: BorderRadius.circular(16),
                          child: Column(
                            children: [
                              BadgeMedal(
                                tier: badge.tier,
                                color: badge.color,
                                state: badge.earned
                                    ? MedalState.earned
                                    : MedalState.locked,
                                size: 52,
                              ),
                              const Gap(6),
                              Text(
                                badge.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  fontWeight: badge.earned
                                      ? FontWeight.w800
                                      : FontWeight.w600,
                                  color: badge.earned ? null : _muted(context),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
                const Gap(18),
                AppCard(
                  radius: 24,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  child: Column(
                    children: [
                      _ProfileAction(
                        icon: Icons.person_outline_rounded,
                        title: 'Your details',
                        subtitle: profile.phone.trim().isEmpty
                            ? profile.email
                            : '${profile.email} · ${profile.phone}',
                        onTap: () => context.push('/profile/edit'),
                      ),
                      const Divider(height: 1),
                      _ProfileAction(
                        icon: Icons.notifications_none_rounded,
                        title: 'Notifications and settings',
                        subtitle: 'Class reminders, theme',
                        onTap: () => context.push('/settings'),
                      ),
                      const Divider(height: 1),
                      _ProfileAction(
                        icon: Icons.verified_user_outlined,
                        title: 'Sign-in and security',
                        subtitle: authState.isEmailVerified
                            ? 'Email verified'
                            : 'Email not verified yet',
                        onTap: () => context.push('/settings'),
                      ),
                      for (final link in _contactLinks) ...[
                        const Divider(height: 1),
                        _ProfileAction(
                          icon: link.icon,
                          title: link.title == 'WhatsApp' ? 'Help' : link.title,
                          subtitle: link.title == 'WhatsApp'
                              ? 'Message us on WhatsApp'
                              : link.subtitle,
                          onTap: () => _openContactLink(context, link.url),
                        ),
                      ],
                    ],
                  ),
                ),
                const Gap(16),
                Center(
                  child: TextButton.icon(
                    onPressed: () async {
                      await ref.read(authControllerProvider.notifier).logout();
                      if (!context.mounted) return;
                      context.go('/welcome');
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.danger,
                    ),
                    icon: const Icon(Icons.logout_rounded),
                    label: const Text('Sign out'),
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

/// Paid weeks out of the course, with Add weeks when more can be bought.
class _YourWeeksCard extends StatelessWidget {
  const _YourWeeksCard({required this.dashboard});

  final StudentDashboardSnapshot dashboard;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pending = dashboard.hasAnyPending;
    final remainingPrice =
        dashboard.remainingWeeks * dashboard.course.pricePerWeek;
    final String message;
    if (pending) {
      message = 'Your weeks unlock once your payment is confirmed.';
    } else if (dashboard.remainingWeeks == 0) {
      message = 'You have the whole course. Nice.';
    } else if (remainingPrice > 0) {
      message =
          '${_naira(remainingPrice)} unlocks the rest of the course.';
    } else {
      message = 'Add weeks to unlock the rest of the course.';
    }

    return AppCard(
      radius: 26,
      padding: const EdgeInsets.all(18),
      shadow: AppShadows.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Your weeks',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: _muted(context),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: (pending ? AppColors.orange : AppColors.teal)
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  pending ? 'Pending' : 'Active',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: pending ? AppColors.orange : AppColors.tealDark,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '${dashboard.paidWeeks}',
                style: theme.textTheme.displaySmall,
              ),
              const Gap(8),
              Text(
                'of ${dashboard.totalProgramWeeks} unlocked',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: _muted(context),
                ),
              ),
            ],
          ),
          const Gap(12),
          Row(
            children: [
              for (final state in dashboard.weekStates)
                Expanded(
                  child: Container(
                    height: 6,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      color: switch (state) {
                        CourseWeekState.done => AppColors.teal,
                        CourseWeekState.current => AppColors.orange,
                        CourseWeekState.unlocked =>
                          AppColors.tealLight.withValues(alpha: 0.6),
                        CourseWeekState.locked =>
                          theme.brightness == Brightness.dark
                              ? AppColors.darkMuted
                              : const Color(0xFFC9D3E1),
                      },
                    ),
                  ),
                ),
            ],
          ),
          const Gap(12),
          Text(
            message,
            style: theme.textTheme.bodySmall?.copyWith(color: _muted(context)),
          ),
          if (dashboard.canTopUp) ...[
            const Gap(14),
            AppButton(
              label: 'Add weeks',
              trailing: const Icon(Icons.add_rounded, color: Colors.white),
              onPressed: () =>
                  context.push('/payment?mode=topup&returnTo=%2Fprofile'),
            ),
          ] else if (pending &&
              dashboard.profile.pendingPayment == null &&
              dashboard.profile.weeksToCommit > 0) ...[
            const Gap(14),
            AppButton(
              label: 'Complete payment',
              onPressed: () =>
                  context.push('/payment?mode=initial&returnTo=%2Fprofile'),
            ),
          ],
        ],
      ),
    );
  }
}

String _naira(int amount) => '₦${NumberFormat.decimalPattern().format(amount)}';

/// Badges: one per course week, earned when that week's class has finished
/// (the same rule and the same medals as the website).
class CertificatesScreen extends ConsumerStatefulWidget {
  const CertificatesScreen({super.key});

  @override
  ConsumerState<CertificatesScreen> createState() => _CertificatesScreenState();
}

class _CertificatesScreenState extends ConsumerState<CertificatesScreen> {
  @override
  Widget build(BuildContext context) {
    final dashboardState = ref.watch(dashboardSnapshotProvider);

    return dashboardState.when(
      loading: () => const AppScreen(
        body: SafeArea(
          child: AppLoadingState(
            compact: true,
            title: 'Loading badges...',
            message: 'Badges come from your finished classes.',
          ),
        ),
      ),
      error: (error, _) => AppScreen(
        body: SafeArea(
          child: AppErrorState(
            compact: true,
            title: 'Badges unavailable',
            message: 'We could not load your badges right now.',
            onRetry: () => ref.refresh(dashboardSnapshotProvider),
          ),
        ),
      ),
      data: (dashboard) {
        final theme = Theme.of(context);
        final journey = _BadgeJourney(dashboard);
        final badges = journey.badges;
        final earned = journey.earned;
        final latest = earned > 0 ? badges[earned - 1] : null;
        final next = earned < badges.length ? badges[earned] : null;
        final spotlight = latest ?? next ?? badges.first;
        final percent = (earned / badges.length * 100).round();

        return AppScreen(
          body: SafeArea(
            bottom: false,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              children: [
                Row(
                  children: [
                    Semantics(
                      button: true,
                      label: 'Back',
                      child: InkWell(
                        onTap: () => context.pop(),
                        customBorder: const CircleBorder(),
                        child: CircleAvatar(
                          radius: 22,
                          backgroundColor: theme.cardColor,
                          child: Icon(
                            Icons.arrow_back_rounded,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const Gap(16),
                Text('Badges', style: theme.textTheme.displaySmall),
                const Gap(6),
                Text(
                  'Earn a badge for every week of classes you finish. The same badges show on the website.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: _muted(context),
                  ),
                ),
                const Gap(18),
                // Latest badge and what's next.
                Container(
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: AppColors.deepBlue,
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        top: -60,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Container(
                            width: 260,
                            height: 260,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: spotlight.color.withValues(
                                    alpha: latest != null ? 0.32 : 0.16,
                                  ),
                                  blurRadius: 90,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            GestureDetector(
                              onTap: () =>
                                  _openBadge(context, journey, spotlight.week),
                              child: BadgeMedal(
                                tier: spotlight.tier,
                                color: spotlight.color,
                                state: latest != null
                                    ? MedalState.latest
                                    : MedalState.next,
                                size: 148,
                              ),
                            ),
                            const Gap(14),
                            Text(
                              latest != null
                                  ? 'WEEK ${latest.week} BADGE · ${latest.tier.toUpperCase()}'
                                  : 'YOUR FIRST BADGE',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: AppColors.tealLight,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const Gap(6),
                            Text(
                              latest?.title ?? '${spotlight.title} is waiting',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.headlineMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const Gap(6),
                            Text(
                              latest?.tagline ??
                                  '${journey.statusOf(spotlight)}.',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Gap(18),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '$earned of ${badges.length} badges earned',
                                    style: theme.textTheme.labelLarge?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                Text(
                                  '$percent%',
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                            const Gap(8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(999),
                              child: LinearProgressIndicator(
                                value: earned / badges.length,
                                minHeight: 8,
                                color: AppColors.tealLight,
                                backgroundColor: Colors.white.withValues(
                                  alpha: 0.15,
                                ),
                              ),
                            ),
                            if (latest != null && next != null) ...[
                              const Gap(18),
                              InkWell(
                                onTap: () =>
                                    _openBadge(context, journey, next.week),
                                borderRadius: BorderRadius.circular(18),
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color: Colors.white.withValues(
                                        alpha: 0.1,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: theme.cardColor,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: BadgeMedal(
                                          tier: next.tier,
                                          color: next.color,
                                          state: MedalState.next,
                                          size: 44,
                                        ),
                                      ),
                                      const Gap(12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'UP NEXT · WEEK ${next.week}',
                                              style: theme.textTheme.labelSmall
                                                  ?.copyWith(
                                                    color: AppColors.tealLight,
                                                    fontWeight: FontWeight.w800,
                                                  ),
                                            ),
                                            Text(
                                              next.title,
                                              style: theme.textTheme.titleSmall
                                                  ?.copyWith(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w800,
                                                  ),
                                            ),
                                            Text(
                                              journey.statusOf(next),
                                              style: theme.textTheme.bodySmall
                                                  ?.copyWith(
                                                    color: Colors.white70,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Icon(
                                        Icons.chevron_right_rounded,
                                        color: Colors.white70,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ] else if (next == null) ...[
                              const Gap(18),
                              Text(
                                "You've earned every badge. Champion.",
                                textAlign: TextAlign.center,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                            if (journey.paymentPending) ...[
                              const Gap(18),
                              AppButton(
                                label: 'Finish payment',
                                onPressed: () => context.push(
                                  '/payment?mode=initial&returnTo=%2Fcertificates',
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Gap(24),
                Text(
                  'Your journey',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Gap(12),
                AppCard(
                  radius: 24,
                  padding: const EdgeInsets.fromLTRB(8, 30, 8, 8),
                  child: _JourneyPath(
                    journey: journey,
                    onOpen: (week) => _openBadge(context, journey, week),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openBadge(BuildContext context, _BadgeJourney journey, int week) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).cardColor,
      builder: (sheetContext) => _BadgeSheet(
        journey: journey,
        initialWeek: week,
        onAddWeeks: () {
          Navigator.of(sheetContext).pop();
          context.push('/payment?mode=topup&returnTo=%2Fcertificates');
        },
      ),
    );
  }
}

/// Which badges exist for the course, how many are earned, and what each
/// one's state and status line are.
class _BadgeJourney {
  _BadgeJourney(this.dashboard)
    : badges = _buildWeeklyBadgeTimeline(dashboard),
      paymentPending = dashboard.hasAnyPending {
    earned = paymentPending
        ? 0
        : _completedWeeksForDashboard(dashboard).clamp(0, badges.length);
    final now = DateTime.now();
    for (final session in dashboard.unlockedSessions) {
      if (session.endsAt.isAfter(now)) continue;
      final current = earnedOn[session.week];
      if (current == null || session.endsAt.isAfter(current)) {
        earnedOn[session.week] = session.endsAt;
      }
    }
  }

  final StudentDashboardSnapshot dashboard;
  final List<_WeeklyBadgeMilestone> badges;
  final bool paymentPending;
  late final int earned;

  /// When each week's last class ended, for "Earned on 26 Sept".
  final Map<int, DateTime> earnedOn = {};

  MedalState stateOf(_WeeklyBadgeMilestone badge) {
    if (badge.week < earned) return MedalState.earned;
    if (badge.week == earned) return MedalState.latest;
    if (badge.week == earned + 1) return MedalState.next;
    return MedalState.locked;
  }

  bool isLit(_WeeklyBadgeMilestone badge) {
    final state = stateOf(badge);
    return state == MedalState.earned || state == MedalState.latest;
  }

  String statusOf(_WeeklyBadgeMilestone badge) {
    if (badge.week <= earned) {
      final on = earnedOn[badge.week];
      return on == null
          ? 'Earned after week ${badge.week}'
          : 'Earned on ${DateFormat('d MMM').format(on)}';
    }
    if (paymentPending) return 'Pay for your weeks to start earning badges';
    if (badge.week > dashboard.paidWeeks) {
      return 'Add week ${badge.week} to earn it';
    }
    return 'Earn it after your week ${badge.week} class';
  }

  bool canAddWeeksFor(_WeeklyBadgeMilestone badge) =>
      !paymentPending && badge.week > dashboard.paidWeeks && dashboard.canTopUp;
}

/// The badges on a winding path, two per row: left to right, then back.
/// The walked part is teal; the rest is a dotted trail.
class _JourneyPath extends StatelessWidget {
  const _JourneyPath({required this.journey, required this.onOpen});

  final _BadgeJourney journey;
  final ValueChanged<int> onOpen;

  static const _cols = 2;
  static const _row = 184.0;
  static const _top = 58.0;

  @override
  Widget build(BuildContext context) {
    final badges = journey.badges;
    final rows = (badges.length / _cols).ceil();
    final height = _top + (rows - 1) * _row + 128;
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final points = [
          for (var i = 0; i < badges.length; i++)
            () {
              final r = i ~/ _cols;
              final c = r.isEven ? i % _cols : _cols - 1 - (i % _cols);
              return Offset((c + 0.5) * width / _cols, _top + r * _row);
            }(),
        ];
        return SizedBox(
          height: height,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _TrailPainter(
                    points: points,
                    earned: journey.earned,
                    width: width,
                    trail: theme.brightness == Brightness.dark
                        ? const Color(0xFF475569)
                        : const Color(0xFFC2CDDC),
                  ),
                ),
              ),
              for (var i = 0; i < badges.length; i++)
                Positioned(
                  left: points[i].dx - 72,
                  top: points[i].dy - 40,
                  width: 144,
                  child: _JourneyStop(
                    badge: badges[i],
                    journey: journey,
                    onTap: () => onOpen(badges[i].week),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _JourneyStop extends StatelessWidget {
  const _JourneyStop({
    required this.badge,
    required this.journey,
    required this.onTap,
  });

  final _WeeklyBadgeMilestone badge;
  final _BadgeJourney journey;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = journey.stateOf(badge);
    final lit = journey.isLit(badge);
    return Semantics(
      button: true,
      label:
          'Week ${badge.week}, ${badge.title}. ${journey.statusOf(badge)}. Open details.',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            SizedBox(
              height: 92,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.topCenter,
                children: [
                  BadgeMedal(
                    tier: badge.tier,
                    color: badge.color,
                    state: state,
                    size: 80,
                  ),
                  if (state == MedalState.latest || state == MedalState.next)
                    Positioned(
                      top: -12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: state == MedalState.latest
                              ? AppColors.deepBlue
                              : AppColors.teal,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          state == MedalState.latest ? 'LATEST' : 'UP NEXT',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const Gap(6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    'WEEK ${badge.week}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: _muted(context),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    badge.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: lit ? null : _muted(context),
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (lit) ...[
                        const Icon(
                          Icons.check_rounded,
                          size: 14,
                          color: AppColors.tealDark,
                        ),
                        const Gap(3),
                      ],
                      Text(
                        lit
                            ? 'Earned'
                            : state == MedalState.next
                            ? 'Up next'
                            : 'Locked',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: lit ? AppColors.tealDark : _muted(context),
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
    );
  }
}

class _TrailPainter extends CustomPainter {
  _TrailPainter({
    required this.points,
    required this.earned,
    required this.width,
    required this.trail,
  });

  final List<Offset> points;
  final int earned;
  final double width;
  final Color trail;

  Path _path(int from, int to) {
    final path = Path()..moveTo(points[from].dx, points[from].dy);
    for (var i = from + 1; i <= to; i++) {
      final a = points[i - 1];
      final b = points[i];
      if ((a.dy - b.dy).abs() < 1) {
        path.lineTo(b.dx, b.dy);
      } else {
        // Turning to the next row: swing out towards the edge.
        final edge = a.dx > width / 2
            ? a.dx + (width - a.dx) * 0.78
            : a.dx * 0.22;
        path.cubicTo(edge, a.dy, edge, b.dy, b.dx, b.dy);
      }
    }
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;
    final last = points.length - 1;
    final ahead = _path(math.max(0, earned - 1), last);
    final dot = Paint()..color = trail;
    for (final metric in ahead.computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += 12) {
        final at = metric.getTangentForOffset(d)?.position;
        if (at != null) canvas.drawCircle(at, 2, dot);
      }
    }
    if (earned >= 2) {
      canvas.drawPath(
        _path(0, earned - 1),
        Paint()
          ..color = AppColors.teal
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }
  }

  @override
  bool shouldRepaint(_TrailPainter old) =>
      old.earned != earned ||
      old.width != width ||
      old.trail != trail ||
      old.points.length != points.length;
}

/// A bigger look at one badge, with arrows to move through the rest.
class _BadgeSheet extends StatefulWidget {
  const _BadgeSheet({
    required this.journey,
    required this.initialWeek,
    required this.onAddWeeks,
  });

  final _BadgeJourney journey;
  final int initialWeek;
  final VoidCallback onAddWeeks;

  @override
  State<_BadgeSheet> createState() => _BadgeSheetState();
}

class _BadgeSheetState extends State<_BadgeSheet> {
  late int _index = widget.journey.badges
      .indexWhere((b) => b.week == widget.initialWeek)
      .clamp(0, widget.journey.badges.length - 1);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final journey = widget.journey;
    final badges = journey.badges;
    final badge = badges[_index];
    final state = journey.stateOf(badge);
    final lit = journey.isLit(badge);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: lit
                  ? BoxDecoration(
                      gradient: RadialGradient(
                        colors: [
                          badge.color.withValues(alpha: 0.28),
                          badge.color.withValues(alpha: 0),
                        ],
                        stops: const [0, 0.62],
                      ),
                    )
                  : null,
              child: Center(
                child: TweenAnimationBuilder<double>(
                  key: ValueKey(badge.week),
                  tween: Tween(begin: 0.8, end: 1),
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeOutBack,
                  builder: (context, scale, child) =>
                      Transform.scale(scale: scale, child: child),
                  child: BadgeMedal(
                    tier: badge.tier,
                    color: badge.color,
                    state: state,
                    size: 150,
                  ),
                ),
              ),
            ),
            const Gap(8),
            Text(
              badge.tier.toUpperCase(),
              style: theme.textTheme.labelMedium?.copyWith(
                color: lit ? AppColors.tealDark : _muted(context),
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
            const Gap(4),
            Text(
              badge.title,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const Gap(6),
            Text(
              badge.tagline,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: _muted(context),
              ),
            ),
            const Gap(14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: lit
                    ? AppColors.teal.withValues(alpha: 0.12)
                    : (theme.brightness == Brightness.dark
                          ? AppColors.darkMuted
                          : AppColors.muted),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    lit ? Icons.check_rounded : Icons.lock_outline_rounded,
                    size: 16,
                    color: lit ? AppColors.tealDark : _muted(context),
                  ),
                  const Gap(6),
                  Flexible(
                    child: Text(
                      journey.statusOf(badge),
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: lit ? AppColors.tealDark : null,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (journey.canAddWeeksFor(badge)) ...[
              const Gap(16),
              AppButton(
                label: 'Add weeks',
                trailing: const Icon(Icons.add_rounded, color: Colors.white),
                onPressed: widget.onAddWeeks,
              ),
            ],
            const Gap(14),
            const Divider(height: 1),
            Row(
              children: [
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: _index > 0
                        ? TextButton.icon(
                            onPressed: () => setState(() => _index--),
                            icon: const Icon(Icons.chevron_left_rounded),
                            label: Text('Week ${badges[_index - 1].week}'),
                          )
                        : const SizedBox.shrink(),
                  ),
                ),
                Text(
                  '${_index + 1} of ${badges.length}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: _muted(context),
                  ),
                ),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: _index < badges.length - 1
                        ? TextButton.icon(
                            onPressed: () => setState(() => _index++),
                            iconAlignment: IconAlignment.end,
                            icon: const Icon(Icons.chevron_right_rounded),
                            label: Text('Week ${badges[_index + 1].week}'),
                          )
                        : const SizedBox.shrink(),
                  ),
                ),
              ],
            ),
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
        padding: const EdgeInsets.symmetric(vertical: 12),
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
    tagline: 'You showed up. That is everything.',
    color: Color(0xFF4ADE80),
    tier: 'Starter',
  ),
  _WeeklyBadgeTemplate(
    badge: '🔥',
    title: 'On Fire',
    tagline: 'Momentum is building. Keep it up.',
    color: Color(0xFFFB923C),
    tier: 'Ignited',
  ),
  _WeeklyBadgeTemplate(
    badge: '⚡',
    title: 'Live Wire',
    tagline: 'You are in the zone. Keep sparking.',
    color: Color(0xFFFACC15),
    tier: 'Charged',
  ),
  _WeeklyBadgeTemplate(
    badge: '🏅',
    title: 'One Month Strong',
    tagline: 'A full month. You are built different.',
    color: Color(0xFFC084FC),
    tier: 'Milestone',
  ),
  _WeeklyBadgeTemplate(
    badge: '💪',
    title: 'Crushing It',
    tagline: 'Look at you go. No slowing down.',
    color: Color(0xFFF472B6),
    tier: 'Crusher',
  ),
  _WeeklyBadgeTemplate(
    badge: '🌊',
    title: 'Halfway Hero',
    tagline: 'Past the midpoint. You are doing this.',
    color: Color(0xFF38BDF8),
    tier: 'Midpoint',
  ),
  _WeeklyBadgeTemplate(
    badge: '🎯',
    title: 'Locked In',
    tagline: 'Focused. Consistent. Unstoppable.',
    color: Color(0xFFFB7185),
    tier: 'Focused',
  ),
  _WeeklyBadgeTemplate(
    badge: '🦅',
    title: 'Soaring',
    tagline: 'Flying high. Nothing stopping you now.',
    color: Color(0xFF818CF8),
    tier: 'Elevated',
  ),
  _WeeklyBadgeTemplate(
    badge: '💎',
    title: 'Diamond Grit',
    tagline: 'Pressure makes diamonds. You are proof.',
    color: Color(0xFF67E8F9),
    tier: 'Diamond',
  ),
  _WeeklyBadgeTemplate(
    badge: '🚀',
    title: 'Launch Mode',
    tagline: 'Final stretch. You are in launch mode.',
    color: Color(0xFFA78BFA),
    tier: 'Launch',
  ),
  _WeeklyBadgeTemplate(
    badge: '⭐',
    title: 'Almost Legendary',
    tagline: 'One step left. Leave nothing behind.',
    color: Color(0xFFFBBF24),
    tier: 'Legend',
  ),
  _WeeklyBadgeTemplate(
    badge: '🏆',
    title: 'Champion',
    tagline: 'You did it. Every single week. Champion.',
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

