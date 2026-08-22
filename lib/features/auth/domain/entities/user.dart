import 'package:equatable/equatable.dart';
import 'package:task_flow/core/constants/app_constants.dart';

/// Domain entity representing an authenticated user with their org membership.
///
/// `orgId`, `orgName` and `role` are joined in from `org_members` /
/// `organizations` at login — the `users` table itself carries no org data.
class User extends Equatable {
  final String id;
  final String name;
  final String email;
  final String? avatarUrl;
  final String orgId;
  final String orgName;
  final String role; // 'org_admin' | 'member'

  const User({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl,
    required this.orgId,
    required this.orgName,
    required this.role,
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

  User copyWith({
    String? id,
    String? name,
    String? email,
    String? avatarUrl,
    String? orgId,
    String? orgName,
    String? role,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      orgId: orgId ?? this.orgId,
      orgName: orgName ?? this.orgName,
      role: role ?? this.role,
    );
  }

  @override
  List<Object?> get props => [id, name, email, avatarUrl, orgId, orgName, role];
}
