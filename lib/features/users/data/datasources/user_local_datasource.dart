import 'package:task_flow/core/mock/error_simulator.dart';
import 'package:task_flow/core/mock/mock_database.dart';
import 'package:task_flow/core/network/mock_datasource_mixin.dart';
import 'package:task_flow/features/users/data/models/org_member_model.dart';
import 'package:task_flow/features/users/domain/entities/org_member.dart';

// ─── Abstract ─────────────────────────────────────────────────────────────────

abstract class UserLocalDatasource {
  /// Members of [orgId], with their profile joined in from `users`.
  Future<List<OrgMember>> getOrgMembers(String orgId);

  /// Whether [userId] belongs to [orgId]. Used to authorize assignment.
  Future<bool> validateOrgMembership(String userId, String orgId);

  /// The membership role of [userId] in [orgId], or `null` if not a member.
  Future<String?> getRole({required String userId, required String orgId});
}

// ─── Implementation ───────────────────────────────────────────────────────────

class UserLocalDatasourceImpl
    with MockDatasourceMixin
    implements UserLocalDatasource {
  final MockDatabase _db;

  @override
  final ErrorSimulator errorSimulator;

  UserLocalDatasourceImpl({
    required MockDatabase database,
    required this.errorSimulator,
  }) : _db = database;

  @override
  Future<List<OrgMember>> getOrgMembers(String orgId) async {
    await _db.ensureLoaded();
    await simulatedDelay();
    checkForSimulatedError(orgId);

    final members = <OrgMember>[];
    // `org_members` has no `id` column — the composite (org_id, user_id) is the
    // key, so nothing may read `member['id']`.
    for (final row in _db.membersOf(orgId)) {
      final user = _db.users[row['user_id']];
      if (user == null) continue; // membership pointing at a deleted user
      members.add(
        OrgMemberModel.fromJson(row)
            .withProfile(
              name: (user['name'] as String?) ?? '',
              email: (user['email'] as String?) ?? '',
              avatarUrl: user['avatar_url'] as String?,
            )
            .toEntity(),
      );
    }

    // Admins first, then alphabetically — the assignee picker reads better.
    members.sort((a, b) {
      if (a.isAdmin != b.isAdmin) return a.isAdmin ? -1 : 1;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return members;
  }

  @override
  Future<bool> validateOrgMembership(String userId, String orgId) async {
    await _db.ensureLoaded();
    return _db.membership(orgId: orgId, userId: userId) != null;
  }

  @override
  Future<String?> getRole({
    required String userId,
    required String orgId,
  }) async {
    await _db.ensureLoaded();
    return _db.membership(orgId: orgId, userId: userId)?['role'] as String?;
  }
}
