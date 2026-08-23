import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:task_flow/core/error/failure_mapper.dart';
import 'package:task_flow/core/error/failures.dart';
import 'package:task_flow/core/network/connectivity_cubit.dart';
import 'package:task_flow/core/utils/cached.dart';
import 'package:task_flow/features/projects/data/datasources/project_local_datasource.dart';
import 'package:task_flow/features/projects/domain/entities/project.dart';
import 'package:task_flow/features/projects/domain/repositories/project_repository.dart';

class ProjectRepositoryImpl implements ProjectRepository {
  final ProjectLocalDatasource _datasource;
  final ConnectivityCubit _connectivity;

  ProjectRepositoryImpl({
    required ProjectLocalDatasource datasource,
    required ConnectivityCubit connectivity,
  })  : _datasource = datasource,
        _connectivity = connectivity;

  bool get _isOffline => _connectivity.state.isOffline;

  // ─── Reads ──────────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, Cached<List<Project>>>> getProjects({
    required String orgId,
  }) async {
    debugPrint('[ProjectRepo] 📖 getProjects(orgId=$orgId) isOffline=$_isOffline');
    if (_isOffline) {
      debugPrint('[ProjectRepo] 📴 Reading from Hive cache (offline)');
      final cached = _datasource.getCachedProjects(orgId);
      if (cached != null) return Right(Cached.stale(cached));
      return const Left(
        NetworkFailure(
          message: 'You are offline and no projects have been saved yet.',
        ),
      );
    }
    try {
      debugPrint('[ProjectRepo] 📡 Reading from MockDatabase (online)');
      return Right(Cached.fresh(await _datasource.getProjects(orgId: orgId)));
    } catch (error) {
      debugPrint('[ProjectRepo] ❌ Live read failed: $error');
      // A live read that fails still beats an empty screen if we have a copy.
      final cached = _datasource.getCachedProjects(orgId);
      if (cached != null) return Right(Cached.stale(cached));
      return Left(mapExceptionToFailure(error));
    }
  }

  @override
  Future<Either<Failure, Cached<Project>>> getProjectById(String id) async {
    if (_isOffline) {
      final cached = _datasource.getCachedProject(id);
      if (cached != null) return Right(Cached.stale(cached));
      return const Left(
        NetworkFailure(
          message: 'You are offline and this project has not been saved.',
        ),
      );
    }
    try {
      return Right(Cached.fresh(await _datasource.getProjectById(id)));
    } catch (error) {
      return Left(mapExceptionToFailure(error));
    }
  }

  // ─── Writes ─────────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, Project>> createProject({
    required String orgId,
    required String name,
    required String description,
    required String createdBy,
  }) async {
    debugPrint('[ProjectRepo] ✏️ createProject(name=$name, orgId=$orgId) isOffline=$_isOffline');
    if (_isOffline) return Left(_offlineWrite('create a project'));
    try {
      final result = await _datasource.createProject(
        orgId: orgId,
        name: name,
        description: description,
        createdBy: createdBy,
      );
      debugPrint('[ProjectRepo] ✅ createProject success: ${result.id}');
      return Right(result);
    } catch (error) {
      debugPrint('[ProjectRepo] ❌ createProject failed: $error');
      return Left(mapExceptionToFailure(error));
    }
  }

  @override
  Future<Either<Failure, Project>> updateProject({
    required String id,
    required String name,
    required String description,
    required String status,
  }) async {
    if (_isOffline) return Left(_offlineWrite('update a project'));
    try {
      return Right(
        await _datasource.updateProject(
          id: id,
          name: name,
          description: description,
          status: status,
        ),
      );
    } catch (error) {
      return Left(mapExceptionToFailure(error));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteProject(String id) async {
    if (_isOffline) return Left(_offlineWrite('delete a project'));
    try {
      await _datasource.deleteProject(id);
      return const Right(unit);
    } catch (error) {
      return Left(mapExceptionToFailure(error));
    }
  }

  /// Writes are rejected offline rather than queued — there is no server to
  /// reconcile against, so a queue would only create phantom state.
  NetworkFailure _offlineWrite(String action) =>
      NetworkFailure(message: 'You need to be online to $action.');
}
