import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import '../../core/models/learning_models.dart';
import '../../core/services/playback_security_service.dart';
import '../../core/state/app_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_controls.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/states/app_state_widgets.dart';
import '../cohorts/models/cohort_session_model.dart';
import '../cohorts/presentation/session_status.dart';
import '../resources/open_resource.dart';
import 'data/watch_progress_repository.dart';

class RecordedPlayerScreen extends ConsumerWidget {
  const RecordedPlayerScreen({super.key, required this.lessonId});

  final String lessonId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardState = ref.watch(dashboardSnapshotProvider);

    return dashboardState.when(
      loading: () => const AppScreen(
        body: SafeArea(
          top: false,
          child: AppLoadingState(
            compact: true,
            title: 'Loading recording...',
            message: 'Preparing your in-app playback experience.',
          ),
        ),
      ),
      error: (error, _) => AppScreen(
        body: SafeArea(
          top: false,
          child: AppErrorState(
            compact: true,
            title: 'Recording unavailable',
            message: 'We could not load this recorded session right now.',
            onRetry: () => ref.refresh(dashboardSnapshotProvider),
          ),
        ),
      ),
      data: (dashboard) {
        CohortSessionModel? session;
        for (final item in dashboard.unlockedSessions) {
          if (item.id == lessonId && item.hasRecordingUrl) {
            session = item;
            break;
          }
        }
        final matchingLessons = dashboard.recordedLessons
            .where((item) => item.id == lessonId)
            .toList();
        final relatedLesson = matchingLessons.isEmpty
            ? null
            : matchingLessons.first;

        if (session == null) {
          return const AppScreen(
            body: SafeArea(
              top: false,
              child: AppEmptyState(
                title: 'Recording not ready',
                message:
                    'This class does not have a published recording link yet.',
                icon: Icons.play_lesson_outlined,
              ),
            ),
          );
        }

        return AppScreen(
          body: _ProtectedRecordedPlayer(
            session: session,
            relatedResources: relatedLesson?.resources ?? const [],
          ),
        );
      },
    );
  }
}

class _ProtectedRecordedPlayer extends ConsumerStatefulWidget {
  const _ProtectedRecordedPlayer({
    required this.session,
    required this.relatedResources,
  });

  final CohortSessionModel session;
  final List<CourseResource> relatedResources;

  @override
  ConsumerState<_ProtectedRecordedPlayer> createState() =>
      _ProtectedRecordedPlayerState();
}

