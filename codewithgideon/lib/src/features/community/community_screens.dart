import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_controls.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/states/app_state_widgets.dart';
import '../cohorts/models/cohort_message_model.dart';
import '../cohorts/models/cohort_session_model.dart';
import '../entry/state/auth_provider.dart';
import '../home/models/student_dashboard_snapshot.dart';
import '../home/state/dashboard_provider.dart';
import 'models/community_space_model.dart';
import 'models/mentor_request_model.dart';
import 'state/community_notifications_provider.dart';
import 'state/community_spaces_provider.dart';
import 'state/mentor_request_provider.dart';

class CommunityChannelsScreen extends ConsumerStatefulWidget {
  const CommunityChannelsScreen({super.key});

  @override
  ConsumerState<CommunityChannelsScreen> createState() =>
      _CommunityChannelsScreenState();
}

class _CommunityChannelsScreenState
    extends ConsumerState<CommunityChannelsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dashboard = ref.watch(dashboardSnapshotProvider);
    final spaces = ref.watch(communitySpacesProvider);
    final unreadCount = ref.watch(unreadMessagesCountProvider);
    final mentorMessages = ref.watch(
      mentorRequestsProvider(
        const MentorConversationQuery(sessionId: null, conversationId: null),
      ),
    );

    return DoubleBackToExitScope(
      child: AppScreen(
        body: SafeArea(
          top: false,
          bottom: false,
          child: dashboard.when(
            loading: () => const AppLoadingState(
              title: 'Loading community',
              message: 'Preparing your mentor support and student spaces.',
            ),
            error: (error, stackTrace) => AppErrorState(
              title: 'Could not load community',
              message:
                  'We could not prepare your community home right now. Please try again.',
              onRetry: () {
                ref.invalidate(dashboardSnapshotProvider);
                ref.invalidate(communitySpacesProvider);
              },
            ),
            data: (snapshot) {
              final route = _mentorRouteForDashboard(snapshot) ?? '/mentor';
              final liveSpacesCount = spaces.maybeWhen(
                data: (items) => items.length,
                orElse: () => 0,
              );
              final latestMentorReply = mentorMessages.maybeWhen(
                data: (items) =>
                    _latestMentorChat(items.where((m) => m.isAdmin).toList()),
                orElse: () => null,
              );
              final filteredSpaces = spaces.maybeWhen(
                data: (items) => items.where(_matchesQuery).toList(),
                orElse: () => const <CommunitySpaceModel>[],
              );
              final unreadLabel = unreadCount.maybeWhen(
                data: (count) => count == 0 ? 'Inbox clear' : '$count unread',
                orElse: () => 'Checking inbox',
              );

              return CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(22, 28, 22, 16),
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
                        decoration: BoxDecoration(
                          gradient:
                              Theme.of(context).brightness == Brightness.dark
                              ? const LinearGradient(
                                  colors: [
                                    AppColors.deepBlueDark,
                                    Color(0xFF0E2348),
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
                              title: 'Community',
                              subtitle:
                                  'Mentor help, student rooms, and course resources arranged like one learning hub.',
                              onDark: true,
                              trailing: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  PremiumIconButton(
                                    icon: Icons.notifications_none_rounded,
                                    onTap: () =>
                                        context.push('/community/messages'),
                                  ),
                                  if (unreadCount.maybeWhen(
                                    data: (count) => count > 0,
                                    orElse: () => false,
                                  ))
                                    Positioned(
                                      top: -2,
                                      right: -2,
                                      child: Container(
                                        constraints: const BoxConstraints(
                                          minWidth: 18,
                                          minHeight: 18,
                                        ),
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(
                                          color: AppColors.orange,
                                          shape: BoxShape.circle,
                                        ),
                                        child: unreadCount.maybeWhen(
                                          data: (count) => Text(
                                            count > 99 ? '99+' : '$count',
                                            textAlign: TextAlign.center,
                                            style: Theme.of(context)
                                                .textTheme
                                                .labelSmall
                                                ?.copyWith(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w800,
                                                ),
                                          ),
                                          orElse: () => const SizedBox.shrink(),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const Gap(18),
                            Row(
                              children: [
                                Expanded(
                                  child: _CommunityHeroStat(
                                    label: 'Mentor',
                                    value: latestMentorReply == null
                                        ? 'Active'
                                        : 'Online',
                                  ),
                                ),
                                const Gap(10),
                                Expanded(
                                  child: _CommunityHeroStat(
                                    label: 'Rooms',
                                    value: '$liveSpacesCount live',
                                  ),
                                ),
                                const Gap(10),
                                Expanded(
                                  child: _CommunityHeroStat(
                                    label: 'Library',
                                    value:
                                        '${snapshot.libraryResources.length} files',
                                  ),
                                ),
                              ],
                            ),
                            const Gap(18),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(22),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.08),
                                ),
                              ),
                              child: TextField(
                                controller: _searchController,
                                onChanged: (value) => setState(() {
                                  _query = value.trim().toLowerCase();
                                }),
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(color: Colors.white),
                                decoration: InputDecoration(
                                  hintText: 'Search your student spaces...',
                                  hintStyle: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: AppColors.darkMutedForeground,
                                      ),
                                  prefixIcon: Icon(
                                    Icons.search_rounded,
                                    color: Colors.white.withValues(alpha: 0.86),
                                  ),
                                  suffixIcon: _query.isEmpty
                                      ? null
                                      : IconButton(
                                          onPressed: () {
                                            _searchController.clear();
                                            setState(() {
                                              _query = '';
                                            });
                                          },
                                          icon: Icon(
                                            Icons.close_rounded,
                                            color: Colors.white.withValues(
                                              alpha: 0.86,
                                            ),
                                          ),
                                        ),
                                  fillColor: Colors.transparent,
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(22),
                                    borderSide: BorderSide.none,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(22),
                                    borderSide: BorderSide(
                                      color: Colors.white.withValues(
                                        alpha: 0.22,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(22, 0, 22, 18),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Text(
                                'Quick Access',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                              const Spacer(),
                              Text(
                                unreadLabel,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: _contextMutedColor(context),
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                            ],
                          ),
                          const Gap(12),
                          Row(
                            children: [
                              Expanded(
                                child: _ConnectedFeatureCard(
                                  icon: Icons.support_agent_rounded,
                                  accent: AppColors.tealDark,
                                  title: 'Mentor Support',
                                  eyebrow: snapshot.heroLabel,
                                  description: latestMentorReply == null
                                      ? 'For quick support and feedback.'
                                      : latestMentorReply.body,
                                  onTap: () => context.push(route),
                                  badge: latestMentorReply == null
                                      ? null
                                      : 'Reply ready',
                                ),
                              ),
                              const Gap(12),
                              Expanded(
                                child: _ConnectedFeatureCard(
                                  icon: Icons.menu_book_rounded,
                                  accent: AppColors.deepBlueLight,
                                  title: 'Resource Library',
                                  eyebrow:
                                      '${snapshot.libraryResources.length} published',
                                  description:
                                      'Open class-ready notes, links, and downloads.',
                                  onTap: () => context.push('/resources'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(22, 2, 22, 130),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        Row(
                          children: [
                            Text(
                              'Student Spaces',
                              style: Theme.of(context).textTheme.labelLarge
                                  ?.copyWith(
                                    color: _contextMutedColor(context),
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                            const Spacer(),
                            spaces.maybeWhen(
                              data: (items) => Text(
                                '${items.length} published',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: _contextMutedColor(context),
                                    ),
                              ),
                              orElse: () => const SizedBox.shrink(),
                            ),
                          ],
                        ),
                        const Gap(12),
                        Text(
                          'Tap into rooms, meet, support and discuss',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: _contextMutedColor(context),
                                height: 1.5,
                              ),
                        ),
                        const Gap(14),
                        spaces.when(
                          loading: () => const AppLoadingState(
                            title: 'Loading spaces',
                            message: 'Pulling the latest rooms.',
                            compact: true,
                          ),
                          error: (error, stackTrace) => AppErrorState(
                            title: 'Could not load spaces',
                            message:
                                'Student spaces are temporarily unavailable. Please try again.',
                            onRetry: () =>
                                ref.invalidate(communitySpacesProvider),
                          ),
                          data: (_) {
                            if (filteredSpaces.isEmpty) {
                              return AppEmptyState(
                                title: _query.isEmpty
                                    ? 'No student spaces yet'
                                    : 'No matching spaces',
                                message: _query.isEmpty
                                    ? 'No published room for this cohort yet.'
                                    : 'Try another keyword or clear the search to see every published room.',
                                icon: Icons.forum_outlined,
                              );
                            }

                            return Column(
                              children: [
                                for (final space in filteredSpaces) ...[
                                  _CommunitySpaceTile(space: space),
                                  const Gap(12),
                                ],
                              ],
                            );
                          },
                        ),
                      ]),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  bool _matchesQuery(CommunitySpaceModel space) {
    if (_query.isEmpty) return true;
    return space.title.toLowerCase().contains(_query) ||
        space.description.toLowerCase().contains(_query) ||
        (space.category ?? '').toLowerCase().contains(_query);
  }
}

class ClassChatScreen extends ConsumerWidget {
  const ClassChatScreen({super.key, required this.channelId});

  final String channelId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final space = ref.watch(communitySpaceByIdProvider(channelId));
    return AppScreen(
      body: SafeArea(
        top: false,
        bottom: false,
        child: space == null
            ? AppEmptyState(
                title: 'Space unavailable',
                message:
                    'This student space is not available for your cohort right now.',
                icon: Icons.forum_outlined,
                action: AppButton(
                  label: 'Back to Community',
                  expanded: false,
                  onPressed: () => context.go('/community'),
                ),
              )
            : Padding(
                padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    PremiumPageHeader(
                      title: space.title,
                      subtitle: space.cohortLabel?.trim().isNotEmpty == true
                          ? space.cohortLabel
                          : 'Student space',
                      leading: PremiumIconButton(
                        icon: Icons.arrow_back_rounded,
                        onTap: () => context.pop(),
                      ),
                    ),
                    const Gap(18),
                    AppCard(
                      radius: 28,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  color: AppColors.deepBlue.withValues(
                                    alpha: 0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                alignment: Alignment.center,
                                child: Icon(
                                  space.icon,
                                  color: AppColors.deepBlueDark,
                                ),
                              ),
                              const Gap(14),
                              Expanded(
                                child: Text(
                                  space.description,
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: AppColors.mutedForeground,
                                        height: 1.55,
                                      ),
                                ),
                              ),
                            ],
                          ),
                          const Gap(18),
                          AppButton(
                            label: space.actionLabel,
                            onPressed: () =>
                                _openCommunitySpace(context, space),
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

class AskMentorScreen extends ConsumerStatefulWidget {
  const AskMentorScreen({
    super.key,
    required this.sessionId,
    required this.contextType,
  });

  final String? sessionId;
  final MentorRequestContext contextType;

  @override
  ConsumerState<AskMentorScreen> createState() => _AskMentorScreenState();
}

class _AskMentorScreenState extends ConsumerState<AskMentorScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<MentorChatMessage> _optimisticMessages = <MentorChatMessage>[];
  bool _isSending = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dashboardAsync = ref.watch(dashboardSnapshotProvider);
    final conversationAsync = ref.watch(
      mentorRequestsProvider(
        MentorConversationQuery(
          sessionId: widget.sessionId,
          conversationId: null,
        ),
      ),
    );
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final session = dashboardAsync.maybeWhen(
      data: _resolveSession,
      orElse: () => null,
    );
    final heading = session?.title ?? 'Ask Mentor';
    final pathLabel = session?.pathTitle ?? 'Private support channel';
    final contextLabel = widget.contextType == MentorRequestContext.live
        ? 'Live class support'
        : 'Recorded lesson follow up';
    final storedMessages = conversationAsync.maybeWhen(
      data: (items) => items,
      orElse: () => const <MentorChatMessage>[],
    );
    final mergedMessages = mergeChatTimeline(
      storedMessages,
      _optimisticMessages,
    );
    final syncedOptimistic = reconcileOptimistic(
      optimistic: _optimisticMessages,
      persisted: storedMessages,
    );

    if (syncedOptimistic.length != _optimisticMessages.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _optimisticMessages
            ..clear()
            ..addAll(syncedOptimistic);
        });
      });
    }

    final isSyncingConversation =
        conversationAsync.isLoading && storedMessages.isEmpty;

    return AppScreen(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        top: false,
        bottom: false,
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: isDark
                    ? const LinearGradient(
                        colors: [AppColors.deepBlueDark, Color(0xFF12356D)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : AppGradients.primary,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(30),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
              child: Column(
                children: [
                  Row(
                    children: [
                      PremiumIconButton(
                        icon: Icons.arrow_back_rounded,
                        onTap: () => context.pop(),
                        isDark: true,
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          contextLabel,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Gap(14),
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.support_agent_rounded,
                          color: Colors.white,
                        ),
                      ),
                      const Gap(12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Mentor Chat',
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const Gap(4),
                            Text(
                              heading,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.white.withValues(alpha: 0.86),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Gap(14),
                  Row(
                    children: [
                      Expanded(
                        child: _MentorHeaderPill(
                          icon: Icons.route_outlined,
                          label: pathLabel,
                        ),
                      ),
                      const Gap(10),
                      _MentorHeaderPill(
                        icon: isSyncingConversation
                            ? Icons.sync_rounded
                            : mergedMessages.isEmpty
                            ? Icons.mark_chat_unread_outlined
                            : Icons.verified_rounded,
                        label: isSyncingConversation
                            ? 'Syncing'
                            : mergedMessages.isEmpty
                            ? 'Listening'
                            : 'Synced',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkBackground
                      : AppColors.background,
                ),
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
                        child: Column(
                          children: [
                            _MentorIntroBubble(isDark: isDark),
                            if (mergedMessages.isEmpty)
                              const _MentorEmptyConversation(),
                          ],
                        ),
                      ),
                    ),
                    ..._buildConversationTiles(mergedMessages),
                    const SliverToBoxAdapter(child: Gap(14)),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F182A) : Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.deepBlue.withValues(
                      alpha: isDark ? 0.14 : 0.05,
                    ),
                    blurRadius: 18,
                    offset: const Offset(0, -6),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurface : Colors.white,
                        borderRadius: BorderRadius.circular(28),
                      ),
                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
                      child: TextField(
                        controller: _controller,
                        minLines: 1,
                        maxLines: 5,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: isDark
                              ? AppColors.darkForeground
                              : AppColors.foreground,
                        ),
                        decoration: InputDecoration(
                          hintText: isSyncingConversation
                              ? 'Conversation is syncing... you can still type'
                              : 'Message mentor',
                          hintStyle: theme.textTheme.bodyMedium?.copyWith(
                            color: isDark
                                ? AppColors.darkMutedForeground
                                : AppColors.mutedForeground,
                          ),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                  const Gap(10),
                  InkWell(
                    onTap: _isSending ? null : _submit,
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.teal : AppColors.deepBlue,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Opacity(
                        opacity: _isSending ? 0.6 : 1,
                        child: const Icon(
                          Icons.send_rounded,
                          color: Colors.white,
                        ),
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

  CohortSessionModel? _resolveSession(StudentDashboardSnapshot dashboard) {
    if (widget.sessionId == null) {
      return dashboard.liveSession ??
          dashboard.latestUnlockedSession ??
          dashboard.nextSession ??
          dashboard.latestRecordedSession;
    }

    for (final item in dashboard.unlockedSessions) {
      if (item.id == widget.sessionId) return item;
    }
    return null;
  }

  Future<void> _submit() async {
    final message = _controller.text.trim();
    if (message.isEmpty || _isSending) return;
    final clientMessageId =
        'client-${DateTime.now().microsecondsSinceEpoch}-${widget.sessionId ?? 'mentor'}';

    final dashboard = await ref.read(dashboardSnapshotProvider.future);
    final session = _resolveSession(dashboard);
    if (session == null) {
      if (!mounted) return;
      showAppSnackBar(
        context,
        'We could not find the class context for this mentor chat yet.',
      );
      return;
    }

    final optimistic = MentorChatMessage(
      id: 'optimistic-${DateTime.now().microsecondsSinceEpoch}',
      conversationId: '',
      sessionId: session.id,
      body: message,
      senderType: MentorChatSenderType.user,
      senderName: dashboard.profile.fullName,
      createdAt: DateTime.now(),
      senderEmail: dashboard.profile.email,
      status: 'sending',
      clientMessageId: clientMessageId,
    );

    setState(() {
      _isSending = true;
      _optimisticMessages.add(optimistic);
      _controller.clear();
    });
    unawaited(_persistOptimisticMessages());

    try {
      final conversationId = await ref
          .read(mentorRequestRepositoryProvider)
          .submitRequest(
            dashboard: dashboard,
            session: session,
            message: message,
            contextType: widget.contextType,
            clientMessageId: clientMessageId,
          );
      if (conversationId.isNotEmpty) {
        ref
                .read(
                  mentorConversationIdOverrideProvider(
                    widget.sessionId,
                  ).notifier,
                )
                .state =
            conversationId;
      }
      if (mounted) {
        setState(() {
          final index = _optimisticMessages.indexWhere(
            (item) => item.id == optimistic.id,
          );
          if (index >= 0) {
            _optimisticMessages[index] = MentorChatMessage(
              id: optimistic.id,
              conversationId: conversationId,
              sessionId: optimistic.sessionId,
              body: optimistic.body,
              senderType: optimistic.senderType,
              senderName: optimistic.senderName,
              createdAt: optimistic.createdAt,
              senderEmail: optimistic.senderEmail,
              status: 'sent',
              source: optimistic.source,
              clientMessageId: optimistic.clientMessageId,
              isConversationStarter: optimistic.isConversationStarter,
            );
          }
        });
      }
      unawaited(_persistOptimisticMessages());
      ref.invalidate(
        mentorRequestsProvider(
          MentorConversationQuery(
            sessionId: widget.sessionId,
            conversationId: conversationId.isEmpty ? null : conversationId,
          ),
        ),
      );
      ref.invalidate(
        mentorRequestsProvider(
          const MentorConversationQuery(sessionId: null, conversationId: null),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _optimisticMessages.removeWhere((item) => item.id == optimistic.id);
        _controller.text = message;
        _controller.selection = TextSelection.collapsed(
          offset: _controller.text.length,
        );
      });
      unawaited(_persistOptimisticMessages());
      showAppSnackBar(context, 'Message not sent. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  Future<void> _persistOptimisticMessages() async {
    final authState = ref.read(authControllerProvider);
    final session = authState.session;
    if (session == null) return;

    final repository = ref.read(mentorRequestRepositoryProvider);
    final cached = await repository.loadCachedConversation(
      studentUid: session.uid,
      sessionId: widget.sessionId,
    );
    final merged = mergeChatTimeline(cached, _optimisticMessages);
    await repository.saveCachedConversation(
      studentUid: session.uid,
      sessionId: widget.sessionId,
      messages: merged,
    );
  }
}

class DirectMessagesScreen extends ConsumerStatefulWidget {
  const DirectMessagesScreen({super.key});

  @override
  ConsumerState<DirectMessagesScreen> createState() =>
      _DirectMessagesScreenState();
}

class _DirectMessagesScreenState extends ConsumerState<DirectMessagesScreen> {
  Set<String> _readIds = <String>{};
  Set<String> _hiddenIds = <String>{};
  bool _notificationPrefsReady = false;

  @override
  void initState() {
    super.initState();
    _loadNotificationPrefs();
  }

  Future<void> _loadNotificationPrefs() async {
    final readIds = await loadReadNotificationIds();
    final hiddenIds = await loadHiddenNotificationIds();
    if (!mounted) return;
    setState(() {
      _readIds = readIds;
      _hiddenIds = hiddenIds;
      _notificationPrefsReady = true;
    });
  }

  Future<void> _openCohortMessageUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;

    final canLaunch = await canLaunchUrl(uri);
    if (!mounted) return;
    if (!canLaunch) {
      showAppSnackBar(context, 'Cannot open this link right now.');
      return;
    }

    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _openCohortMessage(CohortMessageModel item) async {
    await markNotificationRead(item);
    if (!mounted) return;
    setState(() {
      _readIds = {..._readIds, item.id};
    });
    ref.invalidate(unreadMessagesCountProvider);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: AppCard(
              radius: 28,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.teal,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.notifications_active_rounded,
                          color: Colors.white,
                        ),
                      ),
                      const Gap(12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            const Gap(4),
                            Text(
                              item.cohortLabel.isEmpty
                                  ? 'Cohort update'
                                  : item.cohortLabel,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Gap(18),
                  Text(
                    item.body,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.mutedForeground,
                      height: 1.55,
                    ),
                  ),
                  const Gap(18),
                  if (item.hasCta)
                    AppButton(
                      label: item.ctaLabel,
                      expanded: false,
                      onPressed: () async {
                        Navigator.of(context).pop();
                        await _openCohortMessageUrl(item.ctaUrl);
                      },
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _markAllAsRead(List<CohortMessageModel> messages) async {
    if (messages.isEmpty) return;
    await markNotificationsRead(messages);
    if (!mounted) return;
    setState(() {
      _readIds = {..._readIds, ...messages.map((item) => item.id)};
    });
    ref.invalidate(unreadMessagesCountProvider);
  }

  Future<void> _clearAllNotifications(List<CohortMessageModel> messages) async {
    if (messages.isEmpty) return;
    await clearNotifications(messages);
    if (!mounted) return;
    setState(() {
      _hiddenIds = {..._hiddenIds, ...messages.map((item) => item.id)};
      _readIds = {..._readIds, ...messages.map((item) => item.id)};
    });
    ref.invalidate(unreadMessagesCountProvider);
  }

  @override
  Widget build(BuildContext context) {
    final cohortMessages = ref.watch(cohortMessagesProvider);
    return cohortMessages.when(
      loading: () => const AppScreen(
        body: SafeArea(
          top: false,
          bottom: false,
          child: AppLoadingState(
            title: 'Loading messages...',
            message: 'We are pulling the latest cohort updates.',
            compact: true,
          ),
        ),
      ),
      error: (error, stackTrace) => AppScreen(
        body: SafeArea(
          top: false,
          child: AppErrorState(
            title: 'Could not load messages',
            message:
                'We could not fetch your cohort messages right now. Please try again.',
            onRetry: () => ref.refresh(cohortMessagesProvider),
          ),
        ),
      ),
      data: (messages) {
        final visibleMessages = messages
            .where((item) => !_hiddenIds.contains(item.id))
            .toList();
        final unreadCount = visibleMessages
            .where((item) => !_readIds.contains(item.id))
            .length;

        return AppScreen(
          body: SafeArea(
            top: false,
            bottom: false,
            child: Column(
              children: [
                Container(
                  decoration: const BoxDecoration(
                    gradient: AppGradients.primary,
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(36),
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(22, 30, 22, 24),
                  child: Column(
                    children: [
                      PremiumPageHeader(
                        title: 'Notifications',
                        subtitle:
                            'Announcements, updates, and action items from your cohort team.',
                        leading: PremiumIconButton(
                          icon: Icons.arrow_back_rounded,
                          onTap: () => context.pop(),
                          isDark: true,
                        ),
                        onDark: true,
                      ),
                      const Gap(18),
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.14),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.16),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.notifications_active_rounded,
                                color: Colors.white,
                              ),
                            ),
                            const Gap(12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    unreadCount == 0
                                        ? 'All caught up'
                                        : '$unreadCount unread update${unreadCount == 1 ? '' : 's'}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w800,
                                        ),
                                  ),
                                  const Gap(4),
                                  Text(
                                    'Tap any card to open the full notification and follow links.',
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: Colors.white.withValues(
                                            alpha: 0.82,
                                          ),
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
                ),
                Expanded(
                  child: !_notificationPrefsReady
                      ? const AppLoadingState(
                          title: 'Preparing notifications',
                          message: 'Syncing what you have already read.',
                          compact: true,
                        )
                      : visibleMessages.isEmpty
                      ? AppEmptyState(
                          title: 'No notifications left',
                          message: messages.isEmpty
                              ? 'Your mentor has not sent any cohort messages yet.'
                              : 'Everything here has been cleared.',
                          icon: Icons.notifications_off_outlined,
                        )
                      : ListView(
                          padding: const EdgeInsets.fromLTRB(22, 18, 22, 28),
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: AppButton(
                                    label: 'Mark All Read',
                                    expanded: false,
                                    variant: AppButtonVariant.outline,
                                    onPressed: () =>
                                        _markAllAsRead(visibleMessages),
                                  ),
                                ),
                                const Gap(10),
                                Expanded(
                                  child: AppButton(
                                    label: 'Clear',
                                    expanded: false,
                                    variant: AppButtonVariant.ghost,
                                    onPressed: () =>
                                        _clearAllNotifications(visibleMessages),
                                  ),
                                ),
                              ],
                            ),
                            const Gap(16),
                            ...List.generate(visibleMessages.length, (index) {
                              final item = visibleMessages[index];
                              final isUnread = !_readIds.contains(item.id);
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () => _openCohortMessage(item),
                                    borderRadius: BorderRadius.circular(28),
                                    child: AppCard(
                                      radius: 28,
                                      color: isUnread
                                          ? AppColors.deepBlue.withValues(
                                              alpha: 0.04,
                                            )
                                          : null,
                                      border: Border.all(
                                        color: isUnread
                                            ? AppColors.teal.withValues(
                                                alpha: 0.26,
                                              )
                                            : AppColors.deepBlue.withValues(
                                                alpha: 0.06,
                                              ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Container(
                                                width: 44,
                                                height: 44,
                                                decoration: BoxDecoration(
                                                  gradient: isUnread
                                                      ? AppGradients.primary
                                                      : AppGradients.accent,
                                                  borderRadius:
                                                      BorderRadius.circular(16),
                                                ),
                                                alignment: Alignment.center,
                                                child: Icon(
                                                  isUnread
                                                      ? Icons
                                                            .mark_chat_unread_rounded
                                                      : Icons.drafts_rounded,
                                                  color: Colors.white,
                                                ),
                                              ),
                                              const Gap(14),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
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
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w800,
                                                                ),
                                                          ),
                                                        ),
                                                        Container(
                                                          padding:
                                                              const EdgeInsets.symmetric(
                                                                horizontal: 10,
                                                                vertical: 6,
                                                              ),
                                                          decoration: BoxDecoration(
                                                            color: isUnread
                                                                ? AppColors
                                                                      .orange
                                                                      .withValues(
                                                                        alpha:
                                                                            0.14,
                                                                      )
                                                                : AppColors.teal
                                                                      .withValues(
                                                                        alpha:
                                                                            0.14,
                                                                      ),
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  999,
                                                                ),
                                                          ),
                                                          child: Text(
                                                            isUnread
                                                                ? 'New'
                                                                : 'Read',
                                                            style: Theme.of(context)
                                                                .textTheme
                                                                .labelSmall
                                                                ?.copyWith(
                                                                  color:
                                                                      isUnread
                                                                      ? AppColors
                                                                            .orange
                                                                      : AppColors
                                                                            .teal,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w800,
                                                                ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    const Gap(6),
                                                    Text(
                                                      item.body,
                                                      maxLines: 3,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .bodyMedium
                                                          ?.copyWith(
                                                            color: AppColors
                                                                .mutedForeground,
                                                            height: 1.5,
                                                          ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                          const Gap(14),
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.schedule_rounded,
                                                size: 16,
                                                color:
                                                    AppColors.mutedForeground,
                                              ),
                                              const Gap(6),
                                              Text(
                                                MaterialLocalizations.of(
                                                  context,
                                                ).formatShortDate(
                                                  item.createdAt,
                                                ),
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .labelMedium
                                                    ?.copyWith(
                                                      color: AppColors
                                                          .mutedForeground,
                                                    ),
                                              ),
                                              const Spacer(),
                                              Text(
                                                item.hasCta
                                                    ? 'Open update'
                                                    : 'View details',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .labelMedium
                                                    ?.copyWith(
                                                      color: AppColors.teal,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                              ),
                                              const Gap(8),
                                              const Icon(
                                                Icons.arrow_forward_rounded,
                                                color: AppColors.teal,
                                                size: 18,
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }),
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

String? _mentorRouteForDashboard(StudentDashboardSnapshot? dashboard) {
  final session = _preferredMentorSession(dashboard);
  if (session == null) return null;
  final isLive = dashboard?.liveSession?.id == session.id;
  return isLive
      ? '/ai-tutor/${session.id}?source=live'
      : '/ai-tutor/${session.id}';
}

CohortSessionModel? _preferredMentorSession(
  StudentDashboardSnapshot? dashboard,
) {
  if (dashboard == null) return null;
  return dashboard.liveSession ??
      dashboard.latestUnlockedSession ??
      dashboard.nextSession ??
      dashboard.latestRecordedSession;
}

MentorChatMessage? _latestMentorChat(List<MentorChatMessage> messages) {
  if (messages.isEmpty) return null;
  final sorted = [...messages]
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return sorted.first;
}

Future<void> _openCommunitySpace(
  BuildContext context,
  CommunitySpaceModel space,
) async {
  final uri = Uri.tryParse(space.roomUrl ?? '');
  if (uri == null) {
    showAppSnackBar(context, 'This space link is not ready yet.');
    return;
  }

  final canLaunch = await canLaunchUrl(uri);
  if (!context.mounted) return;
  if (!canLaunch) {
    showAppSnackBar(context, 'Cannot open this community room right now.');
    return;
  }

  await launchUrl(uri, mode: LaunchMode.externalApplication);
}

class _CommunitySpaceTile extends StatelessWidget {
  const _CommunitySpaceTile({required this.space});

  final CommunitySpaceModel space;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = _communityAccent(space.category);
    return InkWell(
      onTap: () => context.push('/community/chat/${space.id}'),
      borderRadius: BorderRadius.circular(26),
      child: Ink(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF111C2E)
              : Colors.white.withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(
            color: accent.withValues(alpha: isDark ? 0.34 : 0.16),
          ),
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                    color: AppColors.deepBlue.withValues(alpha: 0.06),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: isDark ? 0.24 : 0.12),
                borderRadius: BorderRadius.circular(18),
              ),
              alignment: Alignment.center,
              child: Icon(space.icon, color: accent),
            ),
            const Gap(14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        space.title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if ((space.category ?? '').trim().isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: accent.withValues(
                              alpha: isDark ? 0.18 : 0.1,
                            ),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            (space.category ?? '').trim(),
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: accent,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                        ),
                    ],
                  ),
                  const Gap(8),
                  Text(
                    space.description,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: _contextMutedColor(context),
                      height: 1.52,
                    ),
                  ),
                  const Gap(10),
                  Row(
                    children: [
                      Text(
                        'Open room',
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: accent,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const Gap(6),
                      Icon(
                        Icons.arrow_outward_rounded,
                        size: 16,
                        color: accent,
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

class _ConnectedFeatureCard extends StatelessWidget {
  const _ConnectedFeatureCard({
    required this.icon,
    required this.accent,
    required this.title,
    required this.eyebrow,
    required this.description,
    required this.onTap,
    this.badge,
  });

  final IconData icon;
  final Color accent;
  final String title;
  final String eyebrow;
  final String description;
  final VoidCallback onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(26),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF111C2E)
              : Colors.white.withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(
            color: accent.withValues(alpha: isDark ? 0.34 : 0.14),
          ),
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.08),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: Icon(icon, color: accent, size: 18),
                ),
                const Spacer(),
                if (badge != null)
                  Flexible(
                    child: Align(
                      alignment: Alignment.topRight,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          badge!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          softWrap: false,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: accent,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const Gap(12),
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const Gap(4),
            Text(
              eyebrow,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: accent,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Gap(6),
            Text(
              description,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: _contextMutedColor(context),
                height: 1.52,
              ),
            ),
            const Gap(12),
            Row(
              children: [
                Text(
                  'Open',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Gap(6),
                Icon(Icons.arrow_outward_rounded, size: 16, color: accent),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CommunityHeroStat extends StatelessWidget {
  const _CommunityHeroStat({required this.label, required this.value});

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
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

Color _communityAccent(String? category) {
  final normalized = (category ?? '').trim().toLowerCase();
  if (normalized.contains('discord')) return const Color(0xFF6366F1);
  if (normalized.contains('whatsapp')) return const Color(0xFF16A34A);
  if (normalized.contains('network')) return AppColors.orange;
  return AppColors.deepBlueLight;
}

Color _contextMutedColor(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark
      ? AppColors.darkMutedForeground
      : AppColors.mutedForeground;
}

class _MentorHeaderPill extends StatelessWidget {
  const _MentorHeaderPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: Colors.white.withValues(alpha: 0.82)),
          const Gap(8),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Colors.white.withValues(alpha: 0.86),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MentorIntroBubble extends StatelessWidget {
  const _MentorIntroBubble({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.darkSurface
              : AppColors.deepBlue.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark
                ? AppColors.darkBorder
                : AppColors.deepBlue.withValues(alpha: 0.08),
          ),
        ),
        child: Text(
          'Mentor replies appear here as you start the conversation. Tap the message box below to send your first message.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: isDark ? AppColors.darkForeground : AppColors.deepBlue,
          ),
        ),
      ),
    );
  }
}

class _MentorEmptyConversation extends StatelessWidget {
  const _MentorEmptyConversation();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 42),
      child: Column(
        children: [
          Icon(
            Icons.mark_chat_unread_outlined,
            color: AppColors.mutedForeground.withValues(alpha: 0.7),
            size: 28,
          ),
          const Gap(10),
          Text(
            'Start the conversation',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const Gap(6),
          Text(
            'Send your first message',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.mutedForeground),
          ),
        ],
      ),
    );
  }
}

class _MentorDayChip extends StatelessWidget {
  const _MentorDayChip({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isDark
                ? AppColors.darkBorder
                : AppColors.deepBlue.withValues(alpha: 0.08),
          ),
        ),
        child: Text(
          _formatMentorDay(date),
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(color: AppColors.mutedForeground),
        ),
      ),
    );
  }
}

class _MentorChatBubble extends StatelessWidget {
  const _MentorChatBubble({required this.message});

  final MentorChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isMine = message.isMine;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bubbleColor = isMine
        ? (isDark ? AppColors.deepBlueLight : AppColors.deepBlue)
        : (isDark ? AppColors.darkSurface : AppColors.surface);
    final radius = isMine
        ? const BorderRadius.only(
            topLeft: Radius.circular(22),
            topRight: Radius.circular(22),
            bottomLeft: Radius.circular(22),
            bottomRight: Radius.circular(6),
          )
        : const BorderRadius.only(
            topLeft: Radius.circular(22),
            topRight: Radius.circular(22),
            bottomLeft: Radius.circular(6),
            bottomRight: Radius.circular(22),
          );

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isMine
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Container(
            constraints: const BoxConstraints(maxWidth: 318),
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            decoration: BoxDecoration(
              color: bubbleColor,
              borderRadius: radius,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.16 : 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isMine) ...[
                  Text(
                    message.senderName,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: isDark ? AppColors.tealLight : AppColors.tealDark,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Gap(4),
                ],
                Text(
                  message.body,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isMine
                        ? Colors.white
                        : isDark
                        ? AppColors.darkForeground
                        : AppColors.foreground,
                    height: 1.5,
                  ),
                ),
                const Gap(6),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (message.isSending) ...[
                      SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.8,
                          color: isMine
                              ? Colors.white.withValues(alpha: 0.92)
                              : AppColors.teal,
                        ),
                      ),
                      const Gap(6),
                    ],
                    Text(
                      message.isSending
                          ? 'Sending...'
                          : _formatMentorMessageTime(message.createdAt),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: isMine
                            ? Colors.white.withValues(alpha: 0.78)
                            : AppColors.mutedForeground,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (isMine) ...[
                      const Gap(6),
                      Icon(
                        message.isSending
                            ? Icons.schedule_rounded
                            : message.isResolved
                            ? Icons.done_all_rounded
                            : message.isRead
                            ? Icons.done_all_rounded
                            : Icons.done_rounded,
                        size: 16,
                        color: isMine
                            ? Colors.white.withValues(
                                alpha: message.isResolved || message.isRead
                                    ? 0.92
                                    : 0.72,
                              )
                            : message.isResolved || message.isRead
                            ? AppColors.tealDark
                            : AppColors.mutedForeground,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

List<Widget> _buildConversationTiles(List<MentorChatMessage> messages) {
  if (messages.isEmpty) return const <Widget>[];

  final slivers = <Widget>[];
  DateTime? lastDay;

  for (final message in messages) {
    final day = DateTime(
      message.createdAt.year,
      message.createdAt.month,
      message.createdAt.day,
    );
    if (lastDay == null || day != lastDay) {
      slivers.add(
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: _MentorDayChip(date: day),
          ),
        ),
      );
      lastDay = day;
    }

    slivers.add(
      SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            message.isMine ? 78 : 16,
            0,
            message.isMine ? 16 : 78,
            10,
          ),
          child: _MentorChatBubble(message: message),
        ),
      ),
    );
  }

  return slivers;
}

String _formatMentorMessageTime(DateTime timestamp) {
  final now = DateTime.now();
  final difference = now.difference(timestamp);
  if (difference.inDays == 0) {
    final hour = timestamp.hour % 12 == 0 ? 12 : timestamp.hour % 12;
    final minute = timestamp.minute.toString().padLeft(2, '0');
    final meridiem = timestamp.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $meridiem';
  }
  return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
}

String _formatMentorDay(DateTime timestamp) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final target = DateTime(timestamp.year, timestamp.month, timestamp.day);
  final difference = today.difference(target).inDays;

  if (difference == 0) return 'Today';
  if (difference == 1) return 'Yesterday';
  return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
}
