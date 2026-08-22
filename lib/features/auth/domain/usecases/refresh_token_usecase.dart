import 'package:dartz/dartz.dart';
import 'package:task_flow/core/error/failures.dart';
import 'package:task_flow/core/usecase/usecase.dart';
import 'package:task_flow/features/auth/domain/entities/auth_token.dart';
import 'package:task_flow/features/auth/domain/repositories/auth_repository.dart';

class RefreshTokenUseCase extends UseCase<AuthToken, NoParams> {
  final AuthRepository repository;

  RefreshTokenUseCase(this.repository);

  @override
  Future<Either<Failure, AuthToken>> call(NoParams params) {
    return repository.refreshToken();
  }
}
