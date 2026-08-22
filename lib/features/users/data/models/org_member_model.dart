import 'package:json_annotation/json_annotation.dart';
import 'package:task_flow/core/constants/app_constants.dart';
import 'package:task_flow/features/users/domain/entities/org_member.dart';

part 'org_member_model.g.dart';

/// Mirrors a row of the `org_members` table — `{ org_id, user_id, role }` —
/// with the matching `users` row joined in.
///
/// The table has no `id` column, so none is modelled. `name`, `email` and
/// `avatarUrl` come from the join and are excluded from JSON in both directions
/// to keep the serialized shape identical to the source table.
@JsonSerializable()
class OrgMemberModel {
  @JsonKey(name: 'org_id')
  final String orgId;
  @JsonKey(name: 'user_id')
  final String userId;
  @JsonKey(defaultValue: AppConstants.roleMember)
  final String role;

  @JsonKey(includeFromJson: false, includeToJson: false)
  final String name;
  @JsonKey(includeFromJson: false, includeToJson: false)
  final String email;
  @JsonKey(includeFromJson: false, includeToJson: false)
  final String? avatarUrl;

  const OrgMemberModel({
    required this.orgId,
    required this.userId,
    required this.role,
    this.name = '',
    this.email = '',
    this.avatarUrl,
  });

  factory OrgMemberModel.fromJson(Map<String, dynamic> json) =>
      _$OrgMemberModelFromJson(json);

  Map<String, dynamic> toJson() => _$OrgMemberModelToJson(this);

  /// Returns a copy with the user's profile joined in from the `users` table.
  OrgMemberModel withProfile({
    required String name,
    required String email,
    String? avatarUrl,
  }) {
    return OrgMemberModel(
      orgId: orgId,
      userId: userId,
      role: role,
      name: name,
      email: email,
      avatarUrl: avatarUrl,
    );
  }

  OrgMember toEntity() {
    return OrgMember(
      orgId: orgId,
      userId: userId,
      role: role,
      name: name,
      email: email,
      avatarUrl: avatarUrl,
    );
  }

  factory OrgMemberModel.fromEntity(OrgMember member) {
    return OrgMemberModel(
      orgId: member.orgId,
      userId: member.userId,
      role: member.role,
      name: member.name,
      email: member.email,
      avatarUrl: member.avatarUrl,
    );
  }
}
