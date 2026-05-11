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
    required this.sessionId,
    required this.body,
    required this.senderType,
    required this.senderName,
    required this.createdAt,
    this.senderEmail,
    this.status,
    this.source,
    this.clientMessageId,
    this.isConversationStarter = false,
  });

  final String id;
  final String conversationId;
  final String sessionId;
  final String body;
  final MentorChatSenderType senderType;
  final String senderName;
  final DateTime createdAt;
  final String? senderEmail;
  final String? status;
  final String? source;
  final String? clientMessageId;
  final bool isConversationStarter;

  bool get isMine => senderType == MentorChatSenderType.user;
  bool get isAdmin => senderType == MentorChatSenderType.admin;
  bool get isSystem => senderType == MentorChatSenderType.system;
  bool get isResolved => (status ?? '').toLowerCase() == 'resolved';
  bool get isRead => (status ?? '').toLowerCase() == 'read';
  bool get isSending => (status ?? '').toLowerCase() == 'sending';
  bool get isFailed => (status ?? '').toLowerCase() == 'failed';

  factory MentorChatMessage.fromThreadSummary(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    return MentorChatMessage(
      id: (data['lastMessageId']?.toString().trim().isNotEmpty ?? false)
          ? data['lastMessageId'].toString()
          : '${doc.id}-summary',
      conversationId: doc.id,
      sessionId: (data['sessionId'] as String?) ?? '',
      body: _summaryBody(data),
      senderType: _isAdminSummary(data)
          ? MentorChatSenderType.admin
          : MentorChatSenderType.user,
      senderName: _summaryDisplayName(data),
      senderEmail: _summaryEmail(data),
      createdAt: _coerceDate(
        data['lastMessageAt'] ?? data['updatedAt'] ?? data['createdAt'],
      ),
      status: data['status'] as String?,
      source: data['source'] as String?,
      clientMessageId: data['clientMessageId']?.toString(),
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
      sessionId: (data['sessionId'] as String?) ?? '',
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
      clientMessageId: data['clientMessageId']?.toString(),
    );
  }

  factory MentorChatMessage.fromCache(Map<String, dynamic> data) {
    final senderLabel = '${data['senderType'] ?? 'user'}'.toLowerCase();
    final senderType = switch (senderLabel) {
      'admin' => MentorChatSenderType.admin,
      'system' => MentorChatSenderType.system,
      _ => MentorChatSenderType.user,
    };

    return MentorChatMessage(
      id: data['id']?.toString() ?? '',
      conversationId: data['conversationId']?.toString() ?? '',
      sessionId: data['sessionId']?.toString() ?? '',
      body: data['body']?.toString() ?? '',
      senderType: senderType,
      senderName: data['senderName']?.toString() ?? 'Unknown',
      createdAt: _coerceDate(data['createdAt']),
      senderEmail: data['senderEmail']?.toString(),
      status: data['status']?.toString(),
      source: data['source']?.toString(),
      clientMessageId: data['clientMessageId']?.toString(),
      isConversationStarter: data['isConversationStarter'] == true,
    );
  }

  Map<String, dynamic> toCacheMap() {
    return <String, dynamic>{
      'id': id,
      'conversationId': conversationId,
      'sessionId': sessionId,
      'body': body,
      'senderType': switch (senderType) {
        MentorChatSenderType.user => 'user',
        MentorChatSenderType.admin => 'admin',
        MentorChatSenderType.system => 'system',
      },
      'senderName': senderName,
      'createdAt': createdAt.toIso8601String(),
      'senderEmail': senderEmail,
      'status': status,
      'source': source,
      'clientMessageId': clientMessageId,
      'isConversationStarter': isConversationStarter,
    };
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
      '';
}

String _summaryBody(Map<String, dynamic> data) {
  return (data['lastMessagePreview'] as String?)?.trim() ??
      (data['lastMessage'] as String?)?.trim() ??
      _messageBody(data);
}

String _displayName(Map<String, dynamic> data) {
  if (_isAdminMessage(data)) {
    return 'Mentor';
  }
  return (data['name'] as String?)?.trim() ??
      (data['fullName'] as String?)?.trim() ??
      (data['senderName'] as String?)?.trim() ??
      (data['displayName'] as String?)?.trim() ??
      'Unknown';
}

String _summaryDisplayName(Map<String, dynamic> data) {
  if (_isAdminSummary(data)) {
    return (data['lastMessageSenderName'] as String?)?.trim().isNotEmpty == true
        ? (data['lastMessageSenderName'] as String).trim()
        : 'Mentor';
  }
  return (data['studentName'] as String?)?.trim() ??
      (data['name'] as String?)?.trim() ??
      _displayName(data);
}

String _email(Map<String, dynamic> data) {
  return (data['email'] as String?)?.trim() ??
      (data['senderEmail'] as String?)?.trim() ??
      '';
}

String _summaryEmail(Map<String, dynamic> data) {
  return (data['lastMessageSenderEmail'] as String?)?.trim() ??
      (data['studentEmail'] as String?)?.trim() ??
      _email(data);
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

bool _isAdminSummary(Map<String, dynamic> data) {
  return '${data['lastMessageSenderType'] ?? ''}'.toLowerCase() == 'admin' ||
      _isAdminMessage(data);
}
