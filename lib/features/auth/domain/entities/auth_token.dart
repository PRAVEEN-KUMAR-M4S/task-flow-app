import 'package:equatable/equatable.dart';

/// Domain entity representing an auth token pair with expiry.
///
/// The token strings are opaque values from the mock login response. They are
/// never logged or rendered — only persisted to secure storage.
class AuthToken extends Equatable {
  final String accessToken;
  final String refreshToken;
  final DateTime expiresAt;

  /// `null` when the payload does not state a refresh-token lifetime.
  final DateTime? refreshExpiresAt;

  const AuthToken({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
    this.refreshExpiresAt,
  });

  bool get isExpired => !DateTime.now().isBefore(expiresAt);

  /// Time remaining before the access token expires; `Duration.zero` once past.
  Duration get timeToExpiry {
    final remaining = expiresAt.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  @override
  List<Object?> get props => [accessToken, refreshToken, expiresAt, refreshExpiresAt];

  /// Deliberately omits the token values so they cannot leak into logs.
  @override
  String toString() => 'AuthToken(expiresAt: $expiresAt)';
}
