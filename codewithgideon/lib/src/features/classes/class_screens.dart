import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/state/app_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_controls.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/states/app_state_widgets.dart';
import '../../core/models/learning_models.dart';
import '../cohorts/models/cohort_session_model.dart';
import '../cohorts/presentation/session_status.dart';
import '../resources/open_resource.dart';

class ClassDetailsScreen extends ConsumerWidget {
  const ClassDetailsScreen({super.key, required this.classId});

  final String classId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardState = ref.watch(dashboardSnapshotProvider);

    return dashboardState.when(
      loading: () => const AppScreen(
        body: SafeArea(
          top: false,
          child: AppLoadingState(
            compact: true,
            title: 'Loading class details...',
            message: 'Pulling the latest session notes and access details.',
          ),
        ),
      ),
      error: (error, _) => AppScreen(
        body: SafeArea(
          top: false,
          child: AppErrorState(
            compact: true,
            title: 'Class unavailable',
            message: 'We could not load that class right now.',
            onRetry: () => ref.refresh(dashboardSnapshotProvider),
          ),
        ),
      ),
      data: (dashboard) {
        CohortSessionModel? session;
        for (final item in dashboard.unlockedSessions) {
          if (item.id == classId) {
            session = item;
            break;
          }
        }

        if (session == null) {
          return const AppScreen(
            body: SafeArea(
              top: false,
              child: AppEmptyState(
                title: 'Class unavailable',
                message:
                    'That session is no longer available in your unlocked class list.',
                icon: Icons.menu_book_outlined,
              ),
            ),
          );
        }

        final sessionResources = _classResourcesForSession(
          resources: dashboard.libraryResources,
          session: session,
          pathId: dashboard.path.id,
          courseId: dashboard.course.id,
        );

        return AppScreen(
          body: SafeArea(
            top: false,
            bottom: false,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(22, 30, 22, 28),
              children: [
                PremiumPageHeader(
                  title: 'Week ${session.week}',
                  subtitle: session.pathTitle,
                  leading: PremiumIconButton(
                    icon: Icons.arrow_back_rounded,
                    onTap: () => context.pop(),
                  ),
                  trailing: _StatusPill(label: _statusLabel(session)),
                ),
                const Gap(12),
                Text(
                  session.title,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Gap(18),
                _ClassDetailHero(session: session),
                const Gap(20),
                AppCard(
                  radius: 28,
                  color: Theme.of(context).cardColor.withValues(alpha: 0.84),
                  child: AdaptiveWrap(
                    minItemWidth: 150,
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _ClassMeta(
                        label: 'Status',
                        value: _accessStatusText(session),
                        icon: Icons.timelapse_outlined,
                      ),
                      _ClassMeta(
                        label: 'Schedule',
                        value: resolveSessionStatus(session).scheduleLabel,
                        icon: Icons.calendar_month_outlined,
                      ),
                      _ClassMeta(
                        label: 'Access',
                        value: _accessLabel(session),
                        icon: _accessIcon(session),
                      ),
                    ],
                  ),
                ),
                const Gap(18),
                _ClassAvailabilityStrip(session: session),
                const Gap(18),
                AppCard(
                  radius: 28,
                  color: Theme.of(context).cardColor.withValues(alpha: 0.84),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Session Notes',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const Gap(10),
                      Text(
                        session.notes.isEmpty
                            ? 'No notes have been published for this session yet.'
                            : session.notes,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: _muted(context),
                          height: 1.55,
                        ),
                      ),
                    ],
                  ),
                ),
                const Gap(18),
                AppCard(
                  radius: 28,
                  color: Theme.of(context).cardColor.withValues(alpha: 0.84),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Class Resources',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const Gap(10),
                      Text(
                        sessionResources.isEmpty
                            ? 'No class-specific files have been added for this lesson yet.'
                            : 'These resources were attached to this class for easier study.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: _muted(context),
                          height: 1.55,
                        ),
                      ),
                      const Gap(14),
                      if (sessionResources.isEmpty)
                        AppButton(
                          label: 'Open Resource Library',
                          expanded: false,
                          variant: AppButtonVariant.outline,
                          leading: const Icon(Icons.folder_open_rounded),
                          onPressed: () => context.push('/resources'),
                        )
                      else
                        ...sessionResources.map(
                          (resource) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: AppColors.deepBlue.withValues(
                                    alpha: 0.08,
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                alignment: Alignment.center,
                                child: const Icon(
                                  Icons.folder_open_rounded,
                                  color: AppColors.deepBlue,
                                ),
                              ),
                              title: Text(resource.name),
                              subtitle: Text(
                                '${resource.type} • ${resource.size.isEmpty ? 'Open file' : resource.size}',
                              ),
                              trailing: const Icon(Icons.open_in_new_rounded),
                              onTap: () =>
                                  openCourseResource(context, resource),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const Gap(20),
                AppButton(
                  label: _primaryActionLabel(session),
                  leading: Icon(
                    _primaryActionIcon(session),
                    color: Colors.white,
                  ),
                  onPressed: _primaryAction(context: context, session: session),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ClassDetailHero extends StatelessWidget {
  const _ClassDetailHero({required this.session});

  final CohortSessionModel session;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final status = resolveSessionStatus(session);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: isDark
            ? const LinearGradient(
                colors: [Color(0xFF101A2D), Color(0xFF16243D)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : const LinearGradient(
                colors: [Color(0xFFEFF6FF), Color(0xFFF7FCFB)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ClassBadge(
                  label: status.statusLabel,
                  tint: _statusTone(status),
                  icon: _statusIcon(status),
                ),
                const Gap(12),
                Text(
                  buildClassStartEstimate(session),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: isDark
                        ? AppColors.darkForeground
                        : AppColors.foreground,
                  ),
                ),
                const Gap(8),
              ],
            ),
          ),
          const Gap(16),
          _ClassHeroIcon(status: status),
        ],
      ),
    );
  }
}

class _ClassHeroIcon extends StatelessWidget {
  const _ClassHeroIcon({required this.status});

