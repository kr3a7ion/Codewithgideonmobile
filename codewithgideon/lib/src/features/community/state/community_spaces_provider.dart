import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../entry/state/auth_provider.dart';
import '../../home/state/dashboard_provider.dart';
import '../models/community_space_model.dart';

class CommunitySpacesRepository {
  CommunitySpacesRepository({required FirebaseFirestore firebaseFirestore})
    : _firebaseFirestore = firebaseFirestore;

  final FirebaseFirestore _firebaseFirestore;

  Stream<List<CommunitySpaceModel>> watchSpaces({
    required Set<String> cohortTokens,
    required String pathId,
  }) {
    return _firebaseFirestore
        .collection('communitySpaces')
        .orderBy('sortOrder')
        .snapshots()
        .map((snapshot) {
          final spaces =
              snapshot.docs
                  .map(CommunitySpaceModel.fromFirestore)
                  .where((space) => space.isPublished)
                  .where((space) {
                    final matchesCohort =
                        space.cohortId == null ||
                        cohortTokens.contains(space.cohortId);
                    final matchesPath =
                        space.pathId == null || space.pathId == pathId;
                    return matchesCohort && matchesPath;
                  })
                  .toList()
                ..sort((a, b) {
                  final sortOrder = a.sortOrder.compareTo(b.sortOrder);
                  if (sortOrder != 0) return sortOrder;
                  final aUpdated = a.updatedAt?.millisecondsSinceEpoch ?? 0;
                  final bUpdated = b.updatedAt?.millisecondsSinceEpoch ?? 0;
                  return bUpdated.compareTo(aUpdated);
                });
          return spaces;
        });
  }
}

final communitySpacesRepositoryProvider = Provider<CommunitySpacesRepository>((
  ref,
) {
  return CommunitySpacesRepository(
    firebaseFirestore: ref.watch(firebaseFirestoreProvider),
  );
});

final communitySpacesProvider =
    StreamProvider.autoDispose<List<CommunitySpaceModel>>((ref) {
      final authState = ref.watch(authControllerProvider);
      if (authState.session == null) {
        return const Stream<List<CommunitySpaceModel>>.empty();
      }

      final dashboard = ref.watch(
        dashboardSnapshotProvider.select(
          (value) =>
              value.maybeWhen(data: (snapshot) => snapshot, orElse: () => null),
        ),
      );
      if (dashboard == null) {
        return const Stream<List<CommunitySpaceModel>>.empty();
      }

      final cohortTokens = <String>{
        dashboard.profile.cohortId ?? '',
        dashboard.profile.cohortKey ?? '',
        dashboard.activeCohort.cohortId,
        dashboard.activeCohort.cohortKey,
      }..removeWhere((item) => item.trim().isEmpty);

      return ref
          .watch(communitySpacesRepositoryProvider)
          .watchSpaces(
            cohortTokens: cohortTokens,
            pathId: dashboard.profile.pathId,
          );
    });

final communitySpaceByIdProvider = Provider.autoDispose
    .family<CommunitySpaceModel?, String>((ref, id) {
      final spaces = ref.watch(
        communitySpacesProvider.select(
          (value) =>
              value.maybeWhen(data: (items) => items, orElse: () => const []),
        ),
      );
      for (final item in spaces) {
        if (item.id == id) return item;
      }
      return null;
    });
