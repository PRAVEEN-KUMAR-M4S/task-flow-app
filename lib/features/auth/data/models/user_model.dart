import 'package:json_annotation/json_annotation.dart';
import 'package:task_flow/core/constants/app_constants.dart';
import 'package:task_flow/features/auth/domain/entities/user.dart';

part 'user_model.g.dart';

/// Mirrors a row of the `users` table in the mock data:
/// `{ id, name, email, avatar_url }`.
///
/// Organization fields are **not** part of that row — they are joined in from
/// `org_members` / `organizations` via [withOrgMembership] and are therefore
/// excluded from JSON in both directions.
@JsonSerializable()
class UserModel {
  final String id;
  final String name;
  final String email;
  @JsonKey(name: 'avatar_url')
  final String? avatarUrl;

  @JsonKey(includeFromJson: false, includeToJson: false)
  final String orgId;
  @JsonKey(includeFromJson: false, includeToJson: false)
  final String orgName;
  @JsonKey(includeFromJson: false, includeToJson: false)
  final String role;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl,
    this.orgId = '',
    this.orgName = '',
    this.role = AppConstants.roleMember,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);

  Map<String, dynamic> toJson() => _$UserModelToJson(this);

  /// Returns a copy with org membership data joined in.
  UserModel withOrgMembership({
    required String orgId,
    required String orgName,
    required String role,
  }) {
    return UserModel(
      id: id,
      name: name,
      email: email,
      avatarUrl: avatarUrl,
      orgId: orgId,
      orgName: orgName,
      role: role,
    );
  }

  User toEntity() {
    return User(
      id: id,
      name: name,
      email: email,
      avatarUrl: avatarUrl,
      orgId: orgId,
      orgName: orgName,
      role: role,
    );
  }

  factory UserModel.fromEntity(User user) {
    return UserModel(
      id: user.id,
      name: user.name,
      email: user.email,
      avatarUrl: user.avatarUrl,
      orgId: user.orgId,
      orgName: user.orgName,
      role: user.role,
    );
  }
}
