import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:task_flow/core/constants/app_constants.dart';
import 'package:task_flow/core/error/failures.dart';
import 'package:task_flow/core/usecase/usecase.dart';
import 'package:task_flow/core/utils/either_extensions.dart';
import 'package:task_flow/features/auth/domain/services/authorization_service.dart';
import 'package:task_flow/features/projects/domain/entities/project.dart';
import 'package:task_flow/features/projects/domain/repositories/project_repository.dart';

class UpdateProjectParams extends Equatable {
  final String id;
  final String name;
  final String description;
  final String status;

  const UpdateProjectParams({
    required this.id,
    required this.name,
    required this.description,
    required this.status,
  });

  @override
  List<Object> get props => [id, name, description, status];
}

/// Edits a project. Admin-only, and only within the caller's organization.
class UpdateProjectUseCase extends UseCase<Project, UpdateProjectParams> {
  final ProjectRepository repository;
  final AuthorizationService authorization;

  UpdateProjectUseCase(this.repository, {required this.authorization});

  @override
  Future<Either<Failure, Project>> call(UpdateProjectParams params) async {
    if (params.name.trim().isEmpty) {
      return const Left(
        ValidationFailure(message: 'Project name is required.'),
      );
    }
    if (!AppConstants.projectStatuses.contains(params.status)) {
      return Left(
        ValidationFailure(message: 'Unknown project status "${params.status}".'),
      );
    }

    final access = await authorization.requireAdmin(action: 'edit projects');

    return access.flatMapAsync((admin) async {
      // Re-read the project to confirm it is inside the admin's own org.
      final existing = await repository.getProjectById(params.id);
      return existing.flatMapAsync((cached) {
        if (cached.data.orgId != admin.orgId) {
          return Future.value(
            const Left(
              UnauthorizedFailure(
                message: 'This project belongs to another organization.',
              ),
            ),
          );
        }
        return repository.updateProject(
          id: params.id,
          name: params.name,
          description: params.description,
          status: params.status,
        );
      });
    });
  }
}
