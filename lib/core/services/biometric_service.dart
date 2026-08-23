import 'package:local_auth/local_auth.dart';

/// Wraps the `local_auth` plugin, providing biometric availability checks
/// and an authentication prompt. All methods are pure wrappers — no state.
class BiometricService {
  final LocalAuthentication _auth;

  BiometricService({LocalAuthentication? auth})
    : _auth = auth ?? LocalAuthentication();

  /// Whether the device has biometric hardware and the user has enrolled
  /// at least one biometric.
  Future<bool> get canCheckBiometrics async {
    try {
      return await _auth.canCheckBiometrics;
    } catch (e) {
      return false;
    }
  }

  /// Whether the device supports any form of local authentication
  /// (biometrics, PIN, pattern, or passcode).
  Future<bool> get isDeviceSupported async {
    try {
      return await _auth.isDeviceSupported();
    } catch (e) {
      return false;
    }
  }

  /// Returns the list of biometric types enrolled on this device.
  Future<List<BiometricType>> get availableBiometrics async {
    try {
      return await _auth.getAvailableBiometrics();
    } catch (e) {
      return [];
    }
  }

  /// Returns a human-readable label for the enrolled biometric type.
  String biometricLabel(List<BiometricType> types) {
    if (types.isEmpty) return 'None';
    if (types.contains(BiometricType.face)) return 'Face ID';
    if (types.contains(BiometricType.fingerprint)) return 'Fingerprint';
    if (types.contains(BiometricType.strong)) return 'Strong Biometric';
    if (types.contains(BiometricType.weak)) return 'Weak Biometric';
    return 'Unknown';
  }

  /// Prompts the user for biometric (or device PIN) authentication.
  ///
  /// Returns `true` if the user authenticated successfully.
  Future<bool> authenticate({
    String reason = 'Please authenticate to continue',
  }) async {
    try {
      final didAuthenticate = await _auth.authenticate(
        localizedReason: reason,
        biometricOnly: false, // allow PIN/pattern fallback
        persistAcrossBackgrounding: true,
      );

      return didAuthenticate;
    } catch (e) {
      return false;
    }
  }
}
