/// Abstract interface for network connectivity detection.
///
/// Lives in [core] so both the data layer (repositories) and the presentation
/// layer (ConnectivityCubit) can depend on a single abstraction without
/// violating Clean Architecture dependency rules.
abstract class NetworkInfo {
  /// Returns `true` when the device has an active network connection.
  Future<bool> get isConnected;
}
