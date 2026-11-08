import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
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

/// The Chat tab: the conversation with Gideon, or the cohort's community
/// rooms.
class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  bool _community = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final hasNewGroupMessages = ref
        .watch(cohortMessagesProvider)
        .maybeWhen(
          data: (items) => items.any(
            (item) => item.createdAt.isAfter(
              DateTime.now().subtract(const Duration(days: 1)),
            ),
          ),
          orElse: () => false,
        );

    Widget segment(String label, bool selected, {bool dot = false}) {
      return Expanded(
        child: Semantics(
          button: true,
          selected: selected,
          child: GestureDetector(
            onTap: () => setState(() => _community = label == 'Community'),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: selected ? theme.cardColor : Colors.transparent,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    ),
                  ),
                  if (dot) ...[
                    const Gap(6),
                    const CircleAvatar(
                      radius: 3.5,
                      backgroundColor: AppColors.orange,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
    }

    return DoubleBackToExitScope(
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Chat', style: theme.textTheme.displayMedium),
                  const Gap(16),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkMuted : AppColors.muted,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      children: [
                        segment('Gideon', !_community),
                        segment(
                          'Community',
                          _community,
                          dot: hasNewGroupMessages && !_community,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _community
                  ? const _CommunityRooms()
                  : const AskMentorScreen(
                      sessionId: null,
                      contextType: MentorRequestContext.recorded,
                      embedded: true,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CommunityRooms extends ConsumerWidget {
  const _CommunityRooms();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spaces = ref.watch(communitySpacesProvider);
    return RefreshIndicator(
      color: AppColors.teal,
      onRefresh: () async => ref.invalidate(communitySpacesProvider),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 120),
        children: [
          spaces.when(
            loading: () => const AppLoadingState(
              title: 'Loading rooms',
              message: 'Pulling the latest rooms for your cohort.',
              compact: true,
            ),
            error: (error, stackTrace) => AppErrorState(
              title: 'Could not load rooms',
              message: 'Community rooms are unavailable right now.',
              onRetry: () => ref.invalidate(communitySpacesProvider),
            ),
            data: (items) {
              if (items.isEmpty) {
                return const AppEmptyState(
                  title: 'No rooms yet',
                  message:
                      'Your cohort room shows here once Gideon opens it.',
                  icon: Icons.forum_outlined,
                );
              }
              return Column(
                children: [
                  for (final space in items) ...[
                    _CommunitySpaceTile(space: space),
                    const Gap(12),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
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
    this.initialText = '',
    this.embedded = false,
  });

  final String? sessionId;
  final MentorRequestContext contextType;

  /// Shown inside the Chat tab: no back button, room for the tab bar.
  final bool embedded;

  /// Typed into the message box on open, e.g. the moment of a recording.
  final String initialText;

  @override
  ConsumerState<AskMentorScreen> createState() => _AskMentorScreenState();
}

const _generalMentorSessionId = 'general';

class _AskMentorScreenState extends ConsumerState<AskMentorScreen> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialText,
  );
  final List<MentorChatMessage> _optimisticMessages = <MentorChatMessage>[];
  final Set<String> _locallyReadMentorReplyIds = <String>{};
  bool _isSending = false;

  /// Screenshots chosen for the next message (the server takes up to 3).
  final List<XFile> _picked = <XFile>[];

  String get _conversationSessionId {
    return _generalMentorSessionId;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final conversationSessionId = _conversationSessionId;
    final conversationAsync = ref.watch(
      mentorRequestsProvider(
        MentorConversationQuery(
          sessionId: conversationSessionId,
          conversationId: null,
        ),
      ),
    );
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final storedMessages = conversationAsync.maybeWhen(
      data: (items) => items,
      orElse: () => const <MentorChatMessage>[],
    );
    final mergedMessages = mergeChatTimeline(
      storedMessages,
      _optimisticMessages,
    );
    _markVisibleMentorRepliesRead(mergedMessages);
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

    final muted = isDark
        ? AppColors.darkMutedForeground
        : AppColors.mutedForeground;
    final content = Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Row(
                children: [
                  if (!widget.embedded) ...[
                    Semantics(
                      button: true,
                      label: 'Back',
                      child: InkWell(
                        onTap: () => context.pop(),
                        customBorder: const CircleBorder(),
                        child: CircleAvatar(
                          radius: 20,
                          backgroundColor: theme.cardColor,
                          child: Icon(
                            Icons.arrow_back_rounded,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ),
                    const Gap(10),
                  ],
                  const CircleAvatar(
                    radius: 22,
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
                        Text(
                          'Gideon · Mentor',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          isSyncingConversation
                              ? 'Syncing your conversation...'
                              : 'Usually replies within a few hours',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
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
                            if (mergedMessages.isEmpty) ...[
                              _MentorIntroBubble(isDark: isDark),
                              const _MentorEmptyConversation(),
                            ],
                          ],
                        ),
                      ),
                    ),
                    ..._buildConversationTiles(mergedMessages),
                    const SliverToBoxAdapter(child: Gap(14)),
                  ],
                ),
            ),
            if (_picked.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Row(
                  children: [
                    for (final file in _picked)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(
                                File(file.path),
                                width: 64,
                                height: 64,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: -8,
                              right: -8,
                              child: IconButton.filledTonal(
                                tooltip: 'Remove screenshot',
                                visualDensity: VisualDensity.compact,
                                iconSize: 16,
                                onPressed: _isSending
                                    ? null
                                    : () => setState(
                                        () => _picked.remove(file),
                                      ),
                                icon: const Icon(Icons.close_rounded),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            Padding(
              // Inside the Chat tab, stay clear of the floating tab bar
              // unless the keyboard is up (the tab bar is behind it then).
              padding: EdgeInsets.fromLTRB(
                12,
                0,
                12,
                widget.embedded && View.of(context).viewInsets.bottom == 0
                    ? 100
                    : 12,
              ),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: isDark
                        ? AppColors.darkBorder
                        : AppColors.deepBlue.withValues(alpha: 0.08),
                  ),
                  boxShadow: AppShadows.card,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Semantics(
                      button: true,
                      label: 'Add a screenshot',
                      child: InkWell(
                        onTap: _isSending ? null : _pickScreenshots,
                        customBorder: const CircleBorder(),
                        child: CircleAvatar(
                          radius: 22,
                          backgroundColor: AppColors.teal.withValues(
                            alpha: 0.12,
                          ),
                          child: const Icon(
                            Icons.add_rounded,
                            color: AppColors.teal,
                          ),
                        ),
                      ),
                    ),
                    const Gap(8),
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        minLines: 1,
                        maxLines: 5,
                        style: theme.textTheme.bodyMedium,
                        decoration: InputDecoration(
                          hintText: 'Message Gideon',
                          hintStyle: theme.textTheme.bodyMedium?.copyWith(
                            color: muted,
                          ),
                          filled: false,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                    const Gap(8),
                    Semantics(
                      button: true,
                      label: 'Send',
                      child: InkWell(
                        onTap: _isSending ? null : _submit,
                        customBorder: const CircleBorder(),
                        child: CircleAvatar(
                          radius: 22,
                          backgroundColor: AppColors.teal.withValues(
                            alpha: _isSending ? 0.6 : 1,
                          ),
                          child: const Icon(
                            Icons.send_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );

    if (widget.embedded) return content;
    return AppScreen(
      resizeToAvoidBottomInset: true,
      body: SafeArea(bottom: false, child: content),
    );
  }

  Future<void> _pickScreenshots() async {
    final room = 3 - _picked.length;
    if (room <= 0) {
      showAppSnackBar(context, 'You can send up to 3 screenshots at a time.');
      return;
    }
    try {
      final files = await ImagePicker().pickMultiImage(
        imageQuality: 85,
        maxWidth: 2000,
      );
      if (!mounted || files.isEmpty) return;
      setState(() => _picked.addAll(files.take(room)));
      if (files.length > room) {
        showAppSnackBar(context, 'Only the first 3 screenshots were added.');
      }
    } catch (_) {
      if (mounted) showAppSnackBar(context, 'Could not open your photos.');
    }
  }

  CohortSessionModel? _resolveSession(StudentDashboardSnapshot dashboard) {
    if (widget.sessionId == null) {
      return null;
    }

    for (final item in dashboard.unlockedSessions) {
      if (item.id == widget.sessionId) return item;
    }
    return null;
  }

  Future<void> _submit() async {
    final message = _controller.text.trim();
    if ((message.isEmpty && _picked.isEmpty) || _isSending) return;
    final picked = List<XFile>.of(_picked);
    final clientMessageId =
        'client-${DateTime.now().microsecondsSinceEpoch}-$_conversationSessionId';

    final StudentDashboardSnapshot dashboard;
    try {
      dashboard = await ref.read(dashboardSnapshotProvider.future);
    } catch (_) {
      if (!mounted) return;
      showAppSnackBar(
        context,
        'We are still preparing your learning details. Please wait a moment and try again.',
      );
      return;
    }

    final session = _resolveSession(dashboard);
    if (session == null && widget.sessionId != null) {
      if (!mounted) return;
      showAppSnackBar(
        context,
        'This mentor conversation is still getting ready. Please wait a moment and try again.',
      );
      return;
    }

    final optimistic = MentorChatMessage(
      id: 'optimistic-${DateTime.now().microsecondsSinceEpoch}',
      conversationId: '',
      sessionId: session?.id ?? _conversationSessionId,
      // Same text the server stores for a screenshot-only message, so the
      // sent copy replaces this one.
      body: message.isEmpty ? 'Sent a screenshot' : message,
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
      _picked.clear();
    });
    unawaited(_persistOptimisticMessages());

    try {
      final repository = ref.read(mentorRequestRepositoryProvider);
      final uid = ref.read(authControllerProvider).session?.uid ?? '';
      final attachments = <Map<String, Object>>[
        for (final file in picked)
          await repository.uploadScreenshot(uid: uid, filePath: file.path),
      ];
      final conversationId = await repository.submitRequest(
        dashboard: dashboard,
        session: session,
        fallbackSessionId: _conversationSessionId,
        message: message,
        contextType: widget.contextType,
        clientMessageId: clientMessageId,
        attachments: attachments,
      );
      if (conversationId.isNotEmpty) {
        ref
                .read(
                  mentorConversationIdOverrideProvider(
                    _conversationSessionId,
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
            sessionId: _conversationSessionId,
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
        _picked
          ..clear()
          ..addAll(picked);
        _controller.text = message;
        _controller.selection = TextSelection.collapsed(
          offset: _controller.text.length,
        );
      });
      unawaited(_persistOptimisticMessages());
      showAppSnackBar(
        context,
        error is StateError
            ? error.message
            : 'Message not sent. Please try again.',
      );
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
      sessionId: _conversationSessionId,
    );
    final merged = mergeChatTimeline(cached, _optimisticMessages);
    await repository.saveCachedConversation(
      studentUid: session.uid,
      sessionId: _conversationSessionId,
      messages: merged,
    );
  }

  void _markVisibleMentorRepliesRead(List<MentorChatMessage> messages) {
    final replies = messages
        .where(
          (item) =>
              item.isAdmin && !_locallyReadMentorReplyIds.contains(item.id),
        )
        .toList();
    if (replies.isEmpty) return;
    _locallyReadMentorReplyIds.addAll(replies.map((item) => item.id));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(markMentorRepliesRead(replies));
      ref.invalidate(unreadMessagesCountProvider);
    });
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
  Set<String> _readMentorReplyIds = <String>{};
  Set<String> _hiddenMentorReplyIds = <String>{};
  bool _notificationPrefsReady = false;

  @override
  void initState() {
    super.initState();
    _loadNotificationPrefs();
  }

  Future<void> _loadNotificationPrefs() async {
    final readIds = await loadReadNotificationIds();
    final hiddenIds = await loadHiddenNotificationIds();
    final readMentorReplyIds = await loadReadMentorReplyIds();
    final hiddenMentorReplyIds = await loadHiddenMentorReplyIds();
    if (!mounted) return;
    setState(() {
      _readIds = readIds;
      _hiddenIds = hiddenIds;
      _readMentorReplyIds = readMentorReplyIds;
      _hiddenMentorReplyIds = hiddenMentorReplyIds;
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

  Future<void> _openMentorReply(MentorChatMessage item) async {
    await markMentorRepliesRead([item]);
    if (!mounted) return;
    setState(() {
      _readMentorReplyIds = {..._readMentorReplyIds, item.id};
    });
    ref.invalidate(unreadMessagesCountProvider);
    context.push('/mentor');
  }

  Future<void> _markAllAsRead(
    List<CohortMessageModel> messages,
    List<MentorChatMessage> mentorReplies,
  ) async {
    if (messages.isEmpty && mentorReplies.isEmpty) return;
    await markNotificationsRead(messages);
    await markMentorRepliesRead(mentorReplies);
    if (!mounted) return;
    setState(() {
      _readIds = {..._readIds, ...messages.map((item) => item.id)};
      _readMentorReplyIds = {
        ..._readMentorReplyIds,
        ...mentorReplies.map((item) => item.id),
      };
    });
    ref.invalidate(unreadMessagesCountProvider);
  }

  Future<void> _clearAllNotifications(
    List<CohortMessageModel> messages,
    List<MentorChatMessage> mentorReplies,
  ) async {
    if (messages.isEmpty && mentorReplies.isEmpty) return;
    await clearNotifications(messages);
    await clearMentorReplyNotifications(mentorReplies);
    if (!mounted) return;
    setState(() {
      _hiddenIds = {..._hiddenIds, ...messages.map((item) => item.id)};
      _readIds = {..._readIds, ...messages.map((item) => item.id)};
      _hiddenMentorReplyIds = {
        ..._hiddenMentorReplyIds,
        ...mentorReplies.map((item) => item.id),
      };
      _readMentorReplyIds = {
        ..._readMentorReplyIds,
        ...mentorReplies.map((item) => item.id),
      };
    });
    ref.invalidate(unreadMessagesCountProvider);
  }

  @override
  Widget build(BuildContext context) {
    final cohortMessages = ref.watch(cohortMessagesProvider);
    final mentorMessages = ref.watch(
      mentorRequestsProvider(
        const MentorConversationQuery(sessionId: null, conversationId: null),
      ),
    );
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
        final visibleMentorReplies =
            mentorMessages
                .maybeWhen(
                  data: (items) => items,
                  orElse: () => const <MentorChatMessage>[],
                )
                .where(
                  (item) =>
                      item.isAdmin && !_hiddenMentorReplyIds.contains(item.id),
                )
                .toList()
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        final unreadCohortCount = visibleMessages
            .where((item) => !_readIds.contains(item.id))
            .length;
        final unreadMentorCount = visibleMentorReplies
            .where((item) => !_readMentorReplyIds.contains(item.id))
            .length;
        final unreadCount = unreadCohortCount + unreadMentorCount;
        final hasNotifications =
            visibleMessages.isNotEmpty || visibleMentorReplies.isNotEmpty;

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
                            'Mentor replies, announcements, and action items from your cohort team.',
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
                      : !hasNotifications
                      ? AppEmptyState(
                          title: 'No notifications left',
                          message:
                              messages.isEmpty && visibleMentorReplies.isEmpty
                              ? 'Mentor replies and cohort updates will appear here.'
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
                                    onPressed: () => _markAllAsRead(
                                      visibleMessages,
                                      visibleMentorReplies,
                                    ),
                                  ),
                                ),
                                const Gap(10),
                                Expanded(
                                  child: AppButton(
                                    label: 'Clear',
                                    expanded: false,
                                    variant: AppButtonVariant.ghost,
                                    onPressed: () => _clearAllNotifications(
                                      visibleMessages,
                                      visibleMentorReplies,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const Gap(16),
                            if (visibleMentorReplies.isNotEmpty) ...[
                              _NotificationSectionLabel(
                                label: 'Mentor chat',
                                count: visibleMentorReplies.length,
                              ),
                              const Gap(10),
                              ...List.generate(visibleMentorReplies.length, (
                                index,
                              ) {
                                final item = visibleMentorReplies[index];
                                final isUnread = !_readMentorReplyIds.contains(
                                  item.id,
                                );
                                return _MentorReplyNotificationCard(
                                  item: item,
                                  isUnread: isUnread,
                                  onTap: () => _openMentorReply(item),
                                );
                              }),
                              const Gap(6),
                            ],
                            if (visibleMessages.isNotEmpty) ...[
                              _NotificationSectionLabel(
                                label: 'Cohort updates',
                                count: visibleMessages.length,
                              ),
                              const Gap(10),
                            ],
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

class _NotificationSectionLabel extends StatelessWidget {
  const _NotificationSectionLabel({required this.label, required this.count});

  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: AppColors.deepBlue,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.2,
          ),
        ),
        const Gap(8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.teal.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            '$count',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.tealDark,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _MentorReplyNotificationCard extends StatelessWidget {
  const _MentorReplyNotificationCard({
    required this.item,
    required this.isUnread,
    required this.onTap,
  });

  final MentorChatMessage item;
  final bool isUnread;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(28),
          child: AppCard(
            radius: 28,
            color: isUnread ? AppColors.teal.withValues(alpha: 0.05) : null,
            border: Border.all(
              color: isUnread
                  ? AppColors.teal.withValues(alpha: 0.28)
                  : AppColors.deepBlue.withValues(alpha: 0.06),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: AppGradients.accent,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        isUnread
                            ? Icons.mark_chat_unread_rounded
                            : Icons.forum_rounded,
                        color: Colors.white,
                      ),
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
                                  'Mentor replied',
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w800),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: isUnread
                                      ? AppColors.orange.withValues(alpha: 0.14)
                                      : AppColors.teal.withValues(alpha: 0.14),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  isUnread ? 'New' : 'Read',
                                  style: Theme.of(context).textTheme.labelSmall
                                      ?.copyWith(
                                        color: isUnread
                                            ? AppColors.orange
                                            : AppColors.teal,
                                        fontWeight: FontWeight.w800,
                                      ),
                                ),
                              ),
                            ],
                          ),
                          const Gap(6),
                          Text(
                            item.body,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: AppColors.mutedForeground,
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
                    const Icon(
                      Icons.schedule_rounded,
                      size: 16,
                      color: AppColors.mutedForeground,
                    ),
                    const Gap(6),
                    Text(
                      _formatMentorMessageTime(item.createdAt),
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppColors.mutedForeground,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Open chat',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppColors.teal,
                        fontWeight: FontWeight.w700,
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
  }
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
          'Send your question when you are ready. Mentor replies will appear here in this conversation.',
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
            'Ask about the class, your code, or what to do next. We will keep the thread here for follow-up.',
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
        ? (isDark ? AppColors.tealDark : AppColors.teal)
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
                for (final url in message.imageUrls) ...[
                  GestureDetector(
                    onTap: () => _showScreenshot(context, url),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.network(
                        url,
                        height: 180,
                        fit: BoxFit.cover,
                        semanticLabel: 'Screenshot',
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.broken_image_outlined),
                      ),
                    ),
                  ),
                  const Gap(8),
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

/// Full-screen, zoomable view of a chat screenshot.
void _showScreenshot(BuildContext context, String url) {
  showDialog<void>(
    context: context,
    builder: (context) => Dialog.fullscreen(
      backgroundColor: Colors.black,
      child: Stack(
        children: [
          Positioned.fill(
            child: InteractiveViewer(
              maxScale: 5,
              child: Center(child: Image.network(url)),
            ),
          ),
          SafeArea(
            child: IconButton(
              tooltip: 'Close',
              color: Colors.white,
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close_rounded),
            ),
          ),
        ],
      ),
    ),
  );
}
