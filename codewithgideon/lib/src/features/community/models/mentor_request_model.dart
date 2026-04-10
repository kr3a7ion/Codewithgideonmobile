import 'package:cloud_firestore/cloud_firestore.dart';

enum MentorRequestContext { live, recorded }

enum MentorChatSenderType { user, admin, system }

class MentorRequestModel {
  const MentorRequestModel({
    required this.id,
    required this.name,
    required this.email,
    required this.message,
    required this.status,
    required this.source,
    required this.contextType,
    required this.sessionId,
    required this.sessionTitle,
    required this.pathTitle,
    required this.cohortKey,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String email;
  final String message;
  final String status;
  final String source;
  final MentorRequestContext contextType;
  final String sessionId;
  final String sessionTitle;
  final String pathTitle;
  final String cohortKey;
  final DateTime createdAt;

  bool get isResolved => status.toLowerCase() == 'resolved';
  bool get isRead => status.toLowerCase() == 'read';
  bool get isNew => !isRead && !isResolved;

  factory MentorRequestModel.fromFirestore(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final createdAtRaw = data['createdAt'];
    final createdAt = createdAtRaw is Timestamp
        ? createdAtRaw.toDate()
        : DateTime.tryParse('${data['createdAt']}') ?? DateTime.now();
    final contextType =
        '${data['contextType'] ?? 'recorded'}'.toLowerCase() == 'live'
        ? MentorRequestContext.live
        : MentorRequestContext.recorded;

    return MentorRequestModel(
      id: doc.id,
      name: (data['name'] as String?) ?? 'Student',
      email: (data['email'] as String?) ?? '',
      message: (data['message'] as String?) ?? '',
      status: (data['status'] as String?) ?? 'new',
      source: (data['source'] as String?) ?? 'mobile-ask-mentor',
      contextType: contextType,
      sessionId: (data['sessionId'] as String?) ?? '',
      sessionTitle: (data['sessionTitle'] as String?) ?? 'Ask Mentor',
      pathTitle: (data['pathTitle'] as String?) ?? '',
      cohortKey: (data['cohortKey'] as String?) ?? '',
      createdAt: createdAt,
    );
  }
}

class MentorChatMessage {
  const MentorChatMessage({
    required this.id,
    required this.conversationId,
    required this.body,
    required this.senderType,
    required this.senderName,
    required this.createdAt,
    this.senderEmail,
    this.status,
    this.source,
    this.isConversationStarter = false,
  });

  final String id;
  final String conversationId;
  final String body;
  final MentorChatSenderType senderType;
  final String senderName;
  final DateTime createdAt;
  final String? senderEmail;
  final String? status;
  final String? source;
  final bool isConversationStarter;

  bool get isMine => senderType == MentorChatSenderType.user;
  bool get isAdmin => senderType == MentorChatSenderType.admin;
  bool get isSystem => senderType == MentorChatSenderType.system;
  bool get isResolved => (status ?? '').toLowerCase() == 'resolved';
  bool get isRead => (status ?? '').toLowerCase() == 'read';

  factory MentorChatMessage.fromRootDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    return MentorChatMessage(
      id: '${doc.id}-root',
      conversationId: doc.id,
      body: _messageBody(data),
      senderType: _isAdminMessage(data)
          ? MentorChatSenderType.admin
          : MentorChatSenderType.user,
      senderName: _displayName(data),
      senderEmail: _email(data),
      createdAt: _coerceDate(
        data['createdAt'] ?? data['sentAt'] ?? data['timestamp'],
      ),
      status: data['status'] as String?,
      source: data['source'] as String?,
      isConversationStarter: true,
    );
  }

  factory MentorChatMessage.fromMap({
    required String conversationId,
    required Map<String, dynamic> data,
    required String fallbackId,
  }) {
    return MentorChatMessage(
      id: data['id']?.toString() ?? fallbackId,
      conversationId: conversationId,
      body: _messageBody(data),
      senderType: _isAdminMessage(data)
          ? MentorChatSenderType.admin
          : MentorChatSenderType.user,
      senderName: _displayName(data),
      senderEmail: _email(data),
      createdAt: _coerceDate(
        data['createdAt'] ?? data['sentAt'] ?? data['timestamp'],
      ),
      status: data['status'] as String?,
      source: data['source']?.toString(),
    );
  }
}

DateTime _coerceDate(Object? raw) {
  if (raw is Timestamp) return raw.toDate();
  if (raw is DateTime) return raw;
  return DateTime.tryParse('$raw') ?? DateTime.now();
}

String _messageBody(Map<String, dynamic> data) {
  return (data['body'] as String?)?.trim() ??
      (data['message'] as String?)?.trim() ??
      (data['text'] as String?)?.trim() ??
      (data['content'] as String?)?.trim() ??
      (data['lastMessage'] as String?)?.trim() ??
      '';
}

String _displayName(Map<String, dynamic> data) {
  return (data['name'] as String?)?.trim() ??
      (data['fullName'] as String?)?.trim() ??
      (data['senderName'] as String?)?.trim() ??
      (data['displayName'] as String?)?.trim() ??
      'Unknown';
}

String _email(Map<String, dynamic> data) {
  return (data['email'] as String?)?.trim() ??
      (data['senderEmail'] as String?)?.trim() ??
      '';
}

bool _isAdminMessage(Map<String, dynamic> data) {
  final senderType =
      '${data['senderType'] ?? data['senderRole'] ?? data['role'] ?? ''}'
          .toLowerCase();
  final source = '${data['source'] ?? ''}'.toLowerCase();
  final sentBy = '${data['sentBy'] ?? ''}'.toLowerCase();
  return senderType == 'admin' ||
      source == 'admin-dashboard' ||
      sentBy == 'admin';
}
