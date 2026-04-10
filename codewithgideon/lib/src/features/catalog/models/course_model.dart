class CourseModel {
  const CourseModel({
    required this.id,
    required this.pathId,
    required this.title,
    required this.durationWeeks,
    required this.pricePerWeek,
    required this.priceLabel,
    required this.isActive,
  });

  final String id;
  final String pathId;
  final String title;
  final int durationWeeks;
  final int pricePerWeek;
  final String priceLabel;
  final bool isActive;
}
