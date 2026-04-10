import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../cohorts/models/cohort_session_model.dart';
import '../../entry/state/auth_provider.dart';
import '../../home/models/student_dashboard_snapshot.dart';
import '../models/mentor_request_model.dart';

class MentorRequestRepository {
  MentorRequestRepository({required FirebaseFirestore firebaseFirestore})
    : _firebaseFirestore = firebaseFirestore;

  final FirebaseFirestore _firebaseFirestore;

  Stream<List<MentorChatMessage>> watchConversation({
    required String studentUid,
    String? sessionId,
  }) {
    return _firebaseFirestore
        .collection('contactMessages')
        .where('auth.uid', isEqualTo: studentUid)
        .snapshots()
        .asyncMap((snapshot) async {
          final docs =
              snapshot.docs.where((doc) {
                final data = doc.data();
                final source = '${data['source'] ?? ''}';
                final matchesSource = source.startsWith('mobile-ask-mentor');
                final matchesSession =
                    sessionId == null ||
                    '${data['sessionId'] ?? ''}' == sessionId;
                return matchesSource && matchesSession;
              }).toList()..sort(
                (a, b) => _toDateTime(
                  a.data()['createdAt'],
                ).compareTo(_toDateTime(b.data()['createdAt'])),
              );

          final mergedThreads = <MentorChatMessage>[];
          for (final doc in docs) {
            final data = doc.data();
            final rootMessage = MentorChatMessage.fromRootDocument(doc);
            if (rootMessage.body.isNotEmpty) {
              mergedThreads.add(rootMessage);
            }

            final embeddedThread = [
              ..._embeddedMessages(doc.id, data['thread']),
              ..._embeddedMessages(doc.id, data['messages']),
              ..._embeddedMessages(doc.id, data['replies']),
            ];

            final subcollection = await _firebaseFirestore
                .collection('contactMessages')
                .doc(doc.id)
                .collection('messages')
                .orderBy('createdAt', descending: false)
                .get();

            final subMessages = subcollection.docs
                .map(
                  (item) => MentorChatMessage.fromMap(
                    conversationId: doc.id,
                    data: {'id': item.id, ...item.data()},
                    fallbackId: '${doc.id}-${item.id}',
                  ),
                )
                .where((item) => item.body.isNotEmpty)
                .toList();

            final combined = [...embeddedThread, ...subMessages];
            for (final message in combined) {
              final duplicate = mergedThreads.any(
                (existing) =>
                    existing.conversationId == message.conversationId &&
                    existing.body == message.body &&
                    existing.senderType == message.senderType &&
                    existing.createdAt == message.createdAt,
              );
              if (!duplicate) {
                mergedThreads.add(message);
              }
            }
          }

          mergedThreads.sort((a, b) => a.createdAt.compareTo(b.createdAt));
          return mergedThreads;
        });
  }

  Future<void> submitRequest({
    required StudentDashboardSnapshot dashboard,
    required CohortSessionModel session,
    required String message,
    required MentorRequestContext contextType,
  }) async {
    final profile = dashboard.profile;
    final sourceSuffix = contextType == MentorRequestContext.live
        ? 'live'
        : 'recorded';

    await _firebaseFirestore.collection('contactMessages').add({
      'name': profile.fullName.trim(),
      'email': profile.email.trim(),
      'body': message.trim(),
      'message': message.trim(),
      'lastMessage': message.trim(),
      'status': 'new',
      'source': 'mobile-ask-mentor:$sourceSuffix',
      'category': 'ask-mentor',
      'contextType': sourceSuffix,
      'sessionId': session.id,
      'sessionTitle': session.title,
      'pathTitle': session.pathTitle,
      'cohortKey': session.cohortKey,
      'cohortId': profile.cohortId,
      'cohortLabel': profile.cohortLabel,
      'studentUid': profile.uid,
      'studentPhone': profile.phone,
      'auth': {'uid': profile.uid},
      'createdAt': FieldValue.serverTimestamp(),
      'lastMessageAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}

final mentorRequestRepositoryProvider = Provider<MentorRequestRepository>((
  ref,
) {
  return MentorRequestRepository(
    firebaseFirestore: ref.watch(firebaseFirestoreProvider),
  );
});

final mentorRequestsProvider = StreamProvider.autoDispose
    .family<List<MentorChatMessage>, String?>((ref, sessionId) {
      final authState = ref.watch(authControllerProvider);
      final session = authState.session;
      if (session == null) {
        return const Stream<List<MentorChatMessage>>.empty();
      }

      return ref
          .watch(mentorRequestRepositoryProvider)
          .watchConversation(studentUid: session.uid, sessionId: sessionId);
    });

List<MentorChatMessage> _embeddedMessages(String conversationId, Object? raw) {
  if (raw is! List) return const <MentorChatMessage>[];

  return raw
      .asMap()
      .entries
      .where((entry) => entry.value is Map)
      .map(
        (entry) => MentorChatMessage.fromMap(
          conversationId: conversationId,
          data: Map<String, dynamic>.from(entry.value as Map),
          fallbackId: '$conversationId-embedded-${entry.key}',
        ),
      )
      .where((item) => item.body.isNotEmpty)
      .toList();
}

DateTime _toDateTime(Object? raw) {
  if (raw is Timestamp) return raw.toDate();
  return DateTime.tryParse('$raw') ?? DateTime.now();
}
