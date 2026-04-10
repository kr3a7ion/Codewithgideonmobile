import 'dart:async';

import 'api_exception.dart';

class ApiClient {
  const ApiClient();

  Future<T> simulateRequest<T>(
    FutureOr<T> Function() callback, {
    Duration latency = const Duration(milliseconds: 650),
    bool shouldFail = false,
    String errorMessage = 'Something went wrong. Please try again.',
  }) async {
    await Future<void>.delayed(latency);
    if (shouldFail) {
      throw ApiException(errorMessage);
    }
    return callback();
  }
}
