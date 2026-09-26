import 'dart:async';

import 'api_exception.dart';

/// Thin wrapper kept so existing repositories compile unchanged.
///
/// It used to add an artificial delay (650 ms by default) to simulate a
/// network while the app ran on demo data. Every repository now talks to
/// Firestore for real, so the delay only slowed the app down: nested calls
/// added ~5 s to each dashboard load. [latency] is accepted but ignored.
class ApiClient {
  const ApiClient();

  Future<T> simulateRequest<T>(
    FutureOr<T> Function() callback, {
    Duration latency = Duration.zero,
    bool shouldFail = false,
    String errorMessage = 'Something went wrong. Please try again.',
  }) async {
    if (shouldFail) {
      throw ApiException(errorMessage);
    }
    return await callback();
  }
}
