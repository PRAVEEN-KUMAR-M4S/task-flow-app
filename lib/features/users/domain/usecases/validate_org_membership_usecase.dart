import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:task_flow/core/error/failures.dart';
import 'package:task_flow/core/usecase/usecase.dart';
import 'package:task_flow/features/users/domain/repositories/user_repository.dart';

class ValidateOrgMembershipParams extends Equatable {
  final String userId;
  final String orgId;

  const ValidateOrgMembershipParams({required this.userId, required this.orgId});

  @override
  List<Object> get props => [userId, orgId];
}

class ValidateOrgMembershipUseCase extends UseCase<bool, ValidateOrgMembershipParams> {
  final UserRepository repository;

  ValidateOrgMembershipUseCase(this.repository);

  @override
  Future<Either<Failure, bool>> call(ValidateOrgMembershipParams params) {
    return repository.validateOrgMembership(params.userId, params.orgId);
  }
}