  final SessionStatusSnapshot status;

  @override
  Widget build(BuildContext context) {
    final tint = _statusTone(status);
    return Container(
      width: 82,
      height: 82,
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.14),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Icon(_statusIcon(status), color: tint, size: 34),
    );
  }
}

class _ClassAvailabilityStrip extends StatelessWidget {
  const _ClassAvailabilityStrip({required this.session});

  final CohortSessionModel session;

  @override
  Widget build(BuildContext context) {
    final status = resolveSessionStatus(session);
    final tint = _statusTone(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: tint.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Icon(_statusIcon(status), color: tint, size: 20),
          const Gap(12),
          Expanded(
            child: Text(
              status.actionState == SessionActionState.watchRecording
                  ? 'Recording access is ready and will stay inside the app player.'
                  : status.actionState == SessionActionState.joinLive
                  ? 'Live access is open now. Join from the primary button below.'
                  : status.actionState == SessionActionState.startsSoon
                  ? 'The join button unlocks automatically when the countdown is up.'
                  : status.actionState == SessionActionState.awaitingRecording
                  ? 'Class has ended. Recording will appear here once published.'
                  : 'A join link has not been published yet for this session.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: _muted(context),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ClassBadge extends StatelessWidget {
  const _ClassBadge({
    required this.label,
    required this.tint,
    required this.icon,
  });

  final String label;
  final Color tint;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final foreground = isDark
        ? Color.lerp(tint, Colors.white, 0.22) ?? tint
        : tint;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: isDark
            ? tint.withValues(alpha: 0.22)
            : tint.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: isDark
              ? tint.withValues(alpha: 0.3)
              : tint.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: foreground),
          const Gap(6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ClassMeta extends StatelessWidget {
  const _ClassMeta({
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
    final iconTone = isDark ? AppColors.tealLight : AppColors.tealDark;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkMuted.withValues(alpha: 0.82)
            : AppColors.muted.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : AppColors.deepBlue.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: iconTone),
              const Gap(8),
              Flexible(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: _muted(context),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const Gap(8),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final isLive = label == 'Live';
    final tone = isLive ? AppColors.teal : AppColors.deepBlue;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark
            ? tone.withValues(alpha: 0.22)
            : tone.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: isDark
              ? tone.withValues(alpha: 0.3)
              : tone.withValues(alpha: 0.12),
        ),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: isDark ? Color.lerp(tone, Colors.white, 0.18) ?? tone : tone,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

String _statusLabel(CohortSessionModel session) {
  final status = resolveSessionStatus(session);
  return switch (status.actionState) {
    SessionActionState.joinLive => 'Live',
    SessionActionState.watchRecording => 'Recording',
    SessionActionState.startsSoon => 'Upcoming',
    SessionActionState.awaitingRecording => 'Completed',
    SessionActionState.awaitingJoinLink => 'Upcoming',
  };
}

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

List<CourseResource> _classResourcesForSession({
  required List<CourseResource> resources,
  required CohortSessionModel session,
  required String pathId,
  required String courseId,
}) {
  return resources.where((resource) {
    final pathMatches =
        resource.pathId.trim().isEmpty || resource.pathId == pathId;
    final courseMatches =
        resource.courseId.trim().isEmpty || resource.courseId == courseId;
    final sessionMatches = resource.sessionId == session.id;
    return pathMatches && courseMatches && sessionMatches;
  }).toList();
}

String _accessLabel(CohortSessionModel session) {
  final status = resolveSessionStatus(session);
  return switch (status.actionState) {
    SessionActionState.watchRecording => 'Watch recorded session',
    SessionActionState.joinLive => 'Join live class',
    SessionActionState.startsSoon => 'Class starts soon',
    SessionActionState.awaitingRecording => 'Await recording link',
    SessionActionState.awaitingJoinLink => 'Awaiting join link',
  };
}

String _accessStatusText(CohortSessionModel session) {
  final status = resolveSessionStatus(session);
  return switch (status.actionState) {
    SessionActionState.watchRecording => 'Recording ready',
    SessionActionState.joinLive => 'Live now',
    SessionActionState.startsSoon => 'Upcoming',
    SessionActionState.awaitingRecording => 'Completed',
    SessionActionState.awaitingJoinLink => 'Pending link',
  };
}

IconData _accessIcon(CohortSessionModel session) {
  final status = resolveSessionStatus(session);
  return switch (status.actionState) {
    SessionActionState.watchRecording => Icons.play_circle_outline_rounded,
    SessionActionState.joinLive => Icons.videocam_outlined,
    SessionActionState.startsSoon => Icons.timelapse_outlined,
    SessionActionState.awaitingRecording => Icons.schedule_outlined,
    SessionActionState.awaitingJoinLink => Icons.link_rounded,
  };
}

String _primaryActionLabel(CohortSessionModel session) {
  final status = resolveSessionStatus(session);
  return switch (status.actionState) {
    SessionActionState.watchRecording => 'Watch Recorded Session',
    SessionActionState.joinLive => 'Join Live Class',
    SessionActionState.startsSoon => 'Class Starts Soon',
    SessionActionState.awaitingRecording => 'Back to Classes',
    SessionActionState.awaitingJoinLink => 'Back to Classes',
  };
}

IconData _primaryActionIcon(CohortSessionModel session) {
  final status = resolveSessionStatus(session);
  return switch (status.actionState) {
    SessionActionState.watchRecording => Icons.play_circle_rounded,
    SessionActionState.joinLive => Icons.videocam_rounded,
    SessionActionState.startsSoon => Icons.timer_rounded,
    SessionActionState.awaitingRecording => Icons.arrow_back_rounded,
    SessionActionState.awaitingJoinLink => Icons.arrow_back_rounded,
  };
}

VoidCallback? _primaryAction({
  required BuildContext context,
  required CohortSessionModel session,
}) {
  final status = resolveSessionStatus(session);
  if (status.actionState == SessionActionState.watchRecording) {
    return () => context.push('/recorded/${session.id}');
  }
  if (status.actionState == SessionActionState.joinLive) {
    return () => _openJoinLink(context, session.joinUrl);
  }
  if (status.actionState == SessionActionState.startsSoon) {
    return null;
  }
  return () => context.pop();
}

Color _muted(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark
      ? AppColors.darkMutedForeground
      : const Color(0xFF50627E);
}

Color _statusTone(SessionStatusSnapshot status) {
  return switch (status.actionState) {
    SessionActionState.joinLive => AppColors.teal,
    SessionActionState.startsSoon => AppColors.deepBlue,
    SessionActionState.watchRecording => AppColors.orange,
    SessionActionState.awaitingRecording => AppColors.orange,
    SessionActionState.awaitingJoinLink => AppColors.deepBlueLight,
  };
}

IconData _statusIcon(SessionStatusSnapshot status) {
  return switch (status.actionState) {
    SessionActionState.joinLive => Icons.videocam_rounded,
    SessionActionState.startsSoon => Icons.timelapse_rounded,
    SessionActionState.watchRecording => Icons.play_circle_rounded,
    SessionActionState.awaitingRecording => Icons.schedule_rounded,
    SessionActionState.awaitingJoinLink => Icons.link_rounded,
  };
}
