import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart' show StateProvider;
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_controls.dart';
import '../../core/widgets/states/app_state_widgets.dart';
import '../cohorts/models/cohort_session_model.dart';
import '../cohorts/presentation/session_status.dart';
import '../community/models/mentor_request_model.dart';
import '../community/state/community_notifications_provider.dart';
import '../community/state/mentor_request_provider.dart';
import '../recorded/data/watch_progress_repository.dart';
import '../student/models/pending_payment_model.dart';
import 'models/student_dashboard_snapshot.dart';
import 'state/dashboard_provider.dart';

final _dashboardSnapshotCacheProvider =
    StateProvider<StudentDashboardSnapshot?>((ref) => null);

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardState = ref.watch(dashboardSnapshotProvider);
    ref.listen<AsyncValue<StudentDashboardSnapshot>>(
      dashboardSnapshotProvider,
      (_, next) {
        next.whenData((snapshot) {
          ref.read(_dashboardSnapshotCacheProvider.notifier).state = snapshot;
        });
      },
    );
    final cachedSnapshot = ref.watch(_dashboardSnapshotCacheProvider);
    final showSyncing = dashboardState.isLoading && cachedSnapshot != null;
    final syncError = dashboardState.asError?.error;
    // Watch for notifications
    ref.watch(dashboardNotificationsProvider);

    if (cachedSnapshot != null) {
      return DoubleBackToExitScope(
        child: _DashboardContent(
          snapshot: cachedSnapshot,
          isSyncing: showSyncing,
          syncErrorMessage: syncError == null
              ? null
              : 'Some sections could not refresh just now. Showing your last synced view.',
        ),
      );
    }

    return dashboardState.when(
      loading: () => const DoubleBackToExitScope(
        child: SafeArea(child: _DashboardShimmer()),
      ),
      error: (error, stackTrace) => DoubleBackToExitScope(
        child: SafeArea(
          child: AppErrorState(
            compact: true,
            title: 'Today is unavailable',
            message:
                'We could not load your classes right now. Please try again.',
            onRetry: () => ref.refresh(dashboardSnapshotProvider),
          ),
        ),
      ),
      data: (dashboard) =>
          DoubleBackToExitScope(child: _DashboardContent(snapshot: dashboard)),
    );
  }
}

class _DashboardContent extends ConsumerWidget {
  const _DashboardContent({
    required this.snapshot,
    this.isSyncing = false,
    this.syncErrorMessage,
  });

  final StudentDashboardSnapshot snapshot;
  final bool isSyncing;
  final String? syncErrorMessage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: () => ref.refresh(dashboardSnapshotProvider.future),
        color: AppColors.teal,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
          children: [
            _DashboardHeader(snapshot: snapshot),
            if (isSyncing || syncErrorMessage != null) ...[
              const Gap(14),
              _DashboardSyncBanner(
                isSyncing: isSyncing,
                message: syncErrorMessage,
              ),
            ],
            const Gap(8),
            _CourseRing(
              snapshot: snapshot,
            ).animate().fadeIn(duration: 320.ms).scale(begin: const Offset(0.96, 0.96)),
            const Gap(22),
            if (_shouldShowInitialPaymentPrompt(snapshot)) ...[
              _InitialPaymentActionButton(snapshot: snapshot),
              const Gap(16),
            ],
            if (snapshot.profile.pendingPayment != null) ...[
              _PendingPaymentStrip(snapshot: snapshot),
              const Gap(16),
            ],
            if (!snapshot.hasAnyPending) ...[
              _ClassCard(snapshot: snapshot),
              const Gap(24),
            ],
            const _QuickActions(),
            if (snapshot.canTopUp) ...[
              const Gap(20),
              _TopUpActionButton(snapshot: snapshot),
            ],
            _ContinueWatching(snapshot: snapshot),
            const _LatestFromGideon(),
          ],
        ),
      ),
    );
  }
}

