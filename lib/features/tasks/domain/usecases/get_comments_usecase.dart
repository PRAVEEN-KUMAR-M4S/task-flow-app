import 'package:dartz/dartz.dart';
import 'package:task_flow/core/error/failures.dart';
import 'package:task_flow/core/usecase/usecase.dart';
import 'package:task_flow/features/tasks/domain/entities/task_comment.dart';
import 'package:task_flow/features/tasks/domain/repositories/task_repository.dart';

class GetCommentsUseCase extends UseCase<List<TaskComment>, String> {
  final TaskRepository repository;

  GetCommentsUseCase(this.repository);

  @override
  Future<Either<Failure, List<TaskComment>>> call(String taskId) async {
    return repository.getComments(taskId);
  }
}
