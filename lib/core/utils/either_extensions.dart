import 'package:dartz/dartz.dart';

/// Async companions to dartz's [Either.flatMap].
///
/// Chaining an async step off an `Either` with `fold` forces both branches to
/// have the same type, so the left branch has to be wrapped in a `Future` by
/// hand at every call site. These helpers do that once.
extension EitherAsync<L, R> on Either<L, R> {
  /// Runs [next] only when this is a [Right], short-circuiting the [Left].
  Future<Either<L, T>> flatMapAsync<T>(
    Future<Either<L, T>> Function(R right) next,
  ) =>
      fold((left) async => Left(left), next);

  /// Maps the right side through an async transform, keeping any [Left].
  Future<Either<L, T>> mapAsync<T>(Future<T> Function(R right) next) =>
      fold((left) async => Left(left), (right) async => Right(await next(right)));
}
