import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../cohorts/models/cohort_session_model.dart';
import '../../entry/state/auth_provider.dart';
import '../../home/models/student_dashboard_snapshot.dart';
import '../models/mentor_request_model.dart';

class MentorConversationQuery {
  const MentorConversationQuery({this.sessionId, this.conversationId});

  final String? sessionId;
  final String? conversationId;

  @override
  bool operator ==(Object other) =>
      other is MentorConversationQuery &&
      other.sessionId == sessionId &&
      other.conversationId == conversationId;

  @override
  int get hashCode => Object.hash(sessionId, conversationId);
}

class MentorRequestRepository {
  MentorRequestRepository({
    required FirebaseFirestore firebaseFirestore,
    required FirebaseFunctions firebaseFunctions,
  }) : _db = firebaseFirestore,
       _fn = firebaseFunctions;

  final FirebaseFirestore _db;
  final FirebaseFunctions _fn;

  CollectionReference<Map<String, dynamic>> get _threadsCollection =>
      _db.collection('mentorThreads');

  String buildThreadId({required String studentUid}) {
    final sanitize = RegExp(r'[^A-Za-z0-9._-]+');
    final cleanUid = studentUid.trim().replaceAll(sanitize, '_');
    return 'mentor_$cleanUid';
  }

  String _cacheKey(String studentUid, String? sessionId) {
    final normalizedSessionId = (sessionId ?? '').trim();
    return 'mentor.chat.$studentUid.${normalizedSessionId.isEmpty ? 'all' : normalizedSessionId}';
  }

  Future<List<MentorChatMessage>> loadCachedConversation({
    required String studentUid,
    String? sessionId,
  }) async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_cacheKey(studentUid, sessionId));
    if (raw == null || raw.isEmpty) {
      return const <MentorChatMessage>[];
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return const <MentorChatMessage>[];
      }

      return decoded
          .whereType<Map>()
          .map(
            (item) =>
                MentorChatMessage.fromCache(Map<String, dynamic>.from(item)),
          )
          .where((item) => item.body.isNotEmpty)
          .toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    } catch (_) {
      return const <MentorChatMessage>[];
    }
  }

  Future<void> saveCachedConversation({
    required String studentUid,
    String? sessionId,
    required List<MentorChatMessage> messages,
  }) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _cacheKey(studentUid, sessionId),
      jsonEncode(messages.map((item) => item.toCacheMap()).toList()),
    );
  }

  Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>> watchStudentThreads(
    String studentUid,
  ) {
    return _threadsCollection
        .where('studentUid', isEqualTo: studentUid)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs);
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> watchThreadDoc(
    String conversationId,
  ) {
    return _threadsCollection.doc(conversationId).snapshots();
  }

  Stream<List<MentorChatMessage>> watchSubMessages(String conversationId) {
    return _threadsCollection
        .doc(conversationId)
        .collection('messages')
        .orderBy('createdAt')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map(
                (doc) => MentorChatMessage.fromMap(
                  conversationId: conversationId,
                  data: {'id': doc.id, ...doc.data()},
                  fallbackId: '$conversationId-${doc.id}',
                ),
              )
              .where((item) => item.body.isNotEmpty)
              .toList();
        });
  }

  Future<String> submitRequest({
    required StudentDashboardSnapshot dashboard,
    CohortSessionModel? session,
    String? fallbackSessionId,
    required String message,
    required MentorRequestContext contextType,
    String? clientMessageId,
  }) async {
    final profile = dashboard.profile;
    final sessionId = (session?.id ?? fallbackSessionId ?? '').trim();
    final sessionTitle = (session?.title ?? 'General mentor support').trim();
    final pathTitle = (session?.pathTitle ?? dashboard.path.title).trim();
    final cohortKey = (session?.cohortKey ?? dashboard.activeCohort.cohortKey)
        .trim();
    final callable = _fn.httpsCallable('sendMentorRequest');
    final response = await callable.call(<String, dynamic>{
      'name': profile.fullName.trim(),
      'email': profile.email.trim(),
      'message': message.trim(),
      'clientMessageId': (clientMessageId ?? '').trim(),
      'contextType': session != null && contextType == MentorRequestContext.live
          ? 'live'
          : 'recorded',
      'sessionId': sessionId,
      'sessionTitle': sessionTitle,
      'pathTitle': pathTitle,
      'cohortKey': cohortKey,
      'cohortId': profile.cohortId,
      'cohortLabel': profile.cohortLabel,
      'studentPhone': profile.phone,
    });
    final data = Map<String, dynamic>.from(response.data as Map);
    return '${data['conversationId'] ?? ''}'.trim();
  }
}

