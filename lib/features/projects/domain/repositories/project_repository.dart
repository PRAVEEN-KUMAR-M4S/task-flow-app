import 'package:dartz/dartz.dart';
import 'package:task_flow/core/error/failures.dart';
import 'package:task_flow/core/utils/cached.dart';
import 'package:task_flow/features/projects/domain/entities/project.dart';

/// Abstract repository interface for projects.
/// Implementation detail (mock JSON) is hidden behind this contract.
abstract class ProjectRepository {
  /// Reads may be served from cache while offline — [Cached.isStale] says which.
  Future<Either<Failure, Cached<List<Project>>>> getProjects({
    required String orgId,
  });

  Future<Either<Failure, Cached<Project>>> getProjectById(String id);

  Future<Either<Failure, Project>> createProject({
    required String orgId,
    required String name,
    required String description,
    required String createdBy,
  });

  Future<Either<Failure, Project>> updateProject({
    required String id,
    required String name,
    required String description,
    required String status,
  });

  Future<Either<Failure, Unit>> deleteProject(String id);
}
