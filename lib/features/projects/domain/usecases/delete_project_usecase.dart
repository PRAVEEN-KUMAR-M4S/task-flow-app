import 'package:dartz/dartz.dart';
import 'package:task_flow/core/error/failures.dart';
import 'package:task_flow/core/usecase/usecase.dart';
import 'package:task_flow/core/utils/either_extensions.dart';
import 'package:task_flow/features/auth/domain/services/authorization_service.dart';
import 'package:task_flow/features/projects/domain/repositories/project_repository.dart';

/// Deletes a project. Admin-only, and only within the caller's organization.
class DeleteProjectUseCase extends UseCase<Unit, String> {
  final ProjectRepository repository;
  final AuthorizationService authorization;

  DeleteProjectUseCase(this.repository, {required this.authorization});

  @override
  Future<Either<Failure, Unit>> call(String projectId) async {
    final access = await authorization.requireAdmin(action: 'delete projects');

    return access.flatMapAsync((admin) async {
      final existing = await repository.getProjectById(projectId);
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
        return repository.deleteProject(projectId);
      });
    });
  }
}
