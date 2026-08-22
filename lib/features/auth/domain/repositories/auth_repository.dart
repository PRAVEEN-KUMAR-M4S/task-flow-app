import 'package:dartz/dartz.dart';
import 'package:task_flow/core/error/failures.dart';
import 'package:task_flow/features/auth/domain/entities/auth_token.dart';
import 'package:task_flow/features/auth/domain/entities/test_credential.dart';
import 'package:task_flow/features/auth/domain/entities/user.dart';

/// Abstract repository interface for authentication.
/// The data layer implements this — swappable for a real HTTP backend.
abstract class AuthRepository {
  /// Validates credentials and returns the authenticated [User].
  Future<Either<Failure, User>> login({
    required String email,
    required String password,
  });

  /// Clears the session and any stored tokens.
  Future<Either<Failure, Unit>> logout();

  /// Exchanges a refresh token for a new [AuthToken].
  Future<Either<Failure, AuthToken>> refreshToken();

  /// Returns the cached [User] if a valid session exists, otherwise `null`.
  Future<Either<Failure, User?>> getCachedUser();

  /// When the current access token expires, or `null` if there is no session.
  Future<DateTime?> getSessionExpiry();

  /// Demo logins shipped with the mock data.
  ///
  /// Loaded through the data layer on purpose — the assignment forbids
  /// hard-coding the mock credentials inside UI widgets.
  Future<Either<Failure, List<TestCredential>>> getTestCredentials();
}
