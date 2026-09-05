import 'package:connectivity_plus/connectivity_plus.dart';

import 'network_info.dart';

/// Concrete [NetworkInfo] backed by the `connectivity_plus` package.
///
/// Checks whether the device has Wi-Fi, mobile data, or Ethernet.
/// This is a thin wrapper — repositories inject [NetworkInfo] (the
/// abstraction), not this class directly.
class NetworkInfoImpl implements NetworkInfo {
  final Connectivity _connectivity;

  NetworkInfoImpl({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity();

  @override
  Future<bool> get isConnected async {
    final results = await _connectivity.checkConnectivity();
    // `checkConnectivity` returns a List<ConnectivityResult> on newer versions.
    // Treat anything other than "no connection" as connected.
    return results.any((result) => result != ConnectivityResult.none);
  }
}
