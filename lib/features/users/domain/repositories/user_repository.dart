import 'package:dartz/dartz.dart';
import 'package:task_flow/core/error/failures.dart';
import 'package:task_flow/features/users/domain/entities/org_member.dart';

abstract class UserRepository {
  Future<Either<Failure, List<OrgMember>>> getOrgMembers(String orgId);

  Future<Either<Failure, bool>> validateOrgMembership(
    String userId,
    String orgId,
  );

  /// The authoritative role of [userId] in [orgId], read from `org_members`.
  /// Used by use cases to authorize admin-only actions without trusting the UI.
  Future<Either<Failure, String?>> getRole({
    required String userId,
    required String orgId,
  });
}
