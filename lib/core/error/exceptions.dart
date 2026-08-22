/// Raw exceptions thrown by data sources.
/// Repositories catch these and map them to [Failure] objects.

class ServerException implements Exception {
  final String message;
  const ServerException({this.message = 'Server error'});

  @override
  String toString() => 'ServerException: $message';
}

class NetworkException implements Exception {
  final String message;
  const NetworkException({this.message = 'Network error'});

  @override
  String toString() => 'NetworkException: $message';
}

class NotFoundException implements Exception {
  final String message;
  const NotFoundException({this.message = 'Not found'});

  @override
  String toString() => 'NotFoundException: $message';
}

class TimeoutException implements Exception {
  final String message;
  const TimeoutException({this.message = 'Request timed out'});

  @override
  String toString() => 'TimeoutException: $message';
}

class ValidationException implements Exception {
  final String message;
  const ValidationException({this.message = 'Validation failed'});

  @override
  String toString() => 'ValidationException: $message';
}

class UnauthorizedException implements Exception {
  final String message;
  const UnauthorizedException({this.message = 'Unauthorized'});

  @override
  String toString() => 'UnauthorizedException: $message';
}

class CacheException implements Exception {
  final String message;
  const CacheException({this.message = 'Cache error'});

  @override
  String toString() => 'CacheException: $message';
}

class InvalidCredentialsException implements Exception {
  final String message;
  const InvalidCredentialsException({this.message = 'Invalid credentials'});

  @override
  String toString() => 'InvalidCredentialsException: $message';
}
