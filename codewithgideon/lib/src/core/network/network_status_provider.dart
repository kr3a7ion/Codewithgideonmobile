import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'
    show Provider, StreamProvider;

enum NetworkStatus { online, offline }

final connectivityProvider = Provider<Connectivity>((ref) {
  return Connectivity();
});

final networkStatusProvider = StreamProvider<NetworkStatus>((ref) async* {
  final connectivity = ref.watch(connectivityProvider);
  final initial = await connectivity.checkConnectivity();
  yield _toStatus(initial);

  yield* connectivity.onConnectivityChanged.map(_toStatus);
});

NetworkStatus _toStatus(List<ConnectivityResult> results) {
  if (results.isEmpty ||
      results.every((item) => item == ConnectivityResult.none)) {
    return NetworkStatus.offline;
  }
  return NetworkStatus.online;
}
