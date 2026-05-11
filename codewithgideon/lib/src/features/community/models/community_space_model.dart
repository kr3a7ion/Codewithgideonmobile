import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CommunitySpaceModel {
  const CommunitySpaceModel({
    required this.id,
    required this.title,
    required this.description,
    required this.isPublished,
    required this.sortOrder,
    this.cohortId,
    this.cohortLabel,
    this.pathId,
    this.roomUrl,
    this.ctaLabel,
    this.category,
    this.iconKey,
    this.updatedAt,
  });

  final String id;
  final String title;
  final String description;
  final bool isPublished;
  final int sortOrder;
  final String? cohortId;
  final String? cohortLabel;
  final String? pathId;
  final String? roomUrl;
  final String? ctaLabel;
  final String? category;
  final String? iconKey;
  final DateTime? updatedAt;

  factory CommunitySpaceModel.fromFirestore(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final updatedAtRaw = data['updatedAt'];
    return CommunitySpaceModel(
      id: doc.id,
      title: '${data['title'] ?? ''}'.trim(),
      description: '${data['description'] ?? ''}'.trim(),
      isPublished: data['isPublished'] != false,
      sortOrder: (data['sortOrder'] as num?)?.toInt() ?? 0,
      cohortId: _cleanString(data['cohortId']),
      cohortLabel: _cleanString(data['cohortLabel']),
      pathId: _cleanString(data['pathId']),
      roomUrl: _cleanString(data['roomUrl']),
      ctaLabel: _cleanString(data['ctaLabel']),
      category: _cleanString(data['category']),
      iconKey: _cleanString(data['icon']),
      updatedAt: _toDateTime(updatedAtRaw),
    );
  }

  IconData get icon {
    switch ((iconKey ?? '').toLowerCase()) {
      case 'sparkles':
        return Icons.auto_awesome_rounded;
      case 'book':
        return Icons.menu_book_rounded;
      case 'folder':
        return Icons.folder_copy_outlined;
      default:
        return Icons.forum_outlined;
    }
  }

  String get actionLabel =>
      (ctaLabel?.trim().isNotEmpty ?? false) ? ctaLabel!.trim() : 'Open space';
}

String? _cleanString(Object? value) {
  final text = '$value'.trim();
  return text.isEmpty || text == 'null' ? null : text;
}

DateTime? _toDateTime(Object? value) {
  if (value is Timestamp) return value.toDate();
  if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
  if (value is String) return DateTime.tryParse(value);
  return null;
}
