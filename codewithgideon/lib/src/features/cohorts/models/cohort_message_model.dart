class CohortMessageModel {
  const CohortMessageModel({
    required this.id,
    required this.cohortId,
    required this.cohortLabel,
    required this.title,
    required this.body,
    required this.ctaLabel,
    required this.ctaUrl,
    required this.sentBy,
    required this.createdAt,
  });

  final String id;
  final String cohortId;
  final String cohortLabel;
  final String title;
  final String body;
  final String ctaLabel;
  final String ctaUrl;
  final String sentBy;
  final DateTime createdAt;

  bool get hasCta => ctaLabel.trim().isNotEmpty && ctaUrl.trim().isNotEmpty;
}
