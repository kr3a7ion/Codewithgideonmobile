class CohortSessionModel {
  const CohortSessionModel({
    required this.id,
    required this.cohortKey,
    required this.week,
    required this.pathId,
    required this.pathTitle,
    required this.title,
    required this.startsAt,
    required this.endsAt,
    required this.joinUrl,
    required this.recordingUrl,
    required this.notes,
    required this.isPublished,
  });

  final String id;
  final String cohortKey;
  final int week;
  final String pathId;
  final String pathTitle;
  final String title;
  final DateTime startsAt;
  final DateTime endsAt;
  final String joinUrl;
  final String recordingUrl;
  final String notes;
  final bool isPublished;

  bool get hasJoinUrl => joinUrl.trim().isNotEmpty;
  bool get hasRecordingUrl => recordingUrl.trim().isNotEmpty;
}
