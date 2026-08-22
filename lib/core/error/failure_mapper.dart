import 'package:task_flow/core/error/exceptions.dart' as ex;
import 'package:task_flow/core/error/failures.dart';

/// Single place that translates data-layer exceptions into domain [Failure]s.
///
/// Every repository funnels through this so a new exception type only has to be
/// mapped once, and so no repository accidentally swallows a specific error into
/// a generic [ServerFailure].
Failure mapExceptionToFailure(Object error) {
  return switch (error) {
    ex.InvalidCredentialsException(:final message) =>
      InvalidCredentialsFailure(message: message),
    ex.UnauthorizedException(:final message) =>
      UnauthorizedFailure(message: message),
    ex.NotFoundException(:final message) => NotFoundFailure(message: message),
    ex.TimeoutException(:final message) => TimeoutFailure(message: message),
    ex.ValidationException(:final message) =>
      ValidationFailure(message: message),
    ex.NetworkException(:final message) => NetworkFailure(message: message),
    ex.CacheException(:final message) => CacheFailure(message: message),
    ex.ServerException(:final message) => ServerFailure(message: message),
    // Anything unmapped is still a server-side problem from the caller's point
    // of view; the raw error is not surfaced to the UI.
    _ => const ServerFailure(),
  };
}