class _ProtectedRecordedPlayerState
    extends ConsumerState<_ProtectedRecordedPlayer> {
  static const _saveEvery = Duration(seconds: 10);

  YoutubePlayerController? _controller;
  bool _isLoading = true;
  bool _isPlayable = true;
  bool _isFullscreen = false;
  bool _didEnableSecurePlayback = false;

  // Watch progress, shared with the website.
  WatchProgressRepository? _progressRepository;
  String? _uid;
  WatchProgress? _savedAtOpen;
  bool _resumed = false;
  bool _completed = false;
  int _position = 0;
  int _duration = 0;
  int _lastSavedPosition = -1;
  DateTime _lastSavedAt = DateTime.fromMillisecondsSinceEpoch(0);
  PlayerState _lastPlayerState = PlayerState.unknown;
  bool _disposing = false;

  /// True once the saved progress has loaded (or failed to), so resuming
  /// waits for it instead of starting from 0.
  bool _progressLoaded = false;

  /// After "Mark as not watched", don't let the 90% rule mark it watched
  /// again until playback has gone back below that point.
  bool _holdAutoComplete = false;

  @override
  void initState() {
    super.initState();
    _enableSecurePlayback();
    // Kept here because ref can't be used once the screen is disposed, and the
    // last position is saved then.
    _progressRepository = ref.read(watchProgressRepositoryProvider);
    _uid = ref.read(authControllerProvider).session?.uid;

    final recordingUri = Uri.tryParse(widget.session.recordingUrl);
    final videoId = recordingUri == null
        ? null
        : _extractYoutubeId(recordingUri);
    if (videoId != null) {
      _controller = YoutubePlayerController(
        initialVideoId: videoId,
        flags: const YoutubePlayerFlags(
          autoPlay: true,
          mute: false,
          loop: false,
          disableDragSeek: true,
          enableCaption: false,
          forceHD: false,
          hideControls: true,
          controlsVisibleAtStart: false,
          hideThumbnail: true,
          showLiveFullscreenButton: false,
        ),
      )..addListener(_onPlayerStateChange);
    } else {
      _isPlayable = false;
      _isLoading = false;
    }
  }

  Future<void> _enableSecurePlayback() async {
    await PlaybackSecurityService.enableSecurePlayback();
    if (mounted) {
      _didEnableSecurePlayback = true;
    }
  }

  void _onPlayerStateChange() {
    final controller = _controller;
    if (controller == null) return;
    if (controller.value.isReady && _isLoading) {
      setState(() => _isLoading = false);
    }

    final playerState = controller.value.playerState;
    final position = controller.value.position.inSeconds;
    final duration = controller.metadata.duration.inSeconds;
    if (duration > 0) _duration = duration;
    if (position > 0) _position = position;
    if (_holdAutoComplete &&
        _duration > 0 &&
        _position / _duration < watchedAt) {
      _holdAutoComplete = false;
    }

    _resumeOnce(controller);

    final stateChanged = playerState != _lastPlayerState;
    _lastPlayerState = playerState;
    if (playerState == PlayerState.playing) {
      if (DateTime.now().difference(_lastSavedAt) >= _saveEvery) {
        _saveProgress();
      }
    } else if (stateChanged &&
        (playerState == PlayerState.paused ||
            playerState == PlayerState.ended)) {
      _saveProgress(completed: playerState == PlayerState.ended ? true : null);
    }
  }

  /// Picks up where the student stopped last time, unless they had nearly
  /// finished or already watched it.
  void _resumeOnce(YoutubePlayerController controller) {
    if (_resumed || !controller.value.isReady || !_progressLoaded) return;
    _resumed = true;
    // Hold off the first automatic save so it can't record 0 s before the
    // jump back to the saved spot has happened.
    _lastSavedAt = DateTime.now();
    final saved = _savedAtOpen;
    if (saved == null || saved.completed) return;
    final nearEnd = saved.duration > 0 && saved.position >= saved.duration - 15;
    if (saved.position > 15 && !nearEnd) {
      controller.seekTo(Duration(seconds: saved.position));
    }
  }

  void _saveProgress({bool? completed}) {
    final uid = _uid;
    final repository = _progressRepository;
    if (uid == null || repository == null) return;
    // Before resuming, the player may still be at 0 s; an automatic save then
    // would wipe the saved position.
    if (completed == null && !_resumed) return;
    final reachedEnd =
        !_holdAutoComplete &&
        _duration > 0 &&
        _position / _duration >= watchedAt;
    final isCompleted = completed ?? (_completed || reachedEnd);
    if (_position == _lastSavedPosition && isCompleted == _completed) return;
    _lastSavedAt = DateTime.now();
    _lastSavedPosition = _position;
    if (isCompleted != _completed && mounted && !_disposing) {
      setState(() => _completed = isCompleted);
    } else {
      _completed = isCompleted;
    }
    repository
        .save(
          uid: uid,
          sessionId: widget.session.id,
          position: _position,
          duration: _duration,
          completed: isCompleted,
        )
        .catchError((Object _) {
          // Offline or not allowed: the student can keep watching.
        });
  }

  void _toggleWatched() {
    final watched = !_completed;
    if (!watched) {
      // Start the recording over, so its position doesn't count as watched
      // again on the next save.
      _position = 0;
      _holdAutoComplete = true;
      _controller?.seekTo(Duration.zero);
    }
    if (watched && _duration > 0) _position = _duration;
    _saveProgress(completed: watched);
    showAppSnackBar(
      context,
      watched ? 'Marked as watched.' : 'Marked as not watched.',
    );
  }

  @override
  void dispose() {
    _disposing = true;
    final controller = _controller;
    if (controller != null) {
      final position = controller.value.position.inSeconds;
      if (position > 0) _position = position;
      _saveProgress();
      controller.removeListener(_onPlayerStateChange);
      controller.dispose();
    }
    if (_didEnableSecurePlayback) {
      PlaybackSecurityService.disableSecurePlayback();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final status = resolveSessionStatus(widget.session);
    final controller = _controller;
    // Saved progress can arrive after the screen opens; use it until the
    // player has had its chance to resume.
    final progressState = ref.watch(watchProgressProvider);
    final progressReady = progressState.hasValue || progressState.hasError;
    final saved = progressState.maybeWhen(
      data: (items) => items[widget.session.id],
      orElse: () => null,
    );
    if (saved != null && _savedAtOpen == null && !_resumed) {
      _savedAtOpen = saved;
      _completed = saved.completed;
      _position = saved.position;
      _duration = saved.duration;
    }
    if (progressReady && !_progressLoaded) {
      _progressLoaded = true;
      // The player may already be ready and waiting; resume after this frame.
      if (controller != null && controller.value.isReady) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _resumeOnce(controller);
        });
      }
    }
    final watchedFraction = _completed
        ? 1.0
        : _duration > 0
        ? (_position / _duration).clamp(0.0, 1.0)
        : 0.0;

    final player = controller == null
        ? null
        : YoutubePlayer(
            controller: controller,
            showVideoProgressIndicator: true,
            progressIndicatorColor: AppColors.teal,
            progressColors: ProgressBarColors(
              playedColor: AppColors.teal,
              handleColor: AppColors.tealLight,
              bufferedColor: Colors.grey.shade400,
              backgroundColor: Colors.grey.shade600,
            ),
            onReady: () {
              if (mounted) {
                setState(() => _isLoading = false);
              }
            },
          );

    if (player == null) {
      return _RecordedPlayerLayout(
        session: widget.session,
        relatedResources: widget.relatedResources,
        status: status,
        isDark: isDark,
        isPlayable: _isPlayable,
        isLoading: _isLoading,
        player: null,
        controller: controller,
        isWatched: _completed,
        watchedFraction: watchedFraction,
        durationSeconds: _duration,
        onToggleWatched: _toggleWatched,
      );
    }

    return YoutubePlayerBuilder(
      onEnterFullScreen: () {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
        if (!mounted) return;
        setState(() => _isFullscreen = true);
      },
      onExitFullScreen: () {
        SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
        if (!mounted) return;
        setState(() => _isFullscreen = false);
      },
      player: player,
      builder: (context, playerWidget) {
        return _RecordedPlayerLayout(
          session: widget.session,
          relatedResources: widget.relatedResources,
          status: status,
          isDark: isDark,
          isPlayable: _isPlayable,
          isLoading: _isLoading,
          player: playerWidget,
          isFullscreen: _isFullscreen,
          controller: controller,
          isWatched: _completed,
          watchedFraction: watchedFraction,
          durationSeconds: _duration,
          onToggleWatched: _toggleWatched,
        );
      },
    );
  }
}

