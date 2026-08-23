import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:task_flow/core/error/failures.dart';
import 'package:task_flow/features/projects/domain/entities/project.dart';
import 'package:task_flow/features/projects/domain/usecases/create_project_usecase.dart';
import 'package:task_flow/features/projects/domain/usecases/delete_project_usecase.dart';
import 'package:task_flow/features/projects/domain/usecases/get_projects_usecase.dart';
import 'package:task_flow/features/projects/domain/usecases/update_project_usecase.dart';

// ─── States ───────────────────────────────────────────────────────────────────

abstract class ProjectListState extends Equatable {
  const ProjectListState();
  @override
  List<Object?> get props => [];
}

class ProjectListInitial extends ProjectListState {
  const ProjectListInitial();
}

class ProjectListLoading extends ProjectListState {
  const ProjectListLoading();
}

class ProjectListSuccess extends ProjectListState {
  final List<Project> projects;
  final bool isStale;
  const ProjectListSuccess({required this.projects, this.isStale = false});
  @override
  List<Object?> get props => [projects, isStale];
}

class ProjectListEmpty extends ProjectListState {
  const ProjectListEmpty();
}

class ProjectListError extends ProjectListState {
  final Failure failure;
  const ProjectListError(this.failure);
  @override
  List<Object?> get props => [failure];
}

class ProjectMutationLoading extends ProjectListState {
  final List<Project> currentProjects;
  const ProjectMutationLoading(this.currentProjects);
  @override
  List<Object?> get props => [currentProjects];
}

// ─── Cubit ────────────────────────────────────────────────────────────────────

class ProjectListCubit extends Cubit<ProjectListState> {
  final GetProjectsUseCase _getProjectsUseCase;
  final CreateProjectUseCase _createProjectUseCase;
  final UpdateProjectUseCase _updateProjectUseCase;
  final DeleteProjectUseCase _deleteProjectUseCase;

  String? _currentOrgId;

  String? get currentOrgId => _currentOrgId;

  ProjectListCubit({
    required GetProjectsUseCase getProjectsUseCase,
    required CreateProjectUseCase createProjectUseCase,
    required UpdateProjectUseCase updateProjectUseCase,
    required DeleteProjectUseCase deleteProjectUseCase,
  }) : _getProjectsUseCase = getProjectsUseCase,
       _createProjectUseCase = createProjectUseCase,
       _updateProjectUseCase = updateProjectUseCase,
       _deleteProjectUseCase = deleteProjectUseCase,
       super(const ProjectListInitial());

  Future<void> loadProjects({required String orgId}) async {
    _currentOrgId = orgId;
    emit(const ProjectListLoading());
    final result = await _getProjectsUseCase(GetProjectsParams(orgId: orgId));
    result.fold(
      (failure) {
        emit(ProjectListError(failure));
      },
      (cached) {
        final projects = cached.data;
        final isStale = cached.isStale;
        if (projects.isEmpty) {
          emit(const ProjectListEmpty());
        } else {
          emit(ProjectListSuccess(projects: projects, isStale: isStale));
        }
      },
    );
  }

  Future<void> refresh() async {
    if (_currentOrgId == null) return;
    await loadProjects(orgId: _currentOrgId!);
  }

  Future<String?> createProject({
    required String orgId,
    required String name,
    required String description,
  }) async {
    final current = state is ProjectListSuccess
        ? (state as ProjectListSuccess).projects
        : <Project>[];
    emit(ProjectMutationLoading(current));
    final result = await _createProjectUseCase(
      CreateProjectParams(name: name, description: description),
    );
    return result.fold(
      (failure) {
        emit(ProjectListSuccess(projects: current));
        return failure.message;
      },
      (_) {
        loadProjects(orgId: orgId);
        return null;
      },
    );
  }

  Future<String?> updateProject({
    required String id,
    required String name,
    required String description,
    required String status,
  }) async {
    final current = state is ProjectListSuccess
        ? (state as ProjectListSuccess).projects
        : <Project>[];
    emit(ProjectMutationLoading(current));
    final result = await _updateProjectUseCase(
      UpdateProjectParams(
        id: id,
        name: name,
        description: description,
        status: status,
      ),
    );
    return result.fold(
      (failure) {
        emit(ProjectListSuccess(projects: current));
        return failure.message;
      },
      (_) {
        if (_currentOrgId != null) loadProjects(orgId: _currentOrgId!);
        return null;
      },
    );
  }

  Future<String?> deleteProject({required String id}) async {
    final current = state is ProjectListSuccess
        ? (state as ProjectListSuccess).projects
        : <Project>[];
    emit(ProjectMutationLoading(current));
    final result = await _deleteProjectUseCase(id);
    return result.fold(
      (failure) {
        emit(ProjectListSuccess(projects: current));
        return failure.message;
      },
      (_) {
        if (_currentOrgId != null) loadProjects(orgId: _currentOrgId!);
        return null;
      },
    );
  }
}
