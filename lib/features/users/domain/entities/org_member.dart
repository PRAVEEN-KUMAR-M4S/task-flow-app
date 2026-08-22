import 'package:equatable/equatable.dart';
import 'package:task_flow/core/constants/app_constants.dart';

/// A user's membership of an organization, with the user's profile joined in.
///
/// The `org_members` table has no surrogate key — (`orgId`, `userId`) is the
/// natural one — so this entity intentionally has no `id` field.
class OrgMember extends Equatable {
  final String orgId;
  final String userId;
  final String role; // 'org_admin' | 'member'
  final String name;
  final String email;
  final String? avatarUrl;

  const OrgMember({
    required this.orgId,
    required this.userId,
    required this.role,
    required this.name,
    required this.email,
    this.avatarUrl,
  });

  bool get isAdmin => role == AppConstants.roleOrgAdmin;

  String get roleLabel => isAdmin ? 'Org Admin' : 'Member';

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'))
      ..removeWhere((part) => part.isEmpty);
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts[1][0]}'.toUpperCase();
    }
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '?';
  }

  @override
  List<Object?> get props => [orgId, userId, role, name, email, avatarUrl];
}