/// Dark player area on top, a light sheet below with the class details, and
/// an "Ask about this moment" bar that carries the current playback time.
class _RecordedPlayerLayout extends StatefulWidget {
  const _RecordedPlayerLayout({
    required this.session,
    required this.relatedResources,
    required this.status,
    required this.isDark,
    required this.isPlayable,
    required this.isLoading,
    required this.player,
    required this.controller,
    required this.isWatched,
    required this.watchedFraction,
    required this.durationSeconds,
    required this.onToggleWatched,
    this.isFullscreen = false,
  });

  final CohortSessionModel session;
  final List<CourseResource> relatedResources;
  final SessionStatusSnapshot status;
  final bool isDark;
  final bool isPlayable;
  final bool isLoading;
  final Widget? player;
  final YoutubePlayerController? controller;
  final bool isFullscreen;
  final bool isWatched;
  final double watchedFraction;
  final int durationSeconds;
  final VoidCallback onToggleWatched;

  @override
  State<_RecordedPlayerLayout> createState() => _RecordedPlayerLayoutState();
}

class _RecordedPlayerLayoutState extends State<_RecordedPlayerLayout> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final session = widget.session;
    final controller = widget.controller;

    final playerArea = AspectRatio(
      aspectRatio: 16 / 9,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const ColoredBox(color: AppColors.deepBlue),
          if (widget.player != null)
            widget.player!
          else
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  widget.isPlayable
                      ? 'Preparing playback...'
                      : 'This recording is not in a supported YouTube format yet.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          if (widget.player != null && !widget.isLoading && controller != null)
            Positioned.fill(
              child: _SecurePlayerOverlay(
                controller: controller,
                isDark: true,
              ),
            ),
          if (widget.isLoading)
            Container(
              color: AppColors.deepBlue,
              alignment: Alignment.center,
              child: Text(
                'W${session.week}',
                style: theme.textTheme.displayLarge?.copyWith(
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
            ),
        ],
      ),
    );

    if (widget.isFullscreen) return playerArea;

    final notes = session.notes.trim();
    final resources = widget.relatedResources;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: ColoredBox(
      color: AppColors.deepBlue,
      child: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                children: [
                  Semantics(
                    button: true,
                    label: 'Back',
                    child: InkWell(
                      onTap: () => context.pop(),
                      customBorder: const CircleBorder(),
                      child: CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.white.withValues(alpha: 0.14),
                        child: const Icon(
                          Icons.arrow_back_rounded,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          playerArea,
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
              ),
              child: Column(
                children: [
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
                      children: [
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: _sheetLine(context),
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ),
                        const Gap(16),
                        Text(
                          'WEEK ${session.week} · RECORDING',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: AppColors.teal,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const Gap(6),
                        Text(
                          session.title,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const Gap(14),
                        _WatchProgressRow(
                          isWatched: widget.isWatched,
                          fraction: widget.watchedFraction,
                          recordedLabel: _recordedLabel(
                            session,
                            widget.durationSeconds,
                          ),
                          onToggle: widget.onToggleWatched,
                        ),
                        const Gap(16),
                        _SheetTabs(
                          labels: [
                            'Notes',
                            resources.isEmpty
                                ? 'Resources'
                                : 'Resources · ${resources.length}',
                            'Ask',
                          ],
                          value: _tab,
                          onChanged: (index) => setState(() => _tab = index),
                        ),
                        const Gap(16),
                        if (_tab == 0)
                          Text(
                            notes.isEmpty
                                ? 'Class notes will appear here when Gideon adds them.'
                                : notes,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              height: 1.6,
                            ),
                          )
                        else if (_tab == 1) ...[
                          for (final resource in resources) ...[
                            AppCard(
                              radius: 18,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 4,
                              ),
                              child: ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: Icon(
                                  _resourceIcon(resource.type),
                                  color: AppColors.teal,
                                ),
                                title: Text(
                                  resource.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                trailing: const Icon(
                                  Icons.open_in_new_rounded,
                                  size: 18,
                                ),
                                onTap: () =>
                                    openCourseResource(context, resource),
                              ),
                            ),
                            const Gap(10),
                          ],
                          if (resources.isEmpty)
                            Text(
                              'No files for this class yet.',
                              style: theme.textTheme.bodyMedium,
                            ),
                          TextButton(
                            onPressed: () => context.push('/resources'),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.teal,
                            ),
                            child: const Text('Browse all resources'),
                          ),
                        ] else ...[
                          Text(
                            'Stuck on part of this class? Ask Gideon. Use the bar below to send the exact moment you are watching.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              height: 1.55,
                            ),
                          ),
                          const Gap(14),
                          AppButton(
                            label: 'Open chat with Gideon',
                            onPressed: () =>
                                context.push('/mentor/${session.id}'),
                          ),
                        ],
                      ],
                    ),
                  ),
                  _AskAboutMoment(session: session, controller: controller),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
    );
  }
}

