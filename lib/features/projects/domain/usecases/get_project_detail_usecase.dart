import 'package:dartz/dartz.dart';
import 'package:task_flow/core/error/failures.dart';
import 'package:task_flow/core/usecase/usecase.dart';
import 'package:task_flow/core/utils/cached.dart';
import 'package:task_flow/core/utils/either_extensions.dart';
import 'package:task_flow/features/auth/domain/services/authorization_service.dart';
import 'package:task_flow/features/projects/domain/entities/project.dart';
import 'package:task_flow/features/projects/domain/repositories/project_repository.dart';

/// Loads one project, refusing projects outside the caller's organization —
/// otherwise a deep link to another org's project id would leak its contents.
class GetProjectDetailUseCase extends UseCase<Cached<Project>, String> {
  final ProjectRepository repository;
  final AuthorizationService authorization;

  GetProjectDetailUseCase(this.repository, {required this.authorization});

  @override
  Future<Either<Failure, Cached<Project>>> call(String projectId) async {
    final session = await authorization.currentUser();

    return session.flatMapAsync((user) async {
      final result = await repository.getProjectById(projectId);
      return result.flatMap((cached) {
        if (cached.data.orgId != user.orgId) {
          return const Left(
            UnauthorizedFailure(
              message: 'This project belongs to another organization.',
            ),
          );
        }
        return Right(cached);
      });
    });
  }
}