List<MentorChatMessage> _dedupeTimeline(
  List<MentorChatMessage> primary,
  List<MentorChatMessage> secondary,
) {
  final merged = <MentorChatMessage>[...primary];
  for (final message in secondary) {
    if (!merged.any((existing) => _isSameMessage(existing, message))) {
      merged.add(message);
    }
  }
  merged.sort((a, b) => a.createdAt.compareTo(b.createdAt));
  return merged;
}

bool _isSameMessage(MentorChatMessage left, MentorChatMessage right) {
  final leftClientId = (left.clientMessageId ?? '').trim();
  final rightClientId = (right.clientMessageId ?? '').trim();
  if (leftClientId.isNotEmpty && rightClientId.isNotEmpty) {
    return leftClientId == rightClientId;
  }

  final leftId = left.id.trim();
  final rightId = right.id.trim();
  final leftIsOptimistic = leftId.startsWith('optimistic-');
  final rightIsOptimistic = rightId.startsWith('optimistic-');
  if (!leftIsOptimistic && !rightIsOptimistic && leftId == rightId) {
    return true;
  }

  if (left.senderType != right.senderType) return false;
  if (left.body.trim() != right.body.trim()) return false;

  return left.createdAt.difference(right.createdAt).inSeconds.abs() <= 3;
}

MentorChatMessage _systemErrorMessage({
  required String conversationId,
  required String sessionId,
  required Object error,
}) {
  final isPermissionDenied =
      error is FirebaseException && error.code == 'permission-denied';

  return MentorChatMessage(
    id: 'system-$conversationId-${isPermissionDenied ? 'permission' : 'sync'}',
    conversationId: conversationId,
    sessionId: sessionId,
    body: isPermissionDenied
        ? 'We are setting up this mentor conversation. Send your message and replies will appear here.'
        : 'We could not refresh mentor replies just now. Check your connection and try again.',
    senderType: MentorChatSenderType.system,
    senderName: 'CodeWithGideon',
    createdAt: DateTime.now(),
    status: 'system',
    source: 'mobile-system',
  );
}

