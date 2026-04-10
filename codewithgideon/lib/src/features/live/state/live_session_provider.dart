import 'package:flutter_riverpod/legacy.dart';

import '../../../core/data/demo_data.dart';

class LiveSessionState {
  const LiveSessionState({
    required this.isMuted,
    required this.showChat,
    required this.showHandDialog,
    required this.showNotes,
    required this.showLeaveDialog,
    required this.chatMessages,
    required this.notes,
    required this.messageDraft,
  });

  final bool isMuted;
  final bool showChat;
  final bool showHandDialog;
  final bool showNotes;
  final bool showLeaveDialog;
  final List<CommunityMessage> chatMessages;
  final String notes;
  final String messageDraft;

  LiveSessionState copyWith({
    bool? isMuted,
    bool? showChat,
    bool? showHandDialog,
    bool? showNotes,
    bool? showLeaveDialog,
    List<CommunityMessage>? chatMessages,
    String? notes,
    String? messageDraft,
  }) {
    return LiveSessionState(
      isMuted: isMuted ?? this.isMuted,
      showChat: showChat ?? this.showChat,
      showHandDialog: showHandDialog ?? this.showHandDialog,
      showNotes: showNotes ?? this.showNotes,
      showLeaveDialog: showLeaveDialog ?? this.showLeaveDialog,
      chatMessages: chatMessages ?? this.chatMessages,
      notes: notes ?? this.notes,
      messageDraft: messageDraft ?? this.messageDraft,
    );
  }
}

class LiveSessionController extends StateNotifier<LiveSessionState> {
  LiveSessionController()
    : super(
        const LiveSessionState(
          isMuted: false,
          showChat: false,
          showHandDialog: false,
          showNotes: false,
          showLeaveDialog: false,
          chatMessages: DemoData.liveChatMessages,
          notes: '',
          messageDraft: '',
        ),
      );

  void toggleMute() => state = state.copyWith(isMuted: !state.isMuted);
  void toggleChat() => state = state.copyWith(showChat: !state.showChat);
  void setShowHand(bool value) => state = state.copyWith(showHandDialog: value);
  void setShowNotes(bool value) => state = state.copyWith(showNotes: value);
  void setShowLeave(bool value) =>
      state = state.copyWith(showLeaveDialog: value);
  void updateNotes(String value) => state = state.copyWith(notes: value);
  void updateMessageDraft(String value) =>
      state = state.copyWith(messageDraft: value);

  void sendMessage() {
    if (state.messageDraft.trim().isEmpty) return;
    state = state.copyWith(
      chatMessages: [
        ...state.chatMessages,
        CommunityMessage(
          id: '${state.chatMessages.length + 1}',
          user: 'You',
          avatar: 'ME',
          message: state.messageDraft.trim(),
          time: _timestamp(),
          isUser: true,
        ),
      ],
      messageDraft: '',
    );
  }

}

final liveSessionProvider =
    StateNotifierProvider.family<
      LiveSessionController,
      LiveSessionState,
      String
    >((ref, sessionId) {
      return LiveSessionController();
    });

String _timestamp() {
  final now = DateTime.now();
  final hour = now.hour > 12
      ? now.hour - 12
      : now.hour == 0
      ? 12
      : now.hour;
  final minute = now.minute.toString().padLeft(2, '0');
  final period = now.hour >= 12 ? 'PM' : 'AM';
  return '$hour:$minute $period';
}
