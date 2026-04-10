import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../core/state/app_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_controls.dart';
import '../../core/widgets/app_scaffold.dart';

class LiveSessionScreen extends ConsumerStatefulWidget {
  const LiveSessionScreen({super.key, required this.sessionId});

  final String sessionId;

  @override
  ConsumerState<LiveSessionScreen> createState() => _LiveSessionScreenState();
}

class _LiveSessionScreenState extends ConsumerState<LiveSessionScreen> {
  late final TextEditingController _messageController;
  late final TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _messageController = TextEditingController();
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _syncController(TextEditingController controller, String value) {
    if (controller.text == value) return;
    controller.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sessionId = widget.sessionId;
    final state = ref.watch(liveSessionProvider(sessionId));
    final controller = ref.read(liveSessionProvider(sessionId).notifier);
    _syncController(_messageController, state.messageDraft);
    _syncController(_notesController, state.notes);

    return AppScreen(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF111827), Color(0xFF1F2937)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: const BoxDecoration(
                              gradient: AppGradients.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.videocam_rounded,
                              color: Colors.white,
                              size: 44,
                            ),
                          ),
                          const Gap(20),
                          Text(
                            'React Hooks Deep Dive',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                          const Gap(6),
                          Text(
                            'Live Session in Progress',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                    SafeArea(
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(22, 30, 22, 18),
                        child: Column(
                          children: [
                            Wrap(
                              alignment: WrapAlignment.spaceBetween,
                              runSpacing: 10,
                              spacing: 10,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.35),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 10,
                                        height: 10,
                                        decoration: const BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const Gap(8),
                                      Text(
                                        '45:23',
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelLarge
                                            ?.copyWith(color: Colors.white),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.35),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: const BoxDecoration(
                                          color: Colors.green,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const Gap(8),
                                      Text(
                                        '24 participants',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(color: Colors.white),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 280),
                      curve: Curves.easeOutCubic,
                      top: 0,
                      bottom: 110,
                      right: state.showChat ? 0 : -430,
                      width: MediaQuery.of(context).size.width,
                      child: Material(
                        color: Colors.white,
                        child: Column(
                          children: [
                            Container(
                              decoration: const BoxDecoration(
                                gradient: AppGradients.primary,
                              ),
                              padding: const EdgeInsets.fromLTRB(
                                18,
                                54,
                                18,
                                18,
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    'Live Chat',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w800,
                                        ),
                                  ),
                                  const Spacer(),
                                  IconButton(
                                    onPressed: controller.toggleChat,
                                    icon: const Icon(
                                      Icons.close_rounded,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: ListView.builder(
                                padding: const EdgeInsets.all(18),
                                itemCount: state.chatMessages.length,
                                itemBuilder: (context, index) {
                                  final item = state.chatMessages[index];
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 14),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        CircleAvatar(
                                          radius: 18,
                                          backgroundColor: item.isMentor
                                              ? AppColors.orange
                                              : AppColors.deepBlueLight,
                                          child: Text(
                                            item.avatar,
                                            style: Theme.of(context)
                                                .textTheme
                                                .labelMedium
                                                ?.copyWith(color: Colors.white),
                                          ),
                                        ),
                                        const Gap(12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Text(
                                                    item.user,
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .labelLarge
                                                        ?.copyWith(
                                                          color: item.isMentor
                                                              ? AppColors.orange
                                                              : AppColors
                                                                    .foreground,
                                                          fontWeight:
                                                              FontWeight.w800,
                                                        ),
                                                  ),
                                                  if (item.isMentor) ...[
                                                    const Gap(8),
                                                    Container(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 8,
                                                            vertical: 4,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: AppColors.orange
                                                            .withValues(
                                                              alpha: 0.12,
                                                            ),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              999,
                                                            ),
                                                      ),
                                                      child: Text(
                                                        'Mentor',
                                                        style: Theme.of(context)
                                                            .textTheme
                                                            .labelSmall
                                                            ?.copyWith(
                                                              color: AppColors
                                                                  .orange,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w800,
                                                            ),
                                                      ),
                                                    ),
                                                  ],
                                                  const Gap(8),
                                                  Text(
                                                    item.time,
                                                    style: Theme.of(
                                                      context,
                                                    ).textTheme.bodySmall,
                                                  ),
                                                ],
                                              ),
                                              const Gap(4),
                                              Text(item.message),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                18,
                                12,
                                18,
                                18,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      onChanged: controller.updateMessageDraft,
                                      controller: _messageController,
                                      decoration: const InputDecoration(
                                        hintText: 'Type a message...',
                                      ),
                                    ),
                                  ),
                                  const Gap(10),
                                  InkWell(
                                    onTap: controller.sendMessage,
                                    borderRadius: BorderRadius.circular(18),
                                    child: Container(
                                      width: 52,
                                      height: 52,
                                      decoration: const BoxDecoration(
                                        color: AppColors.teal,
                                        borderRadius: BorderRadius.all(
                                          Radius.circular(18),
                                        ),
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
                    ),
                  ],
                ),
              ),
              Container(
                color: const Color(0xFF111827),
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 36),
                child: Column(
                  children: [
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _ActionTile(
                            icon: Icons.pan_tool_alt_rounded,
                            label: 'Raise Hand',
                            color: Colors.amber,
                            onTap: () => controller.setShowHand(true),
                          ),
                          const Gap(10),
                          _ActionTile(
                            icon: Icons.help_outline_rounded,
                            label: 'Ask Mentor',
                            color: AppColors.teal,
                            onTap: () =>
                                context.push('/ai-tutor/$sessionId?source=live'),
                          ),
                          const Gap(10),
                          _ActionTile(
                            icon: Icons.note_alt_outlined,
                            label: 'Notes',
                            color: Colors.lightBlueAccent,
                            onTap: () => controller.setShowNotes(true),
                          ),
                        ],
                      ),
                    ),
                    const Gap(18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _ControlButton(
                          icon: state.isMuted
                              ? Icons.mic_off_rounded
                              : Icons.mic_rounded,
                          color: state.isMuted
                              ? Colors.red
                              : const Color(0xFF1F2937),
                          onTap: controller.toggleMute,
                        ),
                        const Gap(18),
                        _ControlButton(
                          icon: Icons.chat_bubble_outline_rounded,
                          color: const Color(0xFF1F2937),
                          onTap: controller.toggleChat,
                          badge: true,
                        ),
                        const Gap(18),
                        _ControlButton(
                          icon: Icons.close_rounded,
                          color: Colors.red,
                          onTap: () => controller.setShowLeave(true),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (state.showHandDialog)
            _CenterDialog(
              icon: Icons.pan_tool_alt_rounded,
              iconColor: Colors.amber,
              title: 'Raise Your Hand',
              body: 'The instructor will be notified and may call on you.',
              onClose: () => controller.setShowHand(false),
              actions: [
                Expanded(
                  child: AppButton(
                    label: 'Cancel',
                    variant: AppButtonVariant.outline,
                    onPressed: () => controller.setShowHand(false),
                  ),
                ),
                const Gap(10),
                Expanded(
                  child: AppButton(
                    label: 'Confirm',
                    variant: AppButtonVariant.secondary,
                    onPressed: () {
                      controller.setShowHand(false);
                      showAppSnackBar(
                        context,
                        'Hand raised. Sarah will see your request.',
                      );
                    },
                  ),
                ),
              ],
            ),
          if (state.showNotes)
            Material(
              color: Colors.white,
              child: SafeArea(
                child: Column(
                  children: [
                    Container(
                      decoration: const BoxDecoration(
                        gradient: AppGradients.primary,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 16,
                      ),
                      child: Row(
                        children: [
                          Text(
                            'My Notes',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: () => controller.setShowNotes(false),
                            icon: const Icon(
                              Icons.expand_more_rounded,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: TextField(
                          controller: _notesController,
                          onChanged: controller.updateNotes,
                          maxLines: null,
                          expands: true,
                          decoration: const InputDecoration(
                            hintText: 'Take notes during the class...',
                            alignLabelWithHint: true,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (state.showLeaveDialog)
            _CenterDialog(
              icon: Icons.logout_rounded,
              iconColor: Colors.red,
              title: 'Leave Class?',
              body: 'Are you sure you want to leave this live session?',
              onClose: () => controller.setShowLeave(false),
              actions: [
                Expanded(
                  child: AppButton(
                    label: 'Cancel',
                    variant: AppButtonVariant.outline,
                    onPressed: () => controller.setShowLeave(false),
                  ),
                ),
                const Gap(10),
                Expanded(
                  child: AppButton(
                    label: 'Leave',
                    variant: AppButtonVariant.danger,
                    onPressed: () => context.go('/dashboard'),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF1F2937),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const Gap(8),
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  const _ControlButton({
    required this.icon,
    required this.color,
    required this.onTap,
    this.badge = false,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool badge;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
        ),
        if (badge)
          Positioned(
            right: 2,
            top: 2,
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: AppColors.teal,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF111827), width: 2),
              ),
            ),
          ),
      ],
    );
  }
}

class _CenterDialog extends StatelessWidget {
  const _CenterDialog({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.body,
    required this.actions,
    required this.onClose,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String body;
  final List<Widget> actions;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.72),
      child: InkWell(
        onTap: onClose,
        child: Center(
          child: InkWell(
            onTap: () {},
            child: Container(
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 74,
                    height: 74,
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: 0.14),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: iconColor, size: 34),
                  ),
                  const Gap(18),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Gap(10),
                  Text(
                    body,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.mutedForeground,
                      height: 1.6,
                    ),
                  ),
                  const Gap(20),
                  Row(children: actions),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
