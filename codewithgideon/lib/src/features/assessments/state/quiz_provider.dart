import 'package:flutter_riverpod/legacy.dart';

class QuizState {
  const QuizState({required this.answers, required this.remaining});

  final Map<int, int> answers;
  final Duration remaining;

  QuizState copyWith({Map<int, int>? answers, Duration? remaining}) {
    return QuizState(
      answers: answers ?? this.answers,
      remaining: remaining ?? this.remaining,
    );
  }
}

class QuizController extends StateNotifier<QuizState> {
  QuizController()
    : super(
        const QuizState(
          answers: {},
          remaining: Duration(minutes: 14, seconds: 35),
        ),
      );

  void selectAnswer(int questionNumber, int answerIndex) {
    state = state.copyWith(
      answers: {...state.answers, questionNumber: answerIndex},
    );
  }

  void reset() {
    state = const QuizState(
      answers: {},
      remaining: Duration(minutes: 14, seconds: 35),
    );
  }
}

final quizProvider =
    StateNotifierProvider.family<QuizController, QuizState, String>((
      ref,
      quizId,
    ) {
      return QuizController();
    });
