import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:task_flow/core/error/failures.dart';
import 'package:task_flow/core/usecase/usecase.dart';
import 'package:task_flow/features/tasks/domain/entities/task_entity.dart';
import 'package:task_flow/features/tasks/domain/repositories/task_repository.dart';
import 'package:task_flow/features/users/domain/repositories/user_repository.dart';

class UpdateTaskParams extends Equatable {
  final String taskId;
  final String title;
  final String description;
  final String priority;
  final String status;
  final String? assigneeId;
  final String? orgId;
  final DateTime? dueDate;
  final List<String> tags;

  const UpdateTaskParams({
    required this.taskId,
    required this.title,
    required this.description,
    required this.priority,
    required this.status,
    this.assigneeId,
    this.orgId,
    this.dueDate,
    this.tags = const [],
  });

  @override
  List<Object?> get props => [
        taskId,
        title,
        description,
        priority,
        status,
        assigneeId,
        orgId,
        dueDate,
        tags,
      ];
}

class UpdateTaskUseCase extends UseCase<TaskEntity, UpdateTaskParams> {
  final TaskRepository repository;
  final UserRepository userRepository;

  UpdateTaskUseCase({required this.repository, required this.userRepository});

  @override
  Future<Either<Failure, TaskEntity>> call(UpdateTaskParams params) async {
    // Validate org membership if assigning a user (same as AssignTaskUseCase)
    if (params.assigneeId != null && params.orgId != null) {
      final isMemberResult = await userRepository.validateOrgMembership(
        params.assigneeId!,
        params.orgId!,
      );
      final validationResult = isMemberResult.flatMap((isMember) {
        if (!isMember) {
          return const Left(ValidationFailure(
            message: 'Cannot assign task: User does not belong to this organization.',
          ));
        }
        return const Right(true);
      });
      if (validationResult.isLeft()) {
        return Left(validationResult.fold((l) => l, (r) => throw Exception()));
      }
    }

    return repository.updateTask(
      taskId: params.taskId,
      title: params.title,
      description: params.description,
      priority: params.priority,
      status: params.status,
      assigneeId: params.assigneeId,
      dueDate: params.dueDate,
      tags: params.tags,
    );
  }
}
