import 'package:codewithgideon/src/features/cohorts/models/cohort_session_model.dart';
import 'package:codewithgideon/src/features/cohorts/presentation/session_status.dart';
import 'package:codewithgideon/src/features/recorded/data/watch_progress_repository.dart';
import 'package:flutter_test/flutter_test.dart';

CohortSessionModel _session({
  required DateTime startsAt,
  bool timeTba = false,
  String joinUrl = '',
  String recordingUrl = '',
}) {
  return CohortSessionModel(
    id: 's1',
    cohortKey: 'FLUTTER-2026-09',
    week: 3,
    pathId: 'path_flutter',
    pathTitle: 'Flutter',
    title: 'State management',
    startsAt: startsAt,
    endsAt: startsAt.add(const Duration(hours: 1)),
    joinUrl: joinUrl,
    recordingUrl: recordingUrl,
    notes: '',
    isPublished: true,
    timeTba: timeTba,
  );
}

void main() {
  group('Time to be announced classes', () {
    final midday = DateTime(2026, 11, 4, 12);

    test('are never live or counting down, even at the stored midday', () {
      final session = _session(startsAt: midday, timeTba: true);
      final status = resolveSessionStatus(
        session,
        now: DateTime(2026, 11, 4, 12, 30),
      );
      expect(isSessionLive(session, now: DateTime(2026, 11, 4, 12, 30)), false);
      expect(status.countdownLabel, isNull);
      expect(status.scheduleLabel, contains('Time to be announced'));
    });

    test('can be joined all day when there is a link', () {
      final session = _session(
        startsAt: midday,
        timeTba: true,
        joinUrl: 'https://meet.example.com/x',
      );
      final morning = resolveSessionStatus(
        session,
        now: DateTime(2026, 11, 4, 8),
      );
      final evening = resolveSessionStatus(
        session,
        now: DateTime(2026, 11, 4, 21),
      );
      expect(morning.isJoinEnabled, true);
      expect(evening.isJoinEnabled, true);
    });

    test('show the recording once the day is over', () {
      final session = _session(
        startsAt: midday,
        timeTba: true,
        recordingUrl: 'https://youtu.be/abc',
      );
      final status = resolveSessionStatus(
        session,
        now: DateTime(2026, 11, 5, 9),
      );
      expect(status.isRecordingReady, true);
    });

    test('say "Time TBA" instead of a clock time in lists', () {
      final session = _session(startsAt: midday, timeTba: true);
      expect(formatSessionWhen(session), endsWith('Time TBA'));
      expect(formatSessionWhen(session), isNot(contains('12:00')));
    });
  });

  test('normal classes keep their clock time', () {
    final session = _session(startsAt: DateTime(2026, 11, 4, 19));
    expect(formatSessionWhen(session), contains('7:00 PM'));
    expect(isSessionLive(session, now: DateTime(2026, 11, 4, 19, 30)), true);
  });

  test('watch progress counts as watched at 90%, like the website', () {
    expect(watchedAt, 0.9);
    const halfway = WatchProgress(
      sessionId: 's1',
      position: 600,
      duration: 1200,
      completed: false,
    );
    expect(halfway.fraction, 0.5);
    const done = WatchProgress(
      sessionId: 's1',
      position: 0,
      duration: 0,
      completed: true,
    );
    expect(done.fraction, 1);
  });
}
