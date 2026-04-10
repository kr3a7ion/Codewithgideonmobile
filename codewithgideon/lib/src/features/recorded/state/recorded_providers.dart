import 'package:flutter_riverpod/legacy.dart';

import '../../../core/data/demo_data.dart';

class RecordedPlayerState {
  const RecordedPlayerState({
    required this.isPlaying,
    required this.progress,
    required this.showCompleteModal,
  });

  final bool isPlaying;
  final double progress;
  final bool showCompleteModal;

  RecordedPlayerState copyWith({
    bool? isPlaying,
    double? progress,
    bool? showCompleteModal,
  }) {
    return RecordedPlayerState(
      isPlaying: isPlaying ?? this.isPlaying,
      progress: progress ?? this.progress,
      showCompleteModal: showCompleteModal ?? this.showCompleteModal,
    );
  }
}

class RecordedPlayerController extends StateNotifier<RecordedPlayerState> {
  RecordedPlayerController(String lessonId)
    : super(
        RecordedPlayerState(
          isPlaying: false,
          progress: DemoData.recordedLesson(lessonId).completed / 100,
          showCompleteModal: false,
        ),
      );

  void togglePlayback() {
    state = state.copyWith(isPlaying: !state.isPlaying);
  }

  void markComplete() {
    state = state.copyWith(progress: 1, showCompleteModal: true);
  }

  void dismissModal() {
    state = state.copyWith(showCompleteModal: false);
  }
}

final recordedPlayerProvider =
    StateNotifierProvider.family<
      RecordedPlayerController,
      RecordedPlayerState,
      String
    >((ref, lessonId) {
      return RecordedPlayerController(lessonId);
    });

class TutorChatState {
  const TutorChatState({required this.messages, required this.isTyping});

  final List<TutorMessage> messages;
  final bool isTyping;

  TutorChatState copyWith({List<TutorMessage>? messages, bool? isTyping}) {
    return TutorChatState(
      messages: messages ?? this.messages,
      isTyping: isTyping ?? this.isTyping,
    );
  }
}

class TutorChatController extends StateNotifier<TutorChatState> {
  TutorChatController()
    : super(
        const TutorChatState(
          messages: DemoData.tutorSeedMessages,
          isTyping: false,
        ),
      );

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final updated = [
      ...state.messages,
      TutorMessage(
        id: '${state.messages.length + 1}',
        text: text.trim(),
        time: _timestamp(),
        isUser: true,
      ),
    ];
    state = state.copyWith(messages: updated, isTyping: true);
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    state = state.copyWith(
      isTyping: false,
      messages: [
        ...updated,
        TutorMessage(
          id: '${updated.length + 1}',
          text:
              "That's a great question. Arrow functions give you a shorter function syntax and a lexical this binding, which makes callbacks and component logic easier to reason about.",
          time: _timestamp(),
          isUser: false,
        ),
      ],
    );
  }
}

final aiTutorChatProvider =
    StateNotifierProvider.family<TutorChatController, TutorChatState, String>((
      ref,
      lessonId,
    ) {
      return TutorChatController();
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
