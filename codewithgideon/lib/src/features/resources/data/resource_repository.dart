import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/data/demo_data.dart';
import '../../../core/network/api_client.dart';
import '../../cohorts/models/cohort_session_model.dart';
import '../../student/models/student_profile_model.dart';

class ResourceRepository {
  ResourceRepository({
    required ApiClient apiClient,
    required FirebaseFirestore firebaseFirestore,
  }) : _apiClient = apiClient,
       _firebaseFirestore = firebaseFirestore;

  final ApiClient _apiClient;
  final FirebaseFirestore _firebaseFirestore;

  Future<List<CourseResource>> getPublishedResourcesForStudent({
    required StudentProfileModel profile,
    String? resolvedCourseId,
  }) {
    return _apiClient.simulateRequest(() async {
      final snapshot = await _firebaseFirestore
          .collection('resources')
          .orderBy('updatedAt', descending: true)
          .get();

      final effectiveCourseId = (resolvedCourseId ?? profile.courseId).trim();

      return snapshot.docs
          .map((doc) => _mapResource(doc))
          .where((resource) => resource.isPublished)
          .where(
            (resource) =>
                _matchesScope(resource.pathId, profile.pathId) &&
                _matchesScope(resource.courseId, effectiveCourseId),
          )
          .toList();
    }, latency: const Duration(milliseconds: 400));
  }

  List<CourseResource> resourcesForSession({
    required List<CourseResource> resources,
    required CohortSessionModel session,
    required String pathId,
    required String courseId,
  }) {
    // A week can contain multiple classes, so only an explicit sessionId
    // should attach a resource directly to a class screen.
    return resources.where((resource) {
      final scopeMatches =
          _matchesScope(resource.pathId, pathId) &&
          _matchesScope(resource.courseId, courseId);
      final sessionMatches = resource.sessionId == session.id;
      return scopeMatches && sessionMatches;
    }).toList();
  }

  CourseResource _mapResource(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final updatedAt = _parseDate(data['updatedAt']) ?? DateTime.now();

    return CourseResource(
      name: (data['name'] as String?)?.trim() ?? 'Untitled Resource',
      type: (data['type'] as String?)?.trim() ?? 'PDF',
      size: (data['size'] as String?)?.trim() ?? '',
      date: _formatUpdatedLabel(updatedAt),
      folder: (data['folder'] as String?)?.trim() ?? 'General',
      url: (data['url'] as String?)?.trim() ?? '',
      description: (data['description'] as String?)?.trim() ?? '',
      pathId: (data['pathId'] as String?)?.trim() ?? '',
      courseId: (data['courseId'] as String?)?.trim() ?? '',
      sessionId: (data['sessionId'] as String?)?.trim() ?? '',
      sessionWeek: (data['sessionWeek'] as num?)?.toInt(),
      isPublished: (data['isPublished'] as bool?) ?? true,
      updatedAt: updatedAt,
    );
  }
}

bool _matchesScope(String scopeValue, String expected) {
  final normalizedScope = scopeValue.trim();
  if (normalizedScope.isEmpty) return true;
  return normalizedScope == expected.trim();
}

DateTime? _parseDate(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is num) return DateTime.fromMillisecondsSinceEpoch(value.toInt());
  if (value is String) return DateTime.tryParse(value);
  return null;
}

String _formatUpdatedLabel(DateTime updatedAt) {
  const months = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return 'Updated ${months[updatedAt.month - 1]} ${updatedAt.day}';
}
