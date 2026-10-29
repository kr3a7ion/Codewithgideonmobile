import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../entry/state/auth_provider.dart';

/// Share of a recording that counts as watched. Same as the website.
const double watchedAt = 0.9;

/// How far a student is through one class recording. Stored at
/// `users/{uid}/progress/{sessionId}`, shared with the website, so a recording
/// watched on the phone shows as watched on the web and the other way round.
class WatchProgress {
  const WatchProgress({
    required this.sessionId,
    required this.position,
    required this.duration,
    required this.completed,
  });

  final String sessionId;

  /// Seconds into the recording.
  final int position;

  /// Length of the recording in seconds; 0 until the player has reported it.
  final int duration;
  final bool completed;

  double get fraction {
    if (completed) return 1;
    if (duration <= 0) return 0;
    return (position / duration).clamp(0.0, 1.0);
  }

  bool get isStarted => completed || position > 0;

  factory WatchProgress.fromMap(String id, Map<String, dynamic> data) {
    return WatchProgress(
      sessionId: id,
      position: (data['position'] as num?)?.round() ?? 0,
      duration: (data['duration'] as num?)?.round() ?? 0,
      completed: data['completed'] == true,
    );
  }
}

class WatchProgressRepository {
  WatchProgressRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _collection(String uid) {
    return _firestore.collection('users').doc(uid).collection('progress');
  }

  Stream<Map<String, WatchProgress>> watch(String uid) {
    return _collection(uid).snapshots().map(
      (snapshot) => {
        for (final doc in snapshot.docs)
          doc.id: WatchProgress.fromMap(doc.id, doc.data()),
      },
    );
  }

  /// Writes exactly the fields the security rules allow: whole seconds, at
  /// most a day, and a server timestamp.
  Future<void> save({
    required String uid,
    required String sessionId,
    required int position,
    required int duration,
    required bool completed,
  }) {
    final safeDuration = duration.clamp(0, 86400);
    final safePosition = position.clamp(
      0,
      safeDuration > 0 ? safeDuration : 86400,
    );
    return _collection(uid).doc(sessionId).set({
      'sessionId': sessionId,
      'position': safePosition,
      'duration': safeDuration,
      'completed': completed,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}

final watchProgressRepositoryProvider = Provider<WatchProgressRepository>((
  ref,
) {
  return WatchProgressRepository(ref.watch(firebaseFirestoreProvider));
});

/// Every recording the signed-in student has started, by session id. Empty
/// when signed out or when progress can't be read (offline, rules).
final watchProgressProvider =
    StreamProvider.autoDispose<Map<String, WatchProgress>>((ref) {
      final uid = ref.watch(
        authControllerProvider.select((state) => state.session?.uid),
      );
      if (uid == null || uid.isEmpty) {
        return Stream.value(const <String, WatchProgress>{});
      }
      return ref
          .watch(watchProgressRepositoryProvider)
          .watch(uid)
          .transform(
            StreamTransformer<
              Map<String, WatchProgress>,
              Map<String, WatchProgress>
            >.fromHandlers(
              handleError: (error, stackTrace, sink) =>
                  sink.add(const <String, WatchProgress>{}),
            ),
          );
    });

/// Progress for one recording, or null if it hasn't been started.
WatchProgress? progressFor(WidgetRef ref, String sessionId) {
  return ref
      .watch(watchProgressProvider)
      .maybeWhen(data: (items) => items[sessionId], orElse: () => null);
}
