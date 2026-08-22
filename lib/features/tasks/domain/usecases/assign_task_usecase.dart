import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:task_flow/core/error/failures.dart';
import 'package:task_flow/core/usecase/usecase.dart';
import 'package:task_flow/features/tasks/domain/entities/task_entity.dart';
import 'package:task_flow/features/tasks/domain/repositories/task_repository.dart';
import 'package:task_flow/features/users/domain/repositories/user_repository.dart';

class AssignTaskParams extends Equatable {
  final String taskId;
  final String? assigneeId;
  final String orgId;

  const AssignTaskParams({
    required this.taskId,
    this.assigneeId,
    required this.orgId,
  });

  @override
  List<Object?> get props => [taskId, assigneeId, orgId];
}

class AssignTaskUseCase extends UseCase<TaskEntity, AssignTaskParams> {
  final TaskRepository taskRepository;
  final UserRepository userRepository;

  AssignTaskUseCase({
    required this.taskRepository,
    required this.userRepository,
  });

  @override
  Future<Either<Failure, TaskEntity>> call(AssignTaskParams params) async {
    if (params.assigneeId != null) {
      final isMemberResult = await userRepository.validateOrgMembership(
        params.assigneeId!,
        params.orgId,
      );

      final Either<Failure, bool> validationResult = isMemberResult.flatMap((isMember) {
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

    return taskRepository.assignTask(
      taskId: params.taskId,
      assigneeId: params.assigneeId,
    );
  }
}
