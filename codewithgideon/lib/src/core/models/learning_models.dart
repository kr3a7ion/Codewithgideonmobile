// Shared shapes for course resources and class recordings.

class CourseResource {
  const CourseResource({
    required this.name,
    required this.type,
    required this.size,
    this.date = '',
    this.folder = '',
    this.url = '',
    this.description = '',
    this.pathId = '',
    this.courseId = '',
    this.sessionId = '',
    this.sessionWeek,
    this.isPublished = true,
    this.updatedAt,
  });

  final String name;
  final String type;
  final String size;
  final String date;
  final String folder;
  final String url;
  final String description;
  final String pathId;
  final String courseId;
  final String sessionId;
  final int? sessionWeek;
  final bool isPublished;
  final DateTime? updatedAt;

  bool get hasExternalUrl => url.trim().isNotEmpty;
}

class RecordedLesson {
  const RecordedLesson({
    required this.id,
    required this.title,
    required this.instructor,
    required this.duration,
    required this.watched,
    required this.completed,
    required this.description,
    required this.resources,
  });

  final String id;
  final String title;
  final String instructor;
  final String duration;
  final String watched;
  final int completed;
  final String description;
  final List<CourseResource> resources;
}
