import 'package:dartz/dartz.dart';
import 'package:task_flow/core/error/failures.dart';
import 'package:task_flow/features/auth/domain/entities/user.dart';
import 'package:task_flow/features/auth/domain/repositories/auth_repository.dart';

/// Resolves *who is acting* and *what they may do*, from the stored session.
///
/// Authorization used to be a `bool isAdmin` handed in by the widget tree and
/// forwarded through `GoRouterState.extra`, which meant a deep link could claim
/// admin rights. Here the role is re-read from the session on every check, and
/// the session's role itself comes from the `org_members` table — so the UI
/// cannot assert a privilege it does not have.
class AuthorizationService {
  final AuthRepository _authRepository;

  AuthorizationService({required AuthRepository authRepository})
      : _authRepository = authRepository;

  /// The signed-in user, or an [UnauthorizedFailure] if the session is gone.
  Future<Either<Failure, User>> currentUser() async {
    final result = await _authRepository.getCachedUser();
    return result.fold(
      Left.new,
      (user) => user == null
          ? const Left(
              UnauthorizedFailure(
                message: 'Your session has expired. Please sign in again.',
              ),
            )
          : Right(user),
    );
  }

  /// Requires an `org_admin` session, optionally scoped to [orgId].
  ///
  /// [action] is interpolated into the failure message, e.g. "delete projects".
  Future<Either<Failure, User>> requireAdmin({
    required String action,
    String? orgId,
  }) async {
    final result = await currentUser();
    return result.flatMap((user) {
      if (orgId != null && user.orgId != orgId) {
        return Left(
          UnauthorizedFailure(
            message: 'You do not have access to this organization.',
          ),
        );
      }
      if (!user.isAdmin) {
        return Left(
          UnauthorizedFailure(
            message: 'Only organization admins can $action.',
          ),
        );
      }
      return Right(user);
    });
  }

  /// Requires any member of [orgId] — the baseline for read access.
  Future<Either<Failure, User>> requireMemberOf(String orgId) async {
    final result = await currentUser();
    return result.flatMap((user) {
      if (user.orgId != orgId) {
        return const Left(
          UnauthorizedFailure(
            message: 'You do not have access to this organization.',
          ),
        );
      }
      return Right(user);
    });
  }
}
