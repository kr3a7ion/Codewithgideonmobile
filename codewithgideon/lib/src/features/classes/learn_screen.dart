import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/models/learning_models.dart';
import '../../core/state/app_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_controls.dart';
import '../../core/widgets/states/app_state_widgets.dart';
import '../cohorts/models/cohort_session_model.dart';
import '../cohorts/presentation/session_status.dart';
import '../home/models/student_dashboard_snapshot.dart';
import '../recorded/data/watch_progress_repository.dart';
import '../resources/open_resource.dart';

/// The Learn tab: classes as a week timeline, recordings, and resources.
class LearnScreen extends ConsumerWidget {
  const LearnScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tab = ref.watch(classTabProvider);
    final dashboardState = ref.watch(dashboardSnapshotProvider);

    return DoubleBackToExitScope(
      child: SafeArea(
        bottom: false,
        child: dashboardState.when(
          loading: () => const AppLoadingState(
            compact: true,
            title: 'Loading your classes...',
            message: 'Pulling in your latest published cohort sessions.',
          ),
          error: (error, _) => AppErrorState(
            compact: true,
            title: 'Classes unavailable',
            message: 'We could not load your class schedule right now.',
            onRetry: () => ref.refresh(dashboardSnapshotProvider),
          ),
          data: (dashboard) => RefreshIndicator(
            onRefresh: () => ref.refresh(dashboardSnapshotProvider.future),
            color: AppColors.teal,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
              children: [
                Text('Learn', style: Theme.of(context).textTheme.displayMedium),
                const Gap(16),
                _Segments(
                  value: tab,
                  onChanged: (next) =>
                      ref.read(classTabProvider.notifier).state = next,
                ),
                const Gap(18),
                switch (tab) {
                  ClassTab.classes => _WeekTimeline(snapshot: dashboard),
                  ClassTab.recordings => _Recordings(snapshot: dashboard),
                  ClassTab.resources => _Resources(snapshot: dashboard),
                },
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Segments extends StatelessWidget {
  const _Segments({required this.value, required this.onChanged});

  final ClassTab value;
  final ValueChanged<ClassTab> onChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const labels = {
      ClassTab.classes: 'Classes',
      ClassTab.recordings: 'Recordings',
      ClassTab.resources: 'Resources',
    };
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkMuted : AppColors.muted,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          for (final entry in labels.entries)
            Expanded(
              child: Semantics(
                button: true,
                selected: entry.key == value,
                child: GestureDetector(
                  onTap: () => onChanged(entry.key),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: entry.key == value
                          ? Theme.of(context).cardColor
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      entry.value,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: entry.key == value
                            ? FontWeight.w800
                            : FontWeight.w600,
                        color: entry.key == value ? null : _muted(context),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// One row per course week; the current week is open, locked weeks are
/// grouped into a single card at the end.
class _WeekTimeline extends ConsumerStatefulWidget {
  const _WeekTimeline({required this.snapshot});

  final StudentDashboardSnapshot snapshot;

  @override
  ConsumerState<_WeekTimeline> createState() => _WeekTimelineState();
}

class _WeekTimelineState extends ConsumerState<_WeekTimeline> {
  final _open = <int>{};

  @override
  Widget build(BuildContext context) {
    final snapshot = widget.snapshot;
    final states = snapshot.weekStates;
    final progress = ref
        .watch(watchProgressProvider)
        .maybeWhen(
          data: (items) => items,
          orElse: () => const <String, WatchProgress>{},
        );
    final byWeek = <int, List<CohortSessionModel>>{};
    for (final session in snapshot.unlockedSessions) {
      byWeek.putIfAbsent(session.week, () => []).add(session);
    }
    for (final list in byWeek.values) {
      list.sort((a, b) => a.startsAt.compareTo(b.startsAt));
    }
    final titles = {
      for (final week in snapshot.course.syllabus)
        if (week.title.trim().isNotEmpty) week.week: week.title.trim(),
    };
    final firstLocked = states.indexOf(CourseWeekState.locked) + 1;

    final rows = <Widget>[];
    for (var i = 0; i < states.length; i++) {
      final week = i + 1;
      if (states[i] == CourseWeekState.locked) break;
      final sessions = byWeek[week] ?? const <CohortSessionModel>[];
      final isOpen =
          states[i] == CourseWeekState.current || _open.contains(week);
      rows.add(
        _WeekRow(
          week: week,
          title: titles[week],
          state: states[i],
          sessions: sessions,
          progress: progress,
          isOpen: isOpen,
          isLast: firstLocked == 0 && i == states.length - 1,
          onToggle: states[i] == CourseWeekState.current
              ? null
              : () => setState(
                  () => _open.contains(week)
                      ? _open.remove(week)
                      : _open.add(week),
                ),
        ),
      );
    }
    if (firstLocked > 0) {
      rows.add(
        _LockedWeeks(snapshot: snapshot, from: firstLocked, to: states.length),
      );
    }
    return Column(children: rows);
  }
}

class _WeekRow extends StatelessWidget {
  const _WeekRow({
    required this.week,
    required this.title,
    required this.state,
    required this.sessions,
    required this.progress,
    required this.isOpen,
    required this.isLast,
    required this.onToggle,
  });

  final int week;
  final String? title;
  final CourseWeekState state;
  final List<CohortSessionModel> sessions;
  final Map<String, WatchProgress> progress;
  final bool isOpen;
  final bool isLast;
  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final watched = sessions.where((s) => progress[s.id]?.completed == true);
    final String subtitle;
    if (sessions.isEmpty) {
      subtitle = 'Classes not scheduled yet';
    } else if (state == CourseWeekState.done) {
      subtitle =
          '${_plural(sessions.length, 'class', 'classes')} · '
          '${watched.length == sessions.length ? 'all watched' : '${watched.length} watched'}';
    } else {
      subtitle = 'Starts ${formatSessionWhen(sessions.first)}';
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              _WeekNode(week: week, state: state),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: state == CourseWeekState.done
                        ? AppColors.teal
                        : _lineColor(context),
                  ),
                ),
            ],
          ),
          const Gap(14),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InkWell(
                    onTap: onToggle,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title == null ? 'Week $week' : 'Week $week · $title',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          if (!isOpen || sessions.isEmpty) ...[
                            const Gap(2),
                            Text(
                              subtitle,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: _muted(context),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  if (isOpen)
                    for (final session in sessions) ...[
                      const Gap(10),
                      _SessionTile(
                        session: session,
                        progress: progress[session.id],
                      ),
                    ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WeekNode extends StatelessWidget {
  const _WeekNode({required this.week, required this.state});

  final int week;
  final CourseWeekState state;

  @override
  Widget build(BuildContext context) {
    final (Color fill, Color? border, Widget child) = switch (state) {
      CourseWeekState.done => (
        AppColors.teal,
        null,
        const Icon(Icons.check_rounded, size: 18, color: Colors.white),
      ),
      CourseWeekState.current => (
        AppColors.orange,
        null,
        Text(
          '$week',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      CourseWeekState.unlocked => (
        Theme.of(context).cardColor,
        _lineColor(context),
        Text('$week', style: const TextStyle(fontWeight: FontWeight.w800)),
      ),
      CourseWeekState.locked => (
        Theme.of(context).cardColor,
        _lineColor(context),
        Icon(Icons.lock_outline_rounded, size: 16, color: _muted(context)),
      ),
    };
    return Container(
      width: 30,
      height: 30,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: fill,
        shape: BoxShape.circle,
        border: border == null ? null : Border.all(color: border, width: 1.5),
      ),
      child: child,
    );
  }
}

/// A class inside an open week: a big card with Join while live, otherwise
/// a compact row.
class _SessionTile extends StatelessWidget {
  const _SessionTile({required this.session, required this.progress});

  final CohortSessionModel session;
  final WatchProgress? progress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = resolveSessionStatus(session);
    void open() => context.push('/classes/${session.id}');

    if (status.isJoinEnabled) {
      return AppCard(
        radius: 22,
        padding: const EdgeInsets.all(16),
        border: Border.all(color: AppColors.teal, width: 1.5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(radius: 3.5, backgroundColor: AppColors.orange),
                const Gap(6),
                Text(
                  'LIVE NOW',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.orange,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                  ),
                ),
              ],
            ),
            const Gap(8),
            InkWell(
              onTap: open,
              child: Text(
                session.title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const Gap(14),
            AppButton(
              label: 'Join class',
              leading: const Icon(Icons.videocam_outlined, color: Colors.white),
              onPressed: () => _openJoinLink(context, session.joinUrl),
            ),
          ],
        ),
      );
    }

    final (IconData icon, String detail) = switch (status.actionState) {
      SessionActionState.watchRecording => (
        Icons.play_circle_outline_rounded,
        progress?.completed == true
            ? 'Watched'
            : progress?.isStarted == true
            ? '${(progress!.fraction * 100).round()}% watched'
            : 'Recording ready',
      ),
      SessionActionState.awaitingRecording => (
        Icons.schedule_rounded,
        'Recording coming soon',
      ),
      _ => (Icons.event_outlined, formatSessionWhen(session)),
    };
    return InkWell(
      onTap: open,
      borderRadius: BorderRadius.circular(20),
      child: AppCard(
        radius: 20,
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(icon, color: AppColors.teal),
            const Gap(12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    session.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Gap(2),
                  Text(
                    detail,
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
    );
  }
}

class _LockedWeeks extends StatelessWidget {
  const _LockedWeeks({
    required this.snapshot,
    required this.from,
    required this.to,
  });

  final StudentDashboardSnapshot snapshot;
  final int from;
  final int to;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final weeks = to - from + 1;
    final price = weeks * snapshot.course.pricePerWeek;
    final String message;
    if (snapshot.hasAnyPending) {
      message = 'They unlock once your payment is confirmed.';
    } else if (price > 0) {
      message = '${_naira(price)} unlocks the rest of the course.';
    } else {
      message = 'Add weeks to unlock the rest of the course.';
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _WeekNode(week: 0, state: CourseWeekState.locked),
        const Gap(14),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: _lineColor(context), width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  weeks == 1
                      ? 'Week $from is locked'
                      : 'Weeks $from to $to are locked',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Gap(4),
                Text(
                  message,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: _muted(context),
                  ),
                ),
                if (snapshot.canTopUp) ...[
                  const Gap(14),
                  AppButton(
                    label: 'Add weeks',
                    onPressed: () => context.push(
                      '/payment?mode=topup&returnTo=%2Fclasses',
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Recordings extends ConsumerWidget {
  const _Recordings({required this.snapshot});

  final StudentDashboardSnapshot snapshot;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordings = snapshot.recordedSessions;
    if (recordings.isEmpty) {
      return const AppEmptyState(
        title: 'No recordings yet',
        message: 'Class recordings show here once Gideon uploads them.',
        icon: Icons.play_circle_outline_rounded,
      );
    }
    final progress = ref
        .watch(watchProgressProvider)
        .maybeWhen(
          data: (items) => items,
          orElse: () => const <String, WatchProgress>{},
        );
    return Column(
      children: [
        for (final session in recordings) ...[
          _SessionTile(session: session, progress: progress[session.id]),
          const Gap(10),
        ],
      ],
    );
  }
}

class _Resources extends StatelessWidget {
  const _Resources({required this.snapshot});

  final StudentDashboardSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final resources = snapshot.libraryResources;
    if (resources.isEmpty) {
      return const AppEmptyState(
        title: 'No resources yet',
        message: 'Notes, slides and files show here once Gideon adds them.',
        icon: Icons.folder_open_outlined,
      );
    }
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final resource in resources.take(20)) ...[
          InkWell(
            onTap: () => openCourseResource(context, resource),
            borderRadius: BorderRadius.circular(20),
            child: AppCard(
              radius: 20,
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Icon(_resourceIcon(resource), color: AppColors.teal),
                  const Gap(12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          resource.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (resource.folder.trim().isNotEmpty)
                          Text(
                            resource.folder,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: _muted(context),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Icon(Icons.open_in_new_rounded, size: 18, color: _muted(context)),
                ],
              ),
            ),
          ),
          const Gap(10),
        ],
        TextButton(
          onPressed: () => context.push('/resources'),
          style: TextButton.styleFrom(foregroundColor: AppColors.teal),
          child: const Text('Search all resources'),
        ),
      ],
    );
  }
}

IconData _resourceIcon(CourseResource resource) {
  return switch (resource.type.trim().toLowerCase()) {
    'video' => Icons.play_circle_outline_rounded,
    'code' => Icons.code_rounded,
    'link' => Icons.link_rounded,
    _ => Icons.description_outlined,
  };
}

String _plural(int count, String one, String many) =>
    '$count ${count == 1 ? one : many}';

String _naira(int amount) => '₦${NumberFormat.decimalPattern().format(amount)}';

Color _muted(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
    ? AppColors.darkMutedForeground
    : AppColors.mutedForeground;

Color _lineColor(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
    ? AppColors.darkBorder
    : const Color(0xFFC9D3E1);

Future<void> _openJoinLink(BuildContext context, String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null) {
    showAppSnackBar(context, 'The join link is not valid yet.');
    return;
  }
  if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
    if (!context.mounted) return;
    showAppSnackBar(context, 'Could not open the join link right now.');
  }
}
