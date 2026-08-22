import 'package:dartz/dartz.dart';
import 'package:task_flow/core/error/failures.dart';
import 'package:task_flow/core/usecase/usecase.dart';
import 'package:task_flow/features/users/domain/entities/org_member.dart';
import 'package:task_flow/features/users/domain/repositories/user_repository.dart';

class GetOrgMembersUseCase extends UseCase<List<OrgMember>, String> {
  final UserRepository repository;

  GetOrgMembersUseCase(this.repository);

  @override
  Future<Either<Failure, List<OrgMember>>> call(String orgId) {
    return repository.getOrgMembers(orgId);
  }
}
