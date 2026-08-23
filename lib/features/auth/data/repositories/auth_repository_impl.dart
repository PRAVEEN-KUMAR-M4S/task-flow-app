import 'package:dartz/dartz.dart';
import 'package:task_flow/core/error/failure_mapper.dart';
import 'package:task_flow/core/error/failures.dart';
import 'package:task_flow/core/storage/secure_storage_service.dart';
import 'package:task_flow/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:task_flow/features/auth/domain/entities/auth_token.dart';
import 'package:task_flow/features/auth/domain/entities/test_credential.dart';
import 'package:task_flow/features/auth/domain/entities/user.dart';
import 'package:task_flow/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthLocalDatasource _datasource;
  final SecureStorageService _secureStorage;

  AuthRepositoryImpl({
    required AuthLocalDatasource datasource,
    required SecureStorageService secureStorage,
  })  : _datasource = datasource,
        _secureStorage = secureStorage;

  @override
  Future<Either<Failure, User>> login({
    required String email,
    required String password,
  }) async {
    try {
      final result = await _datasource.login(email: email, password: password);
      final user = result.user.toEntity();
      final token = result.token.toEntity();

      // Tokens live only in secure storage; nothing else persists them and
      // AuthToken.toString() deliberately omits them.
      await _secureStorage.saveSession(
        accessToken: token.accessToken,
        refreshToken: token.refreshToken,
        userId: user.id,
        orgId: user.orgId,
        expiresAt: token.expiresAt,
      );

      return Right(user);
    } catch (error) {
      return Left(mapExceptionToFailure(error));
    }
  }

  @override
  Future<Either<Failure, Unit>> logout() async {
    try {
      await _secureStorage.clearSession();
      return const Right(unit);
    } catch (error) {
      return Left(mapExceptionToFailure(error));
    }
  }

  @override
  Future<Either<Failure, AuthToken>> refreshToken() async {
    try {
      final stored = await _secureStorage.getRefreshToken();
      if (stored == null) {
        return const Left(
          UnauthorizedFailure(message: 'Your session has expired.'),
        );
      }

      final model = await _datasource.refreshToken(stored);
      final token = model.toEntity();

      await _secureStorage.updateAccessToken(
        accessToken: token.accessToken,
        expiresAt: token.expiresAt,
        refreshToken: token.refreshToken,
      );

      return Right(token);
    } catch (error) {
      return Left(mapExceptionToFailure(error));
    }
  }

  @override
  Future<Either<Failure, User?>> getCachedUser() async {
    try {
      final model = await _datasource.getCachedUser();
      return Right(model?.toEntity());
    } catch (error) {
      return Left(mapExceptionToFailure(error));
    }
  }

  @override
  Future<DateTime?> getSessionExpiry() => _secureStorage.getTokenExpiry();

  @override
  Future<Either<Failure, List<TestCredential>>> getTestCredentials() async {
    try {
      final models = await _datasource.getTestCredentials();
      return Right(models.map((model) => model.toEntity()).toList());
    } catch (error) {
      return Left(mapExceptionToFailure(error));
    }
  }
}
