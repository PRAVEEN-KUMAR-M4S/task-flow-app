import 'package:dartz/dartz.dart';
import 'package:task_flow/core/error/failures.dart';
import 'package:task_flow/core/usecase/usecase.dart';
import 'package:task_flow/features/notifications/domain/entities/notification_entity.dart';
import 'package:task_flow/features/notifications/domain/repositories/notification_repository.dart';

class GetNotificationsUseCase extends UseCase<List<NotificationEntity>, String> {
  final NotificationRepository repository;

  GetNotificationsUseCase(this.repository);

  @override
  Future<Either<Failure, List<NotificationEntity>>> call(String userId) async {
    final result = await repository.getNotifications(userId);
    return result.fold(
      (failure) => Left(failure),
      (cached) => Right(cached.data),
    );
  }
}
