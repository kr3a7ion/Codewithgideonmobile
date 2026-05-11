import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import '../../core/data/demo_data.dart';
import '../../core/state/app_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_controls.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/states/app_state_widgets.dart';
import '../cohorts/models/cohort_session_model.dart';
import '../cohorts/presentation/session_status.dart';

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

class _ProtectedRecordedPlayer extends StatefulWidget {
  const _ProtectedRecordedPlayer({
    required this.session,
    required this.relatedResources,
  });

  final CohortSessionModel session;
  final List<CourseResource> relatedResources;

  @override
  State<_ProtectedRecordedPlayer> createState() =>
      _ProtectedRecordedPlayerState();
}

class _ProtectedRecordedPlayerState extends State<_ProtectedRecordedPlayer> {
  YoutubePlayerController? _controller;
  bool _isLoading = true;
  bool _isPlayable = true;
  bool _isFullscreen = false;

  @override
  void initState() {
    super.initState();
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
          disableDragSeek: false,
          enableCaption: false,
          forceHD: false,
          hideControls: false,
          controlsVisibleAtStart: true,
          hideThumbnail: false,
          showLiveFullscreenButton: false,
          // Disable related videos and navigation
          // forceHideAnnotation: true, // Removed: not a valid parameter
        ),
      )..addListener(_onPlayerStateChange);
    } else {
      _isPlayable = false;
      _isLoading = false;
    }
  }

  void _onPlayerStateChange() {
    final controller = _controller;
    if (controller != null && controller.value.isReady && _isLoading) {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final status = resolveSessionStatus(widget.session);
    final controller = _controller;

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
      );
    }

    return YoutubePlayerBuilder(
      onEnterFullScreen: () {
        if (!mounted) return;
        setState(() => _isFullscreen = true);
      },
      onExitFullScreen: () {
        SystemChrome.setPreferredOrientations(DeviceOrientation.values);
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
        );
      },
    );
  }
}

class _RecordedPlayerLayout extends StatelessWidget {
  const _RecordedPlayerLayout({
    required this.session,
    required this.relatedResources,
    required this.status,
    required this.isDark,
    required this.isPlayable,
    required this.isLoading,
    required this.player,
    this.isFullscreen = false,
  });

