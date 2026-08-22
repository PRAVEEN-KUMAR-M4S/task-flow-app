import 'package:json_annotation/json_annotation.dart';
import 'package:task_flow/core/constants/app_constants.dart';
import 'package:task_flow/features/auth/domain/entities/test_credential.dart';

part 'test_credential_model.g.dart';

/// Mirrors a row of `auth_mock.test_credentials`:
/// `{ email, password, org_id, role }`.
@JsonSerializable()
class TestCredentialModel {
  final String email;
  final String password;
  @JsonKey(name: 'org_id')
  final String orgId;
  @JsonKey(defaultValue: AppConstants.roleMember)
  final String role;

  const TestCredentialModel({
    required this.email,
    required this.password,
    required this.orgId,
    required this.role,
  });

  factory TestCredentialModel.fromJson(Map<String, dynamic> json) =>
      _$TestCredentialModelFromJson(json);

  Map<String, dynamic> toJson() => _$TestCredentialModelToJson(this);

  TestCredential toEntity() => TestCredential(
        email: email,
        password: password,
        orgId: orgId,
        role: role,
      );
}
