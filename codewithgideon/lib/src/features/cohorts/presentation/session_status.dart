import 'package:intl/intl.dart';

import '../models/cohort_session_model.dart';

enum SessionActionState {
  joinLive,
  startsSoon,
  watchRecording,
  awaitingRecording,
  awaitingJoinLink,
}

class SessionStatusSnapshot {
  const SessionStatusSnapshot({
    required this.actionState,
    required this.statusLabel,
    required this.countdownLabel,
    required this.scheduleLabel,
  });

  final SessionActionState actionState;
  final String statusLabel;
  final String? countdownLabel;
  final String scheduleLabel;

  bool get isJoinEnabled => actionState == SessionActionState.joinLive;
  bool get isRecordingReady => actionState == SessionActionState.watchRecording;
  bool get isUpcoming => actionState == SessionActionState.startsSoon;
}

SessionStatusSnapshot resolveSessionStatus(
  CohortSessionModel session, {
  DateTime? now,
}) {
  final referenceTime = now ?? DateTime.now();
  final scheduleLabel =
      '${DateFormat('EEE, MMM d').format(session.startsAt)} • ${DateFormat('h:mm a').format(session.startsAt)} - ${DateFormat('h:mm a').format(session.endsAt)}';
  final countdownLabel = session.startsAt.isAfter(referenceTime)
      ? _countdownLabel(session.startsAt, referenceTime)
      : null;

  // Keep the rules in one place so dashboard hero, classes, and player flows
  // all react to the same Firebase session timing.
  if (_isSessionLive(session, referenceTime) && session.hasJoinUrl) {
    return SessionStatusSnapshot(
      actionState: SessionActionState.joinLive,
      statusLabel: 'Live now',
      countdownLabel: null,
      scheduleLabel: scheduleLabel,
    );
  }

  if (!session.startsAt.isAfter(referenceTime) && session.hasRecordingUrl) {
    return SessionStatusSnapshot(
      actionState: SessionActionState.watchRecording,
      statusLabel: 'Recording ready',
      countdownLabel: null,
      scheduleLabel: scheduleLabel,
    );
  }

  if (session.startsAt.isAfter(referenceTime) && session.hasJoinUrl) {
    return SessionStatusSnapshot(
      actionState: SessionActionState.startsSoon,
      statusLabel: countdownLabel ?? 'Class starts soon',
      countdownLabel: countdownLabel,
      scheduleLabel: scheduleLabel,
    );
  }

  if (session.endsAt.isBefore(referenceTime)) {
    return SessionStatusSnapshot(
      actionState: SessionActionState.awaitingRecording,
      statusLabel: 'Awaiting recording',
      countdownLabel: null,
      scheduleLabel: scheduleLabel,
    );
  }

  return SessionStatusSnapshot(
    actionState: SessionActionState.awaitingJoinLink,
    statusLabel: countdownLabel ?? 'Awaiting join link',
    countdownLabel: countdownLabel,
    scheduleLabel: scheduleLabel,
  );
}

bool isSessionLive(CohortSessionModel session, {DateTime? now}) {
  return _isSessionLive(session, now ?? DateTime.now());
}

String buildClassStartEstimate(CohortSessionModel session, {DateTime? now}) {
  final referenceTime = now ?? DateTime.now();
  final status = resolveSessionStatus(session, now: referenceTime);
  if (status.countdownLabel != null) {
    return '${status.countdownLabel} • ${status.scheduleLabel}';
  }
  return status.scheduleLabel;
}

String _countdownLabel(DateTime startsAt, DateTime now) {
  final difference = startsAt.difference(now);
  final minutes = difference.inMinutes;
  if (minutes <= 0) return 'Starting now';
  if (minutes < 60) return 'Starting in $minutes min';
  final hours = minutes ~/ 60;
  final remainingMinutes = minutes % 60;
  if (remainingMinutes == 0) return 'Starting in ${hours}h';
  return 'Starting in ${hours}h ${remainingMinutes}m';
}

bool _isSessionLive(CohortSessionModel session, DateTime now) {
  return !session.startsAt.isAfter(now) && !session.endsAt.isBefore(now);
}
