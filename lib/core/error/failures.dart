import 'package:equatable/equatable.dart';

/// Base class for all failures in the app.
/// Every repository returns [Either<Failure, T>].
abstract class Failure extends Equatable {
  final String message;
  final String? code;

  const Failure({required this.message, this.code});

  @override
  List<Object?> get props => [message, code];
}

// ─── Concrete Failures ──────────────────────────────────────────────────────

/// Returned when the server returns a non-2xx response.
class ServerFailure extends Failure {
  const ServerFailure({super.message = 'An unexpected server error occurred.', super.code});
}

/// Returned when no network connectivity is available.
class NetworkFailure extends Failure {
  const NetworkFailure({super.message = 'No internet connection. Please check your network settings.', super.code});
}

/// Returned when a requested resource is not found (simulated 404).
class NotFoundFailure extends Failure {
  const NotFoundFailure({super.message = 'The requested resource was not found.', super.code = '404'});
}

/// Returned when a network request times out (simulated timeout).
class TimeoutFailure extends Failure {
  const TimeoutFailure({super.message = 'The request timed out. Please try again.', super.code = 'TIMEOUT'});
}

/// Returned when user input fails server-side validation.
class ValidationFailure extends Failure {
  const ValidationFailure({required super.message, super.code = 'VALIDATION'});
}

/// Returned when the user is not authenticated or the session has expired.
class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure({super.message = 'You are not authorized to perform this action.', super.code = '401'});
}

/// Returned when reading or writing to local cache fails.
class CacheFailure extends Failure {
  const CacheFailure({super.message = 'Failed to read or write local data.', super.code});
}

/// Returned when invalid credentials are provided during login.
class InvalidCredentialsFailure extends Failure {
  const InvalidCredentialsFailure({super.message = 'Invalid email or password. Please try again.', super.code = 'INVALID_CREDENTIALS'});
}
