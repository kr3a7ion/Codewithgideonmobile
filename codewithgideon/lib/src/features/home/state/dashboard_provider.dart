import 'package:flutter_riverpod/flutter_riverpod.dart'
    show FutureProvider, Provider;

import '../../catalog/data/catalog_repository.dart';
import '../../cohorts/data/cohort_repository.dart';
import '../../entry/state/auth_provider.dart'
    show
        authControllerProvider,
        apiClientProvider,
        firebaseFirestoreProvider,
        sharedPreferencesProvider;
import '../../student/data/student_repository.dart';
import '../data/dashboard_repository.dart';
import '../models/student_dashboard_snapshot.dart';
import '../../../core/services/notification_service.dart';

final catalogRepositoryProvider = Provider<CatalogRepository>((ref) {
  return CatalogRepository(
    apiClient: ref.watch(apiClientProvider),
    firebaseFirestore: ref.watch(firebaseFirestoreProvider),
  );
});

final cohortRepositoryProvider = Provider<CohortRepository>((ref) {
  return CohortRepository(
    apiClient: ref.watch(apiClientProvider),
    firebaseFirestore: ref.watch(firebaseFirestoreProvider),
  );
});

final studentRepositoryProvider = Provider<StudentRepository>((ref) {
  return StudentRepository(
    apiClient: ref.watch(apiClientProvider),
    firebaseFirestore: ref.watch(firebaseFirestoreProvider),
  );
});

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepository(
    apiClient: ref.watch(apiClientProvider),
    catalogRepository: ref.watch(catalogRepositoryProvider),
    cohortRepository: ref.watch(cohortRepositoryProvider),
    studentRepository: ref.watch(studentRepositoryProvider),
  );
});

final dashboardSnapshotProvider = FutureProvider<StudentDashboardSnapshot>((
  ref,
) async {
  final authState = ref.watch(authControllerProvider);
  final session = authState.session;
  if (session == null) {
    throw StateError('A signed-in student session is required.');
  }
  final repository = ref.watch(dashboardRepositoryProvider);
  return repository.fetchDashboard(uid: session.uid, email: session.email);
});

// Provider to handle notifications based on dashboard state
final dashboardNotificationsProvider = FutureProvider<void>((ref) async {
  final snapshot = await ref.watch(dashboardSnapshotProvider.future);

  // Check for live class
  final liveSession = snapshot.liveSession;
  if (liveSession != null) {
    // Check if we already notified for this session
    final prefs = await ref.watch(sharedPreferencesProvider.future);
    final notifiedKey = 'notified_live_${liveSession.id}';
    final alreadyNotified = prefs.getBool(notifiedKey) ?? false;
    if (!alreadyNotified) {
      await NotificationService().showLiveClassNotification();
      await prefs.setBool(notifiedKey, true);
    }
  }

  // Check for recording ready
  final recordedSessions = snapshot.recordedSessions;
  for (final session in recordedSessions) {
    final prefs = await ref.watch(sharedPreferencesProvider.future);
    final notifiedKey = 'notified_recording_${session.id}';
    final alreadyNotified = prefs.getBool(notifiedKey) ?? false;
    if (!alreadyNotified) {
      await NotificationService().showRecordingReadyNotification();
      await prefs.setBool(notifiedKey, true);
    }
  }
});
