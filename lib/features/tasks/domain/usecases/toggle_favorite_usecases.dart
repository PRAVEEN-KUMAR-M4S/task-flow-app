import 'package:dartz/dartz.dart';
import 'package:task_flow/core/error/failures.dart';
import 'package:task_flow/features/tasks/domain/entities/task_entity.dart';
import 'package:task_flow/features/tasks/domain/repositories/task_repository.dart';

class ToggleFavoriteUsecases {
  final TaskRepository taskRepository;

  ToggleFavoriteUsecases({required this.taskRepository});

  Future<Either<Failure, TaskEntity>> call({required String taskId}) {
    return taskRepository.toggleFavorite(taskId: taskId);
  }
}