bool _shouldShowInitialPaymentPrompt(StudentDashboardSnapshot snapshot) {
  return snapshot.hasAnyPending &&
      snapshot.profile.pendingPayment == null &&
      snapshot.profile.weeksToCommit > 0;
}

class _DashboardHeader extends ConsumerWidget {
  const _DashboardHeader({required this.snapshot});

  final StudentDashboardSnapshot snapshot;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final unread = ref
        .watch(unreadMessagesCountProvider)
        .maybeWhen(data: (count) => count, orElse: () => 0);

    return Row(
      children: [
        Semantics(
          button: true,
          label: 'Your profile',
          child: InkWell(
            onTap: () => context.go('/profile'),
            customBorder: const CircleBorder(),
            child: CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.teal,
              child: Text(
                _initials(snapshot.profile.fullName),
                style: theme.textTheme.labelLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ),
        const Gap(12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _greeting(DateTime.now()),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: _muted(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                snapshot.profile.fullName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        Semantics(
          button: true,
          label: unread > 0 ? '$unread new notifications' : 'Notifications',
          child: InkWell(
            onTap: () => context.push('/community/messages'),
            customBorder: const CircleBorder(),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: theme.cardColor,
                shape: BoxShape.circle,
                boxShadow: AppShadows.card,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Icon(Icons.notifications_none_rounded, size: 22),
                  if (unread > 0)
                    const Positioned(
                      top: 11,
                      right: 12,
                      child: CircleAvatar(
                        radius: 4,
                        backgroundColor: AppColors.orange,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// The course at a glance: one ring segment per week.
class _CourseRing extends StatelessWidget {
  const _CourseRing({required this.snapshot});

  final StudentDashboardSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final states = snapshot.weekStates;
    final current = snapshot.currentWeek;
    final done = states.where((s) => s == CourseWeekState.done).length;
    final unlocked = states.where((s) => s == CourseWeekState.unlocked).length;
    final locked = _lockedColor(context);

    return Column(
      children: [
        Semantics(
          label: current == null
              ? 'Your weeks unlock once payment is confirmed'
              : 'Week $current of ${states.length}',
          child: SizedBox.square(
            dimension: 236,
            child: CustomPaint(
              painter: _RingPainter(states: states, lockedColor: locked),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'WEEK',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: AppColors.teal,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.6,
                      ),
                    ),
                    Text(
                      current == null ? '–' : '$current',
                      style: theme.textTheme.displayLarge?.copyWith(
                        fontSize: 72,
                        height: 1,
                      ),
                    ),
                    const Gap(4),
                    Text(
                      'of ${states.length}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: _muted(context),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const Gap(14),
        if (current == null)
          Text(
            'Your weeks unlock once payment is confirmed',
            style: theme.textTheme.bodySmall?.copyWith(color: _muted(context)),
          )
        else
          Wrap(
            spacing: 16,
            alignment: WrapAlignment.center,
            children: [
              _LegendDot(color: AppColors.teal, label: '$done done'),
              const _LegendDot(color: AppColors.orange, label: 'Now'),
              if (unlocked > 0)
                _LegendDot(
                  color: AppColors.tealLight,
                  label: '$unlocked unlocked',
                ),
            ],
          ),
      ],
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.states, required this.lockedColor});

  final List<CourseWeekState> states;
  final Color lockedColor;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 22.0;
    final rect = (Offset.zero & size).deflate(stroke / 2);
    final count = states.length;
    // Gap between segments, in radians; none when the course is one week.
    final gap = count > 1 ? 0.07 : 0.0;
    final sweep = 2 * math.pi / count;
    for (var i = 0; i < count; i++) {
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = switch (states[i]) {
          CourseWeekState.done => AppColors.teal,
          CourseWeekState.current => AppColors.orange,
          CourseWeekState.unlocked => AppColors.tealLight.withValues(
            alpha: 0.6,
          ),
          CourseWeekState.locked => lockedColor,
        };
      canvas.drawArc(
        rect,
        -math.pi / 2 + i * sweep + gap / 2,
        sweep - gap,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.lockedColor != lockedColor || !_sameStates(old.states, states);

  static bool _sameStates(List<CourseWeekState> a, List<CourseWeekState> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(radius: 4, backgroundColor: color),
        const Gap(6),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: _muted(context),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

/// The live class, the next class, or the latest recording.
class _ClassCard extends StatelessWidget {
  const _ClassCard({required this.snapshot});

  final StudentDashboardSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final live = snapshot.liveSession;
    final next = snapshot.nextSession;
    final recording = snapshot.latestRecordedSession;
    final now = DateTime.now();

    final Widget pill;
    final String? trailing;
    final CohortSessionModel? session;
    final List<Widget> body;
    if (live != null) {
      session = live;
      pill = const _Pill(label: 'LIVE NOW', color: AppColors.orange, dot: true);
      final left = live.endsAt.difference(now).inMinutes;
      trailing = left > 0 ? '$left min left' : null;
      body = [
        AppButton(
          label: 'Join class',
          leading: const Icon(Icons.videocam_outlined, color: Colors.white),
          onPressed: live.hasJoinUrl
              ? () => _openJoinLink(context, live.joinUrl)
              : null,
        ),
      ];
    } else if (next != null) {
      session = next;
      pill = const _Pill(label: 'NEXT CLASS', color: AppColors.teal);
      trailing = formatSessionWhen(next);
      body = [
        if (!next.timeTba) ...[_Countdown(to: next.startsAt), const Gap(14)],
        AppButton(
          label: 'Add to calendar',
          leading: const Icon(Icons.event_available_outlined,
              color: Colors.white),
          onPressed: () => _openCalendar(context, next),
        ),
      ];
    } else if (recording != null) {
      session = recording;
      pill = const _Pill(label: 'RECORDING READY', color: AppColors.teal);
      trailing = 'Week ${recording.week}';
      body = [
        AppButton(
          label: 'Watch recording',
          leading: const Icon(Icons.play_arrow_rounded, color: Colors.white),
          onPressed: () => context.push('/recorded/${recording.id}'),
        ),
      ];
    } else {
      session = null;
      pill = const _Pill(label: 'NO CLASS YET', color: AppColors.teal);
      trailing = null;
      body = const [];
    }

    final sessionId = session?.id;
    return AppCard(
      radius: 28,
      padding: const EdgeInsets.all(18),
      shadow: AppShadows.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              pill,
              const Spacer(),
              if (trailing != null)
                Flexible(
                  child: Text(
                    trailing,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: _muted(context),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const Gap(12),
          InkWell(
            onTap: sessionId == null
                ? null
                : () => context.push('/classes/$sessionId'),
            child: Text(
              session?.title ??
                  'Your next class shows here once Gideon schedules it.',
              style: session == null
                  ? theme.textTheme.bodyMedium?.copyWith(color: _muted(context))
                  : theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
            ),
          ),
          if (body.isNotEmpty) ...[const Gap(16), ...body],
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.color, this.dot = false});

  final String label;
  final Color color;
  final bool dot;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: dot ? color : color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dot) ...[
            const CircleAvatar(radius: 3.5, backgroundColor: AppColors.deepBlue),
            const Gap(6),
          ],
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: dot ? AppColors.deepBlue : color,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}

/// Days, hours and minutes until [to]. Refreshes once a minute.
class _Countdown extends StatelessWidget {
  const _Countdown({required this.to});

  final DateTime to;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<void>(
      stream: Stream.periodic(const Duration(minutes: 1)),
      builder: (context, _) {
        final left = to.difference(DateTime.now());
        final safe = left.isNegative ? Duration.zero : left;
        final parts = [
          ('${safe.inDays}', 'days'),
          (safe.inHours.remainder(24).toString().padLeft(2, '0'), 'hrs'),
          (safe.inMinutes.remainder(60).toString().padLeft(2, '0'), 'min'),
        ];
        return Row(
          children: [
            for (final (value, unit) in parts) ...[
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.teal.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    children: [
                      Text(
                        value,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      Text(
                        unit,
                        style: Theme.of(context).textTheme.labelSmall
                            ?.copyWith(color: _muted(context)),
                      ),
                    ],
                  ),
                ),
              ),
              if (unit != 'min') const Gap(8),
            ],
          ],
        );
      },
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    final List<(IconData, String, VoidCallback)> actions = [
      (Icons.chat_bubble_outline_rounded, 'Ask Gideon', () => context.push('/mentor')),
      (Icons.calendar_month_outlined, 'Calendar', () => context.go('/classes')),
      (Icons.menu_book_outlined, 'Resources', () => context.push('/resources')),
      (Icons.groups_outlined, 'Group', () => context.go('/community')),
    ];
    return Row(
      children: [
        for (final (icon, label, onTap) in actions)
          Expanded(
            child: Semantics(
              button: true,
              label: label,
              excludeSemantics: true,
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(20),
                child: Column(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.deepBlue.withValues(alpha: 0.06),
                        ),
                      ),
                      child: Icon(icon, color: AppColors.teal),
                    ),
                    const Gap(8),
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title, {this.action, this.onAction});

  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
        if (action != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(foregroundColor: AppColors.teal),
            child: Text(action!),
          ),
      ],
    );
  }
}

class _DashboardSyncBanner extends StatelessWidget {
  const _DashboardSyncBanner({required this.isSyncing, required this.message});

  final bool isSyncing;
  final String? message;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = message == null ? AppColors.teal : AppColors.orange;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark
            ? accent.withValues(alpha: 0.14)
            : accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: 0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: isSyncing
                ? const CircularProgressIndicator(strokeWidth: 2.1)
                : Icon(
                    Icons.error_rounded,
                    color: accent,
                    size: 18,
                  ),
          ),
          const Gap(10),
          Expanded(
            child: Text(
              message ??
                  'Refreshing your dashboard sections in the background. Your last synced view stays available while new data arrives.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isDark ? AppColors.darkForeground : AppColors.foreground,
                fontWeight: FontWeight.w600,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PendingPaymentStrip extends StatelessWidget {
  const _PendingPaymentStrip({required this.snapshot});

  final StudentDashboardSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final payment = snapshot.profile.pendingPayment!;
    final isTopUp = payment.kind == PendingPaymentKind.topUp;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.orange.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${isTopUp ? 'Top-up' : 'Payment'} in progress: ${payment.weeks} week(s) • ${_formatNaira(payment.amount)}',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          const Gap(12),
          TextButton(
            onPressed: () => context.push(
              isTopUp
                  ? '/payment?mode=topup&returnTo=%2Fdashboard'
                  : '/payment?mode=initial&returnTo=%2Fdashboard',
            ),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }
}

class _InitialPaymentActionButton extends StatelessWidget {
  const _InitialPaymentActionButton({required this.snapshot});

  final StudentDashboardSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F7C83), Color(0xFF17A0A7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.teal.withValues(alpha: 0.18),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () =>
              context.push('/payment?mode=initial&returnTo=%2Fdashboard'),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Complete Your Payment',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const Gap(6),
                      Text(
                        'Your registration is saved. Pay now to unlock ${snapshot.profile.weeksToCommit} week(s) and activate classes.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
                const Gap(14),
                const Icon(Icons.arrow_forward_rounded, color: Colors.white),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TopUpActionButton extends StatelessWidget {
  const _TopUpActionButton({required this.snapshot});

  final StudentDashboardSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 340;

    // The top-up action sits below summary so the roadmap remains informational.
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFA86A), Color(0xFFFF7A45)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.orange.withValues(alpha: 0.22),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () =>
              context.push('/payment?mode=topup&returnTo=%2Fdashboard'),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: compact
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _TopUpActionHeader(snapshot: snapshot),
                      const Gap(12),
                      const Align(
                        alignment: Alignment.centerRight,
                        child: Icon(
                          Icons.chevron_right_rounded,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Expanded(child: _TopUpActionHeader(snapshot: snapshot)),
                      const Gap(12),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: Colors.white,
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _TopUpActionHeader extends StatelessWidget {
  const _TopUpActionHeader({required this.snapshot});

  final StudentDashboardSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.arrow_upward_rounded,
            color: Colors.white,
            size: 20,
          ),
        ),
        const Gap(12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Top Up Access',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Gap(2),
              Text(
                'Unlock ${snapshot.remainingWeeks} week(s) for ${_formatNaira(snapshot.remainingWeeks * snapshot.course.pricePerWeek)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.92),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}


/// Recordings the student started but didn't finish, newest class first.
/// Hidden when there are none.
class _ContinueWatching extends ConsumerWidget {
  const _ContinueWatching({required this.snapshot});

  final StudentDashboardSnapshot snapshot;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref
        .watch(watchProgressProvider)
        .maybeWhen(
          data: (items) => items,
          orElse: () => const <String, WatchProgress>{},
        );
    final started = snapshot.recordedSessions
        .where((session) {
          final item = progress[session.id];
          return item != null && item.isStarted && !item.completed;
        })
        .take(5)
        .toList();
    if (started.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Gap(24),
        _SectionTitle(
          'Continue watching',
          action: 'All',
          onAction: () => context.go('/classes'),
        ),
        const Gap(8),
        SizedBox(
          height: 222,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            itemCount: started.length,
            separatorBuilder: (_, _) => const Gap(12),
            itemBuilder: (context, index) => _RecordingTile(
              session: started[index],
              progress: progress[started[index].id]!,
            ),
          ),
        ),
      ],
    );
  }
}

class _RecordingTile extends StatelessWidget {
  const _RecordingTile({required this.session, required this.progress});

  final CohortSessionModel session;
  final WatchProgress progress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final minutesLeft = progress.duration > 0
        ? ((progress.duration - progress.position) / 60).ceil()
        : null;
    final percent = (progress.fraction * 100).round();

    return Semantics(
      button: true,
      label: 'Continue ${session.title}, $percent% watched',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: () => context.push('/recorded/${session.id}'),
        child: Container(
          width: 280,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(24),
            boxShadow: AppShadows.card,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 128,
                color: AppColors.deepBlue,
                padding: const EdgeInsets.all(14),
                child: Stack(
                  children: [
                    if (minutesLeft != null && minutesLeft > 0)
                      Text(
                        '$minutesLeft min left',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    Positioned(
                      left: 0,
                      bottom: 6,
                      child: Text(
                        'W${session.week}',
                        style: theme.textTheme.displayMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.08),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const Positioned(
                      right: 0,
                      bottom: 0,
                      child: CircleAvatar(
                        radius: 24,
                        backgroundColor: Colors.white,
                        child: Icon(
                          Icons.play_arrow_rounded,
                          color: AppColors.deepBlue,
                          size: 28,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              LinearProgressIndicator(
                value: progress.fraction,
                minHeight: 4,
                color: AppColors.orange,
                backgroundColor: AppColors.deepBlueLight,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Gap(2),
                    Text(
                      'Week ${session.week} · $percent% watched',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: _muted(context),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Only Gideon's most recent reply; the full thread lives in Chat.
class _LatestFromGideon extends ConsumerWidget {
  const _LatestFromGideon();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messages = ref
        .watch(
          mentorRequestsProvider(
            const MentorConversationQuery(
              sessionId: null,
              conversationId: null,
            ),
          ),
        )
        .maybeWhen(data: (items) => items, orElse: () => <MentorChatMessage>[]);
    MentorChatMessage? latest;
    for (final message in messages) {
      if (!message.isAdmin) continue;
      if (latest == null || message.createdAt.isAfter(latest.createdAt)) {
        latest = message;
      }
    }
    if (latest == null) return const SizedBox.shrink();
    final reply = latest;

    final theme = Theme.of(context);
    final body = reply.body.trim().isNotEmpty
        ? reply.body.trim()
        : reply.imageUrls.isNotEmpty
        ? 'Sent a screenshot'
        : '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Gap(24),
        const _SectionTitle('Latest from Gideon'),
        const Gap(10),
        AppCard(
          radius: 24,
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.deepBlue,
                child: Text(
                  'G',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const Gap(12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Gideon replied',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        Text(
                          _timeAgo(reply.createdAt, DateTime.now()),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: _muted(context),
                          ),
                        ),
                      ],
                    ),
                    const Gap(4),
                    Text(
                      body,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium,
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: () => context.push('/mentor'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.teal,
                          padding: EdgeInsets.zero,
                        ),
                        child: const Text('Reply'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Same shapes as the real screen, so nothing jumps when the data arrives.
class _DashboardShimmer extends StatelessWidget {
  const _DashboardShimmer();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
      children: const [
        Row(
          children: [
            AppShimmerBlock(width: 40, height: 40, radius: 999),
            Gap(12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppShimmerBlock(width: 90, height: 10, radius: 999),
                Gap(6),
                AppShimmerBlock(width: 140, height: 14, radius: 999),
              ],
            ),
          ],
        ),
        Gap(22),
        Center(child: AppShimmerBlock(width: 236, height: 236, radius: 999)),
        Gap(36),
        AppShimmerBlock(width: double.infinity, height: 170, radius: 28),
        Gap(24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            AppShimmerBlock(width: 56, height: 56, radius: 20),
            AppShimmerBlock(width: 56, height: 56, radius: 20),
            AppShimmerBlock(width: 56, height: 56, radius: 20),
            AppShimmerBlock(width: 56, height: 56, radius: 20),
          ],
        ),
      ],
    );
  }
}

String _initials(String fullName) {
  final parts = fullName
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList();
  if (parts.isEmpty) return 'CW';
  if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
  return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
      .toUpperCase();
}

String _greeting(DateTime now) {
  if (now.hour < 12) return 'Good morning';
  if (now.hour < 17) return 'Good afternoon';
  return 'Good evening';
}

String _timeAgo(DateTime time, DateTime now) {
  final diff = now.difference(time);
  if (diff.inMinutes < 1) return 'now';
  if (diff.inHours < 1) return '${diff.inMinutes}m';
  if (diff.inDays < 1) return '${diff.inHours}h';
  if (diff.inDays < 7) return '${diff.inDays}d';
  return DateFormat('MMM d').format(time);
}

Color _muted(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
    ? AppColors.darkMutedForeground
    : AppColors.mutedForeground;

Color _lockedColor(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
    ? AppColors.darkMuted
    : const Color(0xFFC9D3E1);

String _formatNaira(int amount) {
  return '₦${NumberFormat.decimalPattern().format(amount)}';
}

Future<void> _openJoinLink(BuildContext context, String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null) {
    showAppSnackBar(context, 'Join link is invalid.');
    return;
  }
  final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!launched && context.mounted) {
    showAppSnackBar(context, 'Could not open the join link.');
  }
}

Future<void> _openCalendar(
  BuildContext context,
  CohortSessionModel session,
) async {
  var launched = false;
  try {
    launched = await launchUrl(
      addToCalendarUri(session),
      mode: LaunchMode.externalApplication,
    );
  } catch (_) {
    launched = false;
  }
  if (!launched && context.mounted) {
    showAppSnackBar(context, 'Could not open your calendar.');
  }
}
