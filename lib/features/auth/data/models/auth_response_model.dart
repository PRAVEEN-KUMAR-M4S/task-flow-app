import 'package:json_annotation/json_annotation.dart';
import 'package:task_flow/core/constants/app_constants.dart';
import 'package:task_flow/features/auth/domain/entities/auth_token.dart';

part 'auth_response_model.g.dart';

/// Mirrors `auth_mock.mock_login_response` in the mock data:
/// `{ access_token, refresh_token, access_token_expires_in_seconds,
///    refresh_token_expires_in_seconds }`.
///
/// The payload carries no `token_type`, so none is modelled.
@JsonSerializable()
class AuthResponseModel {
  @JsonKey(name: 'access_token')
  final String accessToken;
  @JsonKey(name: 'refresh_token')
  final String refreshToken;
  @JsonKey(
    name: 'access_token_expires_in_seconds',
    defaultValue: AppConstants.fallbackTokenExpirySeconds,
  )
  final int accessTokenExpiresInSeconds;
  @JsonKey(name: 'refresh_token_expires_in_seconds', defaultValue: 0)
  final int refreshTokenExpiresInSeconds;

  const AuthResponseModel({
    required this.accessToken,
    required this.refreshToken,
    required this.accessTokenExpiresInSeconds,
    required this.refreshTokenExpiresInSeconds,
  });

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) =>
      _$AuthResponseModelFromJson(json);

  Map<String, dynamic> toJson() => _$AuthResponseModelToJson(this);

  /// [issuedAt] is injectable so tests can pin expiry without faking the clock.
  AuthToken toEntity({DateTime? issuedAt}) {
    final now = issuedAt ?? DateTime.now();
    return AuthToken(
      accessToken: accessToken,
      refreshToken: refreshToken,
      expiresAt: now.add(Duration(seconds: accessTokenExpiresInSeconds)),
      refreshExpiresAt: refreshTokenExpiresInSeconds > 0
          ? now.add(Duration(seconds: refreshTokenExpiresInSeconds))
          : null,
    );
  }
}