class _SheetTabs extends StatelessWidget {
  const _SheetTabs({
    required this.labels,
    required this.value,
    required this.onChanged,
  });

  final List<String> labels;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkMuted : AppColors.muted,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: Semantics(
                button: true,
                selected: i == value,
                child: GestureDetector(
                  onTap: () => onChanged(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: i == value
                          ? Theme.of(context).cardColor
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      labels[i],
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: i == value
                            ? FontWeight.w800
                            : FontWeight.w600,
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

/// Opens the chat with the current playback time already typed in.
class _AskAboutMoment extends StatelessWidget {
  const _AskAboutMoment({required this.session, required this.controller});

  final CohortSessionModel session;
  final YoutubePlayerController? controller;

  @override
  Widget build(BuildContext context) {
    final controller = this.controller;
    final theme = Theme.of(context);

    Widget bar(Duration position) {
      final seconds = position.inSeconds;
      return SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Semantics(
          button: true,
          label: seconds > 0
              ? 'Ask Gideon about ${_formatPlaybackClock(position)}'
              : 'Ask Gideon about this class',
          excludeSemantics: true,
          child: InkWell(
            onTap: () => context.push(
              seconds > 0
                  ? '/mentor/${session.id}?at=$seconds'
                  : '/mentor/${session.id}',
            ),
            borderRadius: BorderRadius.circular(999),
            child: Container(
              padding: const EdgeInsets.fromLTRB(8, 6, 6, 6),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: _sheetLine(context)),
                boxShadow: AppShadows.card,
              ),
              child: Row(
                children: [
                  if (seconds > 0) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.orange.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.schedule_rounded,
                            size: 15,
                            color: AppColors.orange,
                          ),
                          const Gap(4),
                          Text(
                            _formatPlaybackClock(position),
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: AppColors.orange,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Gap(10),
                  ] else
                    const Gap(10),
                  Expanded(
                    child: Text(
                      seconds > 0
                          ? 'Ask about this moment'
                          : 'Ask Gideon about this class',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: _sheetMuted(context),
                      ),
                    ),
                  ),
                  const CircleAvatar(
                    radius: 22,
                    backgroundColor: AppColors.teal,
                    child: Icon(Icons.send_rounded, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (controller == null) return bar(Duration.zero);
    return ValueListenableBuilder<YoutubePlayerValue>(
      valueListenable: controller,
      builder: (context, value, _) => bar(value.position),
    );
  }
}

String _recordedLabel(CohortSessionModel session, int durationSeconds) {
  final date = DateFormat('d MMM').format(session.startsAt);
  if (durationSeconds <= 0) return 'Recorded $date';
  final minutes = (durationSeconds / 60).round();
  final length = minutes >= 60
      ? '${minutes ~/ 60} h ${(minutes % 60).toString().padLeft(2, '0')}'
      : '$minutes min';
  return 'Recorded $date · $length';
}

Color _sheetLine(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
    ? AppColors.darkBorder
    : const Color(0xFFC9D3E1);

Color _sheetMuted(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
    ? AppColors.darkMutedForeground
    : AppColors.mutedForeground;

/// A small ring with the percent, the date, and a Watched toggle.
class _WatchProgressRow extends StatelessWidget {
  const _WatchProgressRow({
    required this.isWatched,
    required this.fraction,
    required this.recordedLabel,
    required this.onToggle,
  });

  final bool isWatched;
  final double fraction;
  final String recordedLabel;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final percent = isWatched ? 100 : (fraction * 100).round();
    return Row(
      children: [
        SizedBox.square(
          dimension: 38,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: isWatched ? 1 : fraction,
                strokeWidth: 3,
                color: AppColors.teal,
                backgroundColor: _sheetLine(context),
              ),
              Text(
                '$percent',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.teal,
                ),
              ),
            ],
          ),
        ),
        const Gap(12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isWatched
                    ? 'Watched'
                    : percent > 0
                    ? '$percent% watched'
                    : 'Not started',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                recordedLabel,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: _sheetMuted(context),
                ),
              ),
            ],
          ),
        ),
        Semantics(
          button: true,
          toggled: isWatched,
          label: isWatched ? 'Watched. Tap to undo' : 'Mark as watched',
          excludeSemantics: true,
          child: InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(999),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isWatched ? AppColors.teal : Colors.transparent,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: isWatched ? AppColors.teal : _sheetLine(context),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_rounded,
                    size: 16,
                    color: isWatched ? Colors.white : AppColors.teal,
                  ),
                  const Gap(6),
                  Text(
                    'Watched',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: isWatched ? Colors.white : AppColors.teal,
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

class _SecurePlayerOverlay extends StatefulWidget {
  const _SecurePlayerOverlay({required this.controller, required this.isDark});

  final YoutubePlayerController controller;
  final bool isDark;

  @override
  State<_SecurePlayerOverlay> createState() => _SecurePlayerOverlayState();
}

class _SecurePlayerOverlayState extends State<_SecurePlayerOverlay> {
  Timer? _hideTimer;
  bool _controlsVisible = true;

  @override
  void initState() {
    super.initState();
    _scheduleHide();
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  }

  void _scheduleHide() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      setState(() => _controlsVisible = false);
    });
  }

  void _showControls() {
    if (!_controlsVisible) {
      setState(() => _controlsVisible = true);
    }
    _scheduleHide();
  }

  void _toggleControls() {
    if (_controlsVisible) {
      _hideTimer?.cancel();
      setState(() => _controlsVisible = false);
      return;
    }
    _showControls();
  }

  Future<void> _toggleFullscreen() async {
    final isFullScreen = widget.controller.value.isFullScreen;
    if (!isFullScreen) {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    }
    widget.controller.toggleFullScreenMode();
    _showControls();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: _toggleControls,
        child: ValueListenableBuilder<YoutubePlayerValue>(
          valueListenable: widget.controller,
          builder: (context, value, _) {
            final duration = value.metaData.duration;
            final durationLabel = _formatPlaybackClock(duration);
            final positionLabel = _formatPlaybackClock(value.position);
            final canTogglePlayback = value.isReady && !value.hasError;

            return Stack(
              fit: StackFit.expand,
              children: [
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 180),
                  opacity: _controlsVisible ? 1 : 0,
                  child: IgnorePointer(
                    ignoring: !_controlsVisible,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.black.withValues(alpha: 0.08),
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.34),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 14,
                  right: 14,
                  bottom: 14,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 180),
                    opacity: _controlsVisible ? 1 : 0,
                    child: IgnorePointer(
                      ignoring: !_controlsVisible,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(
                            alpha: widget.isDark ? 0.62 : 0.54,
                          ),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          child: Row(
                            children: [
                              _SecurePlayerControlButton(
                                icon: Icons.replay_10_rounded,
                                onTap: !canTogglePlayback
                                    ? null
                                    : () {
                                        _seekBy(
                                          widget.controller,
                                          value.position,
                                          -10,
                                        );
                                        _showControls();
                                      },
                              ),
                              const Gap(8),
                              InkWell(
                                onTap: !canTogglePlayback
                                    ? null
                                    : () {
                                        if (value.isPlaying) {
                                          widget.controller.pause();
                                        } else {
                                          widget.controller.play();
                                        }
                                        _showControls();
                                      },
                                borderRadius: BorderRadius.circular(999),
                                child: Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  alignment: Alignment.center,
                                  child: Icon(
                                    value.isPlaying
                                        ? Icons.pause_rounded
                                        : Icons.play_arrow_rounded,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                                ),
                              ),
                              const Gap(8),
                              _SecurePlayerControlButton(
                                icon: Icons.forward_10_rounded,
                                onTap: !canTogglePlayback
                                    ? null
                                    : () {
                                        _seekBy(
                                          widget.controller,
                                          value.position,
                                          10,
                                        );
                                        _showControls();
                                      },
                              ),
                              const Gap(12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      value.isPlaying
                                          ? 'Playing securely in-app'
                                          : 'Paused in-app',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelMedium
                                          ?.copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w800,
                                          ),
                                    ),
                                    const Gap(3),
                                    Text(
                                      '$positionLabel / $durationLabel',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall
                                          ?.copyWith(
                                            color: Colors.white70,
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              InkWell(
                                onTap: value.isReady ? _toggleFullscreen : null,
                                borderRadius: BorderRadius.circular(999),
                                child: Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.08),
                                    shape: BoxShape.circle,
                                  ),
                                  alignment: Alignment.center,
                                  child: Icon(
                                    value.isFullScreen
                                        ? Icons.fullscreen_exit_rounded
                                        : Icons.fullscreen_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SecurePlayerControlButton extends StatelessWidget {
  const _SecurePlayerControlButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }
}

void _seekBy(
  YoutubePlayerController controller,
  Duration currentPosition,
  int deltaSeconds,
) {
  final nextPosition = currentPosition + Duration(seconds: deltaSeconds);
  controller.seekTo(
    nextPosition.isNegative ? Duration.zero : nextPosition,
    allowSeekAhead: true,
  );
}

String _formatPlaybackClock(Duration value) {
  final safeValue = value.isNegative ? Duration.zero : value;
  final hours = safeValue.inHours;
  final minutes = safeValue.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = safeValue.inSeconds.remainder(60).toString().padLeft(2, '0');
  if (hours > 0) {
    return '$hours:$minutes:$seconds';
  }
  return '${safeValue.inMinutes}:$seconds';
}

String? _extractYoutubeId(Uri uri) {
  final host = uri.host.toLowerCase();
  if (host.contains('youtu.be')) {
    return uri.pathSegments.isEmpty ? null : uri.pathSegments.first;
  }
  if (host.contains('youtube.com')) {
    final videoId = uri.queryParameters['v'];
    if (videoId != null && videoId.isNotEmpty) return videoId;
    final embedIndex = uri.pathSegments.indexOf('embed');
    if (embedIndex != -1 && embedIndex + 1 < uri.pathSegments.length) {
      return uri.pathSegments[embedIndex + 1];
    }
  }
  return null;
}

class ResourcesLibraryScreen extends ConsumerStatefulWidget {
  const ResourcesLibraryScreen({super.key});

  @override
  ConsumerState<ResourcesLibraryScreen> createState() =>
      _ResourcesLibraryScreenState();
}

class _ResourcesLibraryScreenState
    extends ConsumerState<ResourcesLibraryScreen> {
  String _query = '';
  String _filter = 'all';

  @override
  Widget build(BuildContext context) {
    final dashboardState = ref.watch(dashboardSnapshotProvider);

    return dashboardState.when(
      loading: () => const AppScreen(
        body: SafeArea(
          top: false,
          child: AppLoadingState(
            compact: true,
            title: 'Loading resources...',
            message: 'Syncing the latest published files from your dashboard.',
          ),
        ),
      ),
      error: (error, _) => AppScreen(
        body: SafeArea(
          top: false,
          child: AppErrorState(
            compact: true,
            title: 'Resources unavailable',
            message: 'We could not load your published learning resources yet.',
            onRetry: () => ref.refresh(dashboardSnapshotProvider),
          ),
        ),
      ),
      data: (dashboard) {
        final allResources = dashboard.libraryResources;
        final resources = allResources.where((resource) {
          final filterMatches = _resourceMatchesFilter(_filter, resource);
          final queryMatches =
              _query.isEmpty ||
              resource.name.toLowerCase().contains(_query.toLowerCase()) ||
              resource.folder.toLowerCase().contains(_query.toLowerCase());
          return filterMatches && queryMatches;
        }).toList();
        final folders = _buildFolderCounts(allResources);
        final videoCount = allResources
            .where((resource) => resource.type.toLowerCase() == 'video')
            .length;
        final codeCount = allResources
            .where((resource) => resource.type.toLowerCase() == 'code')
            .length;
        final pdfCount = allResources
            .where((resource) => resource.type.toLowerCase() == 'pdf')
            .length;
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return AppScreen(
          body: SafeArea(
            top: false,
            bottom: false,
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    gradient: isDark
                        ? const LinearGradient(
                            colors: [
                              AppColors.deepBlueDark,
                              Color(0xFF11274A),
                              AppColors.tealDark,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : AppGradients.primary,
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(36),
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(22, 30, 22, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      PremiumPageHeader(
                        title: 'Resources',
                        subtitle:
                            'Browse admin-published class notes, downloads, and curated materials with quick search.',
                        leading: PremiumIconButton(
                          icon: Icons.arrow_back_rounded,
                          onTap: () => context.pop(),
                          isDark: true,
                        ),
                        onDark: true,
                      ),
                      const Gap(18),
                      Row(
                        children: [
                          Expanded(
                            child: _ResourceHeroStat(
                              label: 'Published',
                              value: '${allResources.length}',
                            ),
                          ),
                          const Gap(10),
                          Expanded(
                            child: _ResourceHeroStat(
                              label: 'Folders',
                              value: '${folders.length}',
                            ),
                          ),
                          const Gap(10),
                          Expanded(
                            child: _ResourceHeroStat(
                              label: 'Video',
                              value: '$videoCount',
                            ),
                          ),
                        ],
                      ),
                      const Gap(16),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                        child: TextField(
                          onChanged: (value) => setState(() => _query = value),
                          style: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.copyWith(color: Colors.white),
                          decoration: InputDecoration(
                            hintText:
                                'Search resources, folders, or file types...',
                            hintStyle: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: AppColors.darkMutedForeground,
                                ),
                            prefixIcon: Icon(
                              Icons.search_rounded,
                              color: Colors.white.withValues(alpha: 0.86),
                            ),
                            fillColor: Colors.transparent,
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(22),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(22),
                              borderSide: BorderSide(
                                color: Colors.white.withValues(alpha: 0.22),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      ref.invalidate(dashboardSnapshotProvider);
                      await ref.read(dashboardSnapshotProvider.future);
                    },
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(22, 18, 22, 28),
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.darkSurface.withValues(alpha: 0.84)
                                : Colors.white.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: Theme.of(
                                context,
                              ).dividerColor.withValues(alpha: 0.35),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: _LibraryMetaChip(
                                  icon: Icons.description_outlined,
                                  label: 'PDF',
                                  value: '$pdfCount files',
                                  accent: const Color(0xFF2563EB),
                                ),
                              ),
                              const Gap(10),
                              Expanded(
                                child: _LibraryMetaChip(
                                  icon: Icons.code_rounded,
                                  label: 'Code',
                                  value: '$codeCount items',
                                  accent: AppColors.purple,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Gap(16),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              for (final filter in const [
                                'all',
                                'pdf',
                                'code',
                                'video',
                              ]) ...[
                                _FilterChip(
                                  label: filter,
                                  active: _filter == filter,
                                  onTap: () => setState(() => _filter = filter),
                                ),
                                const Gap(10),
                              ],
                            ],
                          ),
                        ),
                        const Gap(20),
                        Text(
                          'Folders',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const Gap(12),
                        if (folders.isEmpty)
                          AppCard(
                            child: Text(
                              'No published folders yet. Course resources will appear here once they are ready.',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          )
                        else
                          AdaptiveWrap(
                            minItemWidth: 150,
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              for (
                                var index = 0;
                                index < folders.length;
                                index++
                              )
                                AppCard(
                                  color: isDark
                                      ? const Color(0xFF111C2E)
                                      : Theme.of(context).cardColor,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 46,
                                        height: 46,
                                        decoration: BoxDecoration(
                                          gradient: _folderGradient(index),
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.folder_rounded,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const Gap(12),
                                      Text(
                                        folders[index].$1,
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelLarge
                                            ?.copyWith(
                                              fontWeight: FontWeight.w800,
                                            ),
                                      ),
                                      const Gap(6),
                                      Text(
                                        '${folders[index].$2} files',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: _resourceMutedColor(
                                                context,
                                              ),
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        const Gap(22),
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            Text(
                              'All Resources',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            Text(
                              '${allResources.length} published',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: _resourceMutedColor(context),
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ],
                        ),
                        const Gap(12),
                        if (allResources.isEmpty)
                          AppEmptyState(
                            title: 'No resources published yet',
                            message:
                                'Course files for your enrollment will appear here once they are ready.',
                            icon: Icons.folder_off_rounded,
                          )
                        else if (resources.isEmpty)
                          AppEmptyState(
                            title: 'No matching resources',
                            message:
                                'Try a broader search term or switch the selected filter.',
                            icon: Icons.folder_off_rounded,
                            action: AppButton(
                              label: 'Clear Filters',
                              expanded: false,
                              onPressed: () {
                                setState(() {
                                  _query = '';
                                  _filter = 'all';
                                });
                              },
                            ),
                          )
                        else
                          for (final resource in resources)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _ResourceListTile(
                                resource: resource,
                                onTap: () => openCourseResource(context, resource),
                              ),
                            ),
                      ],
                    ),
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

bool _resourceMatchesFilter(String filter, CourseResource resource) {
  final type = resource.type.toLowerCase();
  return filter == 'all' ||
      (filter == 'pdf' && type == 'pdf') ||
      (filter == 'code' && type == 'code') ||
      (filter == 'video' && type == 'video');
}

List<(String, int)> _buildFolderCounts(List<CourseResource> resources) {
  final counts = <String, int>{};
  for (final resource in resources) {
    final folder = resource.folder.trim().isEmpty ? 'General' : resource.folder;
    counts.update(folder, (value) => value + 1, ifAbsent: () => 1);
  }
  final folders =
      counts.entries.map((entry) => (entry.key, entry.value)).toList()
        ..sort((a, b) => a.$1.compareTo(b.$1));
  return folders;
}

LinearGradient _folderGradient(int index) {
  const palette = <List<Color>>[
    [AppColors.orange, AppColors.orangeLight],
    [AppColors.purple, Color(0xFFA78BFA)],
    [Color(0xFF3B82F6), Color(0xFF2563EB)],
    [AppColors.teal, AppColors.tealLight],
  ];
  final colors = palette[index % palette.length];
  return LinearGradient(colors: colors);
}

IconData _resourceIcon(String type) {
  switch (type.toLowerCase()) {
    case 'video':
      return Icons.ondemand_video_rounded;
    case 'code':
      return Icons.code_rounded;
    case 'link':
      return Icons.link_rounded;
    default:
      return Icons.description_outlined;
  }
}

Color _resourceBadgeColor(String type, {bool isDark = false}) {
  switch (type.toLowerCase()) {
    case 'video':
      return isDark ? const Color(0xFF3C2A12) : const Color(0xFFFEF3C7);
    case 'code':
      return isDark ? const Color(0xFF24183E) : const Color(0xFFEDE9FE);
    case 'link':
      return isDark ? const Color(0xFF132A1D) : const Color(0xFFDCFCE7);
    default:
      return isDark ? const Color(0xFF16253B) : const Color(0xFFDBEAFE);
  }
}

Color _resourceAccentColor(String type) {
  switch (type.toLowerCase()) {
    case 'video':
      return const Color(0xFFD97706);
    case 'code':
      return const Color(0xFF7C3AED);
    case 'link':
      return const Color(0xFF15803D);
    default:
      return Colors.blue;
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: active
              ? AppColors.deepBlue
              : (isDark ? AppColors.darkSurface : Colors.white),
          borderRadius: BorderRadius.circular(999),
          border: active
              ? null
              : Border.all(
                  color: isDark
                      ? AppColors.darkBorder
                      : AppColors.border.withValues(alpha: 0.8),
                ),
          boxShadow: active || isDark ? null : AppShadows.card,
        ),
        child: Text(
          label[0].toUpperCase() + label.substring(1),
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: active
                ? Colors.white
                : (isDark ? AppColors.darkForeground : AppColors.foreground),
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _ResourceHeroStat extends StatelessWidget {
  const _ResourceHeroStat({required this.label, required this.value});

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

class _LibraryMetaChip extends StatelessWidget {
  const _LibraryMetaChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: isDark ? 0.16 : 0.08),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: isDark ? 0.2 : 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: accent, size: 18),
          ),
          const Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: _resourceMutedColor(context),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Gap(4),
                Text(
                  value,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ResourceListTile extends StatelessWidget {
  const _ResourceListTile({required this.resource, required this.onTap});

  final CourseResource resource;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = _resourceAccentColor(resource.type);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Ink(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF111C2E) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: accent.withValues(alpha: isDark ? 0.3 : 0.12),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: _resourceBadgeColor(resource.type, isDark: isDark),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(_resourceIcon(resource.type), color: accent),
            ),
            const Gap(14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    resource.name,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Gap(8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _ResourceInfoPill(
                        label: resource.type.toUpperCase(),
                        accent: accent,
                      ),
                      _ResourceInfoPill(
                        label: resource.folder.trim().isEmpty
                            ? 'General'
                            : resource.folder,
                      ),
                    ],
                  ),
                  const Gap(10),
                  Text(
                    '${resource.size.isEmpty ? 'Open file' : resource.size} • ${resource.date}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: _resourceMutedColor(context),
                    ),
                  ),
                ],
              ),
            ),
            const Gap(10),
            Icon(Icons.open_in_new_rounded, color: accent),
          ],
        ),
      ),
    );
  }
}

class _ResourceInfoPill extends StatelessWidget {
  const _ResourceInfoPill({required this.label, this.accent});

  final String label;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pillAccent = accent ?? _resourceMutedColor(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: pillAccent.withValues(alpha: isDark ? 0.18 : 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: pillAccent,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

Color _resourceMutedColor(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark
      ? AppColors.darkMutedForeground
      : AppColors.mutedForeground;
}
