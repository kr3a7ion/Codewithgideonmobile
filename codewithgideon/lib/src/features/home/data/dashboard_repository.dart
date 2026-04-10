import '../../../core/network/api_client.dart';
import '../../../core/data/demo_data.dart';
import '../../catalog/data/catalog_repository.dart';
import '../../cohorts/data/cohort_repository.dart';
import '../../cohorts/models/cohort_session_model.dart';
import '../../student/data/student_repository.dart';
import '../models/student_dashboard_snapshot.dart';

class DashboardRepository {
  DashboardRepository({
    required ApiClient apiClient,
    required CatalogRepository catalogRepository,
    required CohortRepository cohortRepository,
    required StudentRepository studentRepository,
  }) : _apiClient = apiClient,
       _catalogRepository = catalogRepository,
       _cohortRepository = cohortRepository,
       _studentRepository = studentRepository;

  final ApiClient _apiClient;
  final CatalogRepository _catalogRepository;
  final CohortRepository _cohortRepository;
  final StudentRepository _studentRepository;

  Future<StudentDashboardSnapshot> fetchDashboard({
    required String uid,
    required String email,
  }) {
    return _apiClient.simulateRequest(() async {
      final profile = await _studentRepository.getStudentProfileByUid(uid);
      if (profile == null) {
        throw StateError(
          'Student profile for uid "$uid" was not found in Firestore.',
        );
      }
      final path = await _catalogRepository.getPath(profile.pathId);
      final course = await _catalogRepository.getCourseForPath(
        profile.pathId,
        courseId: profile.courseId,
      );
      final activeCohort = await _cohortRepository.getActiveCohortForPath(
        profile.pathId,
      );
      final allCohortSessions = await _cohortRepository.getSessionsForCohort(
        profile.cohortKey ?? activeCohort.cohortKey,
      );

      final unlockedSessions =
          profile.isPending || profile.hasPendingInitialPayment
                ? <CohortSessionModel>[]
                : allCohortSessions
                      .where((session) => session.isPublished)
                      .where((session) => session.pathId == profile.pathId)
                      .where((session) => session.week <= profile.weeksToCommit)
                      .toList()
            ..sort((a, b) => a.startsAt.compareTo(b.startsAt));

      // Mirror the source-of-truth session list into a recordings shelf when
      // Firebase has already attached a YouTube or hosted recording URL.
      final recordedLessons =
          unlockedSessions
              .where((session) => session.hasRecordingUrl)
              .map(
                (session) => RecordedLesson(
                  id: session.id,
                  title: session.title,
                  instructor: activeCohort.label,
                  duration: _sessionDurationLabel(session),
                  watched: 'Ready to watch',
                  completed: 0,
                  description: session.notes.isEmpty
                      ? 'Recorded session from your live cohort class.'
                      : session.notes,
                  resources: const [],
                ),
              )
              .toList()
            ..sort((a, b) => b.id.compareTo(a.id));

      return StudentDashboardSnapshot(
        profile: profile,
        path: path,
        course: course,
        activeCohort: activeCohort,
        unlockedSessions: unlockedSessions,
        recordedLessons: recordedLessons,
      );
    }, latency: const Duration(milliseconds: 550));
  }
}

String _sessionDurationLabel(CohortSessionModel session) {
  final minutes = session.endsAt.difference(session.startsAt).inMinutes;
  if (minutes <= 0) return '60 min';
  if (minutes % 60 == 0) return '${minutes ~/ 60} hr';
  return '$minutes min';
}
