import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:task_flow/core/error/failures.dart';
import 'package:task_flow/features/projects/domain/entities/project.dart';
import 'package:task_flow/features/projects/domain/usecases/get_project_detail_usecase.dart';

// ─── States ───────────────────────────────────────────────────────────────────

abstract class ProjectDetailState extends Equatable {
  const ProjectDetailState();
  @override
  List<Object?> get props => [];
}

class ProjectDetailInitial extends ProjectDetailState {
  const ProjectDetailInitial();
}

class ProjectDetailLoading extends ProjectDetailState {
  const ProjectDetailLoading();
}

class ProjectDetailSuccess extends ProjectDetailState {
  final Project project;
  const ProjectDetailSuccess(this.project);
  @override
  List<Object?> get props => [project];
}

class ProjectDetailError extends ProjectDetailState {
  final Failure failure;
  const ProjectDetailError(this.failure);
  @override
  List<Object?> get props => [failure];
}

// ─── Cubit ────────────────────────────────────────────────────────────────────

class ProjectDetailCubit extends Cubit<ProjectDetailState> {
  final GetProjectDetailUseCase _getProjectDetailUseCase;

  ProjectDetailCubit({
    required GetProjectDetailUseCase getProjectDetailUseCase,
  })  : _getProjectDetailUseCase = getProjectDetailUseCase,
        super(const ProjectDetailInitial());

  /// Reset state before opening a new detail screen — singleton reuse.
  void reset() => emit(const ProjectDetailInitial());

  Future<void> loadProject(String id) async {
    emit(const ProjectDetailLoading());
    final result = await _getProjectDetailUseCase(id);
    result.fold(
      (failure) => emit(ProjectDetailError(failure)),
      (cached) => emit(ProjectDetailSuccess(cached.data)),
    );
  }

  Future<void> refresh(String id) => loadProject(id);
}
