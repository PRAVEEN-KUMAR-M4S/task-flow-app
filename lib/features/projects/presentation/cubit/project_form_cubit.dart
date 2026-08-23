import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:task_flow/core/error/failures.dart';
import 'package:task_flow/features/projects/domain/usecases/create_project_usecase.dart';
import 'package:task_flow/features/projects/domain/usecases/update_project_usecase.dart';

// ─── States ───────────────────────────────────────────────────────────────────

abstract class ProjectFormState extends Equatable {
  const ProjectFormState();
  @override
  List<Object?> get props => [];
}

class ProjectFormInitial extends ProjectFormState {
  const ProjectFormInitial();
}

class ProjectFormSubmitting extends ProjectFormState {
  const ProjectFormSubmitting();
}

class ProjectFormSuccess extends ProjectFormState {
  const ProjectFormSuccess();
}

class ProjectFormError extends ProjectFormState {
  final Failure failure;
  const ProjectFormError(this.failure);
  @override
  List<Object?> get props => [failure];
}

// ─── Cubit ────────────────────────────────────────────────────────────────────

class ProjectFormCubit extends Cubit<ProjectFormState> {
  final CreateProjectUseCase _createProjectUseCase;
  final UpdateProjectUseCase _updateProjectUseCase;

  ProjectFormCubit({
    required CreateProjectUseCase createProjectUseCase,
    required UpdateProjectUseCase updateProjectUseCase,
  })  : _createProjectUseCase = createProjectUseCase,
        _updateProjectUseCase = updateProjectUseCase,
        super(const ProjectFormInitial());

  /// Reset state before opening a new form — singleton reuse.
  void reset() => emit(const ProjectFormInitial());

  Future<void> createProject({
    required String name,
    required String description,
  }) async {
    emit(const ProjectFormSubmitting());
    final result = await _createProjectUseCase(
      CreateProjectParams(name: name, description: description),
    );
    if (isClosed) return;
    result.fold(
      (failure) => emit(ProjectFormError(failure)),
      (_) => emit(const ProjectFormSuccess()),
    );
  }

  Future<void> updateProject({
    required String id,
    required String name,
    required String description,
    required String status,
  }) async {
    emit(const ProjectFormSubmitting());
    final result = await _updateProjectUseCase(
      UpdateProjectParams(id: id, name: name, description: description, status: status),
    );
    if (isClosed) return;
    result.fold(
      (failure) => emit(ProjectFormError(failure)),
      (_) => emit(const ProjectFormSuccess()),
    );
  }
}