class MentorConversationNotifier
    extends AsyncNotifier<List<MentorChatMessage>> {
  MentorConversationNotifier(this.query);

  final MentorConversationQuery query;

  StreamSubscription<List<QueryDocumentSnapshot<Map<String, dynamic>>>>?
  _threadsSub;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _threadDocSub;
  StreamSubscription<List<MentorChatMessage>>? _messagesSub;

  MentorRequestRepository get _repository =>
      ref.read(mentorRequestRepositoryProvider);

  @override
  Future<List<MentorChatMessage>> build() async {
    final authState = ref.watch(authControllerProvider);
    final session = authState.session;
    if (session == null) {
      return const <MentorChatMessage>[];
    }

    final cached = await _repository.loadCachedConversation(
      studentUid: session.uid,
      sessionId: query.sessionId,
    );
    if (cached.isNotEmpty) {
      state = AsyncData(cached);
    }

    ref.onDispose(_cancelAll);

    if ((query.sessionId ?? '').trim().isEmpty &&
        (query.conversationId ?? '').trim().isEmpty) {
      _bindSummaryTimeline(studentUid: session.uid);
      return cached;
    }

    final preferredConversationId = ref.watch(
      mentorConversationIdOverrideProvider(query.sessionId),
    );
    final explicitConversationId =
        (preferredConversationId ?? query.conversationId)?.trim();
    final sessionId = (query.sessionId ?? '').trim();
    final conversationId = explicitConversationId?.isNotEmpty == true
        ? explicitConversationId!
        : _repository.buildThreadId(studentUid: session.uid);
    _bindConversationTimeline(
      studentUid: session.uid,
      conversationId: conversationId,
      sessionId: sessionId,
    );
    return cached;
  }

  void _bindSummaryTimeline({required String studentUid}) {
    _threadsSub = _repository
        .watchStudentThreads(studentUid)
        .listen(
          (docs) {
            final summaries =
                docs
                    .map(MentorChatMessage.fromThreadSummary)
                    .where((item) => item.body.trim().isNotEmpty)
                    .toList()
                  ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
            state = AsyncData(summaries);
            unawaited(
              _repository.saveCachedConversation(
                studentUid: studentUid,
                sessionId: query.sessionId,
                messages: summaries,
              ),
            );
          },
          onError: (Object error, StackTrace stackTrace) {
            state = AsyncData(
              _dedupeTimeline(state.value ?? const <MentorChatMessage>[], [
                _systemErrorMessage(
                  conversationId: 'mentor-summary',
                  sessionId: '',
                  error: error,
                ),
              ]),
            );
          },
        );
  }

  void _bindConversationTimeline({
    required String studentUid,
    required String conversationId,
    required String sessionId,
  }) {
    Map<String, dynamic> rootData = <String, dynamic>{};
    List<MentorChatMessage> subMessages = const <MentorChatMessage>[];

    List<MentorChatMessage> applyThreadReceipt(
      List<MentorChatMessage> messages,
    ) {
      final threadStatus =
          rootData['status']?.toString().trim().isNotEmpty == true
          ? rootData['status'].toString().trim()
          : null;
      if (threadStatus == null || threadStatus.toLowerCase() == 'new') {
        return messages;
      }
      return messages
          .map(
            (item) => item.isMine && (item.status ?? '').trim().isEmpty
                ? item.copyWith(status: threadStatus)
                : item,
          )
          .toList();
    }

    void emit() {
      final visibleMessages = applyThreadReceipt(subMessages);
      state = AsyncData(visibleMessages);
      unawaited(
        _repository.saveCachedConversation(
          studentUid: studentUid,
          sessionId: query.sessionId,
          messages: visibleMessages,
        ),
      );
    }

    _threadDocSub = _repository
        .watchThreadDoc(conversationId)
        .listen(
          (doc) {
            rootData = doc.data() ?? <String, dynamic>{};
            emit();
          },
          onError: (Object error, StackTrace stackTrace) {
            state = AsyncData(state.value ?? subMessages);
          },
        );

    _messagesSub = _repository
        .watchSubMessages(conversationId)
        .listen(
          (messages) {
            subMessages = messages.map((item) {
              final fallbackSessionId =
                  rootData['sessionId']?.toString().trim().isNotEmpty == true
                  ? rootData['sessionId'].toString().trim()
                  : sessionId;
              final threadStatus =
                  rootData['status']?.toString().trim().isNotEmpty == true
                  ? rootData['status'].toString().trim()
                  : null;
              final normalized = item.sessionId.trim().isEmpty
                  ? item.copyWith(sessionId: fallbackSessionId)
                  : item;
              if (normalized.isMine &&
                  (normalized.status ?? '').trim().isEmpty &&
                  threadStatus != null &&
                  threadStatus.toLowerCase() != 'new') {
                return normalized.copyWith(status: threadStatus);
              }
              return normalized;
            }).toList();
            emit();
          },
          onError: (Object error, StackTrace stackTrace) {
            final fallbackSessionId =
                rootData['sessionId']?.toString().trim().isNotEmpty == true
                ? rootData['sessionId'].toString().trim()
                : sessionId;
            state = AsyncData(
              _dedupeTimeline(subMessages, <MentorChatMessage>[
                _systemErrorMessage(
                  conversationId: conversationId,
                  sessionId: fallbackSessionId,
                  error: error,
                ),
              ]),
            );
          },
        );
  }

  Future<void> _cancelAll() async {
    await _threadsSub?.cancel();
    await _threadDocSub?.cancel();
    await _messagesSub?.cancel();
    _threadsSub = null;
    _threadDocSub = null;
    _messagesSub = null;
  }
}

final mentorRequestRepositoryProvider = Provider<MentorRequestRepository>((
  ref,
) {
  return MentorRequestRepository(
    firebaseFirestore: ref.watch(firebaseFirestoreProvider),
    firebaseFunctions: ref.watch(firebaseFunctionsProvider),
  );
});

final mentorConversationIdOverrideProvider = StateProvider.autoDispose
    .family<String?, String?>((ref, sessionId) => null);

final mentorConversationProvider = AsyncNotifierProvider.autoDispose
    .family<
      MentorConversationNotifier,
      List<MentorChatMessage>,
      MentorConversationQuery
    >((query) => MentorConversationNotifier(query));

final mentorRequestsProvider = mentorConversationProvider;

List<MentorChatMessage> mergeChatTimeline(
  List<MentorChatMessage> persisted,
  List<MentorChatMessage> optimistic,
) {
  return _dedupeTimeline(persisted, optimistic);
}

List<MentorChatMessage> reconcileOptimistic({
  required List<MentorChatMessage> optimistic,
  required List<MentorChatMessage> persisted,
}) {
  return optimistic
      .where(
        (item) => !persisted.any((message) => _isSameMessage(message, item)),
      )
      .toList();
}
