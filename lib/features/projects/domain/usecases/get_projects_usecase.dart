import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:task_flow/core/error/failures.dart';
import 'package:task_flow/core/usecase/usecase.dart';
import 'package:task_flow/core/utils/cached.dart';
import 'package:task_flow/core/utils/either_extensions.dart';
import 'package:task_flow/features/auth/domain/services/authorization_service.dart';
import 'package:task_flow/features/projects/domain/entities/project.dart';
import 'package:task_flow/features/projects/domain/repositories/project_repository.dart';

class GetProjectsParams extends Equatable {
  final String orgId;
  const GetProjectsParams({required this.orgId});

  @override
  List<Object> get props => [orgId];
}

/// Lists the projects of an organization the caller actually belongs to.
class GetProjectsUseCase
    extends UseCase<Cached<List<Project>>, GetProjectsParams> {
  final ProjectRepository repository;
  final AuthorizationService authorization;

  GetProjectsUseCase(this.repository, {required this.authorization});

  @override
  Future<Either<Failure, Cached<List<Project>>>> call(
    GetProjectsParams params,
  ) async {
    final access = await authorization.requireMemberOf(params.orgId);
    return access.flatMapAsync((_) => repository.getProjects(orgId: params.orgId));
  }
}
