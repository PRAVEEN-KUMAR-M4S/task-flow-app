import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:task_flow/core/error/failures.dart';
import 'package:task_flow/core/usecase/usecase.dart';
import 'package:task_flow/core/utils/either_extensions.dart';
import 'package:task_flow/features/auth/domain/services/authorization_service.dart';
import 'package:task_flow/features/projects/domain/entities/project.dart';
import 'package:task_flow/features/projects/domain/repositories/project_repository.dart';

class CreateProjectParams extends Equatable {
  final String name;
  final String description;

  const CreateProjectParams({required this.name, required this.description});

  @override
  List<Object> get props => [name, description];
}

/// Creates a project in the caller's own organization.
///
/// The org, the author and the admin check all come from the stored session,
/// not from parameters — the caller cannot nominate a different org or claim
/// admin rights it does not have.
class CreateProjectUseCase extends UseCase<Project, CreateProjectParams> {
  final ProjectRepository repository;
  final AuthorizationService authorization;

  CreateProjectUseCase(this.repository, {required this.authorization});

  @override
  Future<Either<Failure, Project>> call(CreateProjectParams params) async {
    if (params.name.trim().isEmpty) {
      return const Left(
        ValidationFailure(message: 'Project name is required.'),
      );
    }

    final access = await authorization.requireAdmin(action: 'create projects');
    return access.flatMapAsync(
      (admin) => repository.createProject(
        orgId: admin.orgId,
        name: params.name,
        description: params.description,
        createdBy: admin.id,
      ),
    );
  }
}
