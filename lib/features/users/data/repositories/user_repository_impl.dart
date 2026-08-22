import 'package:dartz/dartz.dart';
import 'package:task_flow/core/error/failure_mapper.dart';
import 'package:task_flow/core/error/failures.dart';
import 'package:task_flow/features/users/data/datasources/user_local_datasource.dart';
import 'package:task_flow/features/users/domain/entities/org_member.dart';
import 'package:task_flow/features/users/domain/repositories/user_repository.dart';

class UserRepositoryImpl implements UserRepository {
  final UserLocalDatasource datasource;

  UserRepositoryImpl({required this.datasource});

  @override
  Future<Either<Failure, List<OrgMember>>> getOrgMembers(String orgId) async {
    try {
      return Right(await datasource.getOrgMembers(orgId));
    } catch (error) {
      // `e.toString()` used to leak the exception class into the UI copy.
      return Left(mapExceptionToFailure(error));
    }
  }

  @override
  Future<Either<Failure, bool>> validateOrgMembership(
    String userId,
    String orgId,
  ) async {
    try {
      return Right(await datasource.validateOrgMembership(userId, orgId));
    } catch (error) {
      return Left(mapExceptionToFailure(error));
    }
  }

  @override
  Future<Either<Failure, String?>> getRole({
    required String userId,
    required String orgId,
  }) async {
    try {
      return Right(await datasource.getRole(userId: userId, orgId: orgId));
    } catch (error) {
      return Left(mapExceptionToFailure(error));
    }
  }
}
