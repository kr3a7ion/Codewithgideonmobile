import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../entry/state/auth_provider.dart' show firebaseFirestoreProvider;
import '../../home/state/dashboard_provider.dart'
    show catalogRepositoryProvider, studentRepositoryProvider;
import '../data/payment_repository.dart';

final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  return PaymentRepository(
    firebaseFirestore: ref.watch(firebaseFirestoreProvider),
    studentRepository: ref.watch(studentRepositoryProvider),
    catalogRepository: ref.watch(catalogRepositoryProvider),
  );
});