  final CohortSessionModel session;
  final List<CourseResource> relatedResources;
  final SessionStatusSnapshot status;
  final bool isDark;
  final bool isPlayable;
  final bool isLoading;
  final Widget? player;
  final bool isFullscreen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      top: false,
      bottom: false,
      child: Column(
        children: [
          if (!isFullscreen)
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 30, 22, 14),
              child: Row(
                children: [
                  PremiumIconButton(
                    icon: PhosphorIconsBold.arrowLeft,
                    onTap: () => context.pop(),
                    isDark: isDark,
                  ),
                  const Gap(12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Recorded Session',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: isDark ? Colors.white70 : Colors.black54,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Gap(2),
                        Text(
                          session.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: isDark ? Colors.white : Colors.black,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ColoredBox(
                  color: isDark
                      ? const Color(0xFF1A1A1A)
                      : Colors.grey.shade200,
                ),
                if (player != null)
                  player!
                else
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        isPlayable
                            ? 'Preparing secure playback...'
                            : 'This recording is not in a supported YouTube format yet.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: isDark ? Colors.white70 : Colors.black54,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                if (isLoading)
                  Container(
                    color: isDark
                        ? const Color(0xFF1A1A1A)
                        : Colors.grey.shade200,
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const AppShimmerBlock(
                          width: 84,
                          height: 84,
                          radius: 999,
                        ),
                        const Gap(14),
                        Text(
                          'Loading player...',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: isDark ? Colors.white70 : Colors.black54,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          if (!isFullscreen)
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 24, 22, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _PlayerPill(
                          icon: PhosphorIconsFill.playCircle,
                          label: status.statusLabel,
                          color: AppColors.teal,
                        ),
                        const Gap(10),
                        _PlayerPill(
                          icon: PhosphorIconsFill.calendarDots,
                          label: status.scheduleLabel,
                          color: AppColors.deepBlueLight,
                        ),
                      ],
                    ),
                    const Gap(18),
                    Text(
                      session.pathTitle,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: AppColors.orangeLight,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Gap(6),
                    Text(
                      session.title,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: isDark ? Colors.white : Colors.black,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Gap(10),
                    Text(
                      session.notes.isEmpty
                          ? 'Recording is available now. Class notes will appear here when they are published.'
                          : session.notes,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isDark ? Colors.white70 : Colors.black54,
                        height: 1.65,
                      ),
                    ),
                    const Gap(22),
                    AdaptiveWrap(
                      minItemWidth: 148,
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _RecordedShortcutCard(
                          icon: Icons.support_agent_rounded,
                          accent: AppColors.purple,
                          title: 'Mentor',
                          subtitle: 'Ask a follow up',
                          onTap: () => context.push('/ai-tutor/${session.id}'),
                        ),
                      ],
                    ),
                    const Gap(22),
                    Text(
                      'Session Resources',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Gap(8),
                    Text(
                      relatedResources.isEmpty
                          ? 'No lesson-specific downloads are published yet. Check the main library for shared course materials.'
                          : 'These files were linked to this recording.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isDark ? Colors.white70 : Colors.black54,
                        height: 1.55,
                      ),
                    ),
                    const Gap(14),
                    if (relatedResources.isEmpty)
                      _RecordedShortcutCard(
                        icon: Icons.folder_open_rounded,
                        accent: AppColors.deepBlue,
                        title: 'Full Library',
                        subtitle: 'Browse all published files',
                        onTap: () => context.push('/resources'),
                      )
                    else
                      for (final resource in relatedResources)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: AppCard(
                            child: ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Container(
                                width: 46,
                                height: 46,
                                decoration: BoxDecoration(
                                  color: _resourceBadgeColor(resource.type),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Icon(
                                  _resourceIcon(resource.type),
                                  color: _resourceAccentColor(resource.type),
                                ),
                              ),
                              title: Text(resource.name),
                              subtitle: Text(
                                '${resource.type} • ${resource.size.isEmpty ? 'Open file' : resource.size} • ${resource.date}',
                              ),
                              trailing: const Icon(Icons.open_in_new_rounded),
                              onTap: () => _openResource(context, resource),
                            ),
                          ),
                        ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PlayerPill extends StatelessWidget {
  const _PlayerPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withValues(alpha: 0.24)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const Gap(8),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecordedShortcutCard extends StatelessWidget {
  const _RecordedShortcutCard({
    required this.icon,
    required this.accent,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color accent;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: AppCard(
        radius: 22,
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: Icon(icon, color: accent, size: 20),
            ),
            const Gap(12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Gap(4),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.mutedForeground,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_rounded, color: accent, size: 18),
          ],
        ),
      ),
    );
  }
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
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Search resources, folders, or file types...',
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
                              'No published folders yet. Resources added from the admin dashboard will appear here.',
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
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodySmall?.copyWith(
                                          color: _resourceMutedColor(context),
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
                                'The admin dashboard has not published any course files for your enrollment yet.',
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
                                onTap: () => _openResource(context, resource),
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

Future<void> _openResource(
  BuildContext context,
  CourseResource resource,
) async {
  final rawUrl = resource.url.trim();
  if (rawUrl.isEmpty) {
    showAppSnackBar(
      context,
      'A file link has not been added yet for ${resource.name}.',
    );
    return;
  }

  final uri = Uri.tryParse(rawUrl);
  if (uri == null) {
    showAppSnackBar(context, 'This resource link is not valid yet.');
    return;
  }

  final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!launched && context.mounted) {
    showAppSnackBar(context, 'Could not open ${resource.name} right now.');
  }
}

class AiTutorScreen extends ConsumerStatefulWidget {
  const AiTutorScreen({super.key, required this.lessonId});

  final String lessonId;

  @override
  ConsumerState<AiTutorScreen> createState() => _AiTutorScreenState();
}

class _AiTutorScreenState extends ConsumerState<AiTutorScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    await ref
        .read(aiTutorChatProvider(widget.lessonId).notifier)
        .sendMessage(text);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(aiTutorChatProvider(widget.lessonId));

    return AppScreen(
      body: SafeArea(
        top: false,
        bottom: false,
        child: Column(
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.purple, Color(0xFF6D28D9)],
                ),
              ),
              padding: const EdgeInsets.fromLTRB(22, 30, 22, 20),
              child: PremiumPageHeader(
                title: 'AI Tutor',
                subtitle: 'Always ready to help',
                leading: PremiumIconButton(
                  icon: Icons.arrow_back_rounded,
                  onTap: () => context.pop(),
                  isDark: true,
                ),
                trailing: Container(
                  width: 42,
                  height: 42,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    color: AppColors.purple,
                  ),
                ),
                onDark: true,
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(18),
                children: [
                  for (final message in state.messages)
                    Align(
                      alignment: message.isUser
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        constraints: const BoxConstraints(maxWidth: 310),
                        decoration: BoxDecoration(
                          gradient: message.isUser
                              ? const LinearGradient(
                                  colors: [
                                    AppColors.deepBlue,
                                    AppColors.deepBlueLight,
                                  ],
                                )
                              : null,
                          color: message.isUser ? null : Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(24),
                            topRight: const Radius.circular(24),
                            bottomLeft: Radius.circular(
                              message.isUser ? 24 : 8,
                            ),
                            bottomRight: Radius.circular(
                              message.isUser ? 8 : 24,
                            ),
                          ),
                          boxShadow: message.isUser ? null : AppShadows.card,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (!message.isUser) ...[
                              Row(
                                children: [
                                  const Icon(
                                    Icons.auto_awesome_rounded,
                                    size: 16,
                                    color: AppColors.purple,
                                  ),
                                  const Gap(6),
                                  Text(
                                    'AI Tutor',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelMedium
                                        ?.copyWith(
                                          color: AppColors.purple,
                                          fontWeight: FontWeight.w800,
                                        ),
                                  ),
                                ],
                              ),
                              const Gap(8),
                            ],
                            Text(
                              message.text,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: message.isUser
                                        ? Colors.white
                                        : AppColors.foreground,
                                    height: 1.6,
                                  ),
                            ),
                            const Gap(8),
                            Text(
                              message.time,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: message.isUser
                                        ? Colors.white70
                                        : AppColors.mutedForeground,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (state.isTyping)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: AppShadows.card,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(
                            3,
                            (index) =>
                                Container(
                                      width: 8,
                                      height: 8,
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade400,
                                        shape: BoxShape.circle,
                                      ),
                                    )
                                    .animate(
                                      onPlay: (controller) =>
                                          controller.repeat(),
                                    )
                                    .fade(
                                      delay: (index * 120).ms,
                                      begin: 0.2,
                                      end: 1,
                                    )
                                    .scale(delay: (index * 120).ms),
                          ),
                        ),
                      ),
                    ),
                  if (state.messages.length == 1) ...[
                    const Gap(12),
                    Text(
                      'Quick questions:',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const Gap(10),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          for (final item in DemoData.quickTutorQuestions) ...[
                            OutlinedButton(
                              onPressed: () => _controller.text = item,
                              child: Text(item),
                            ),
                            const Gap(8),
                          ],
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 10, 22, 24),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      onSubmitted: (_) => _send(),
                      decoration: const InputDecoration(
                        hintText: 'Ask me anything...',
                      ),
                    ),
                  ),
                  const Gap(10),
                  InkWell(
                    onTap: _send,
                    borderRadius: BorderRadius.circular(18),
                    child: Container(
                      width: 54,
                      height: 54,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.purple, Color(0xFF6D28D9)],
                        ),
                        borderRadius: BorderRadius.all(Radius.circular(18)),
                      ),
                      child: const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                      ),
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
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
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
          border: Border.all(color: accent.withValues(alpha: isDark ? 0.3 : 0.12)),
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
