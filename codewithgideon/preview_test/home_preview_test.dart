// Renders screens to PNG for a visual check in CI (not part of `flutter test`).
// Run: flutter test --update-goldens preview_test
import 'dart:io';

import 'package:codewithgideon/src/core/models/learning_models.dart';
import 'package:codewithgideon/src/core/theme/app_theme.dart';
import 'package:codewithgideon/src/features/catalog/models/course_model.dart';
import 'package:codewithgideon/src/features/catalog/models/path_model.dart';
import 'package:codewithgideon/src/features/cohorts/models/active_cohort_model.dart';
import 'package:codewithgideon/src/features/cohorts/models/cohort_session_model.dart';
import 'package:codewithgideon/src/features/classes/class_screens.dart';
import 'package:codewithgideon/src/features/home/dashboard_screen.dart';
import 'package:codewithgideon/src/features/home/models/student_dashboard_snapshot.dart';
import 'package:codewithgideon/src/features/home/state/dashboard_provider.dart';
import 'package:codewithgideon/src/features/student/models/student_profile_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

CohortSessionModel _session(int week, DateTime start, {bool recording = false}) {
  return CohortSessionModel(
    id: 's$week',
    cohortKey: 'FLUTTER-2026-09',
    week: week,
    pathId: 'flutter-mobile',
    pathTitle: 'Flutter & Mobile App Development',
    title: week == 3 ? 'State management with Riverpod' : 'Week $week class',
    startsAt: start,
    endsAt: start.add(const Duration(hours: 1, minutes: 30)),
    joinUrl: 'https://meet.example.com/x',
    recordingUrl: recording ? 'https://youtu.be/abc' : '',
    notes: '',
    isPublished: true,
  );
}

void main() {
  setUpAll(() async {
    final font = File('preview_test/fonts/Manrope.ttf');
    if (font.existsSync()) {
      final loader = FontLoader('Preview')
        ..addFont(Future.value(ByteData.sublistView(font.readAsBytesSync())));
      await loader.load();
    }
    final root = Platform.environment['FLUTTER_ROOT'] ?? '';
    final icons = File(
      '$root/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
    );
    if (icons.existsSync()) {
      final loader = FontLoader('MaterialIcons')
        ..addFont(Future.value(ByteData.sublistView(icons.readAsBytesSync())));
      await loader.load();
    }
  });

  Future<void> render(WidgetTester tester, Widget screen, String name) async {
    tester.view.physicalSize = const Size(390 * 2, 1500 * 2);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    final now = DateTime.now();
    final snapshot = StudentDashboardSnapshot(
      profile: StudentProfileModel(
        uid: 'u1',
        fullName: 'Ada Lovelace',
        email: 'ada@example.com',
        phone: '',
        ageRange: '18-24',
        gender: '',
        pathTitle: 'Flutter & Mobile App Development',
        pathId: 'flutter-mobile',
        courseId: 'c1',
        weeksToCommit: 5,
        status: StudentEnrollmentState.complete,
        joinedAt: DateTime(2026, 9, 1),
        cohortId: 'FLUTTER',
        cohortLabel: 'September 2026',
        cohortKey: 'FLUTTER-2026-09',
      ),
      path: const PathModel(
        id: 'flutter-mobile',
        title: 'Flutter & Mobile App Development',
        description: '',
      ),
      course: const CourseModel(
        id: 'c1',
        pathId: 'flutter-mobile',
        title: 'Flutter & Mobile App Development',
        durationWeeks: 12,
        pricePerWeek: 10000,
        priceLabel: 'N10,000 / week',
        isActive: true,
        syllabus: [],
      ),
      activeCohort: const ActiveCohortModel(
        pathId: 'flutter-mobile',
        pathTitle: 'Flutter & Mobile App Development',
        cohortId: 'FLUTTER',
        cohortKey: 'FLUTTER-2026-09',
        label: 'September 2026',
        seasonKey: '2026-09',
      ),
      unlockedSessions: [
        _session(1, now.subtract(const Duration(days: 14)), recording: true),
        _session(2, now.subtract(const Duration(days: 7)), recording: true),
        _session(3, now.subtract(const Duration(minutes: 20))),
        _session(4, now.add(const Duration(days: 7))),
      ],
      recordedLessons: const <RecordedLesson>[],
      libraryResources: const <CourseResource>[],
    );
    final theme = AppTheme.lightTheme;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dashboardSnapshotProvider.overrideWithValue(AsyncData(snapshot)),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: theme.copyWith(
            textTheme: theme.textTheme.apply(fontFamily: 'Preview'),
          ),
          home: screen,
        ),
      ),
    );
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('out/$name.png'),
    );
  }

  testWidgets('home', (t) => render(t, const DashboardScreen(), 'app-home'));
  testWidgets(
    'classes',
    (t) => render(t, const ClassListScreen(), 'app-classes'),
  );
}
