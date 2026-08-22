import 'package:dartz/dartz.dart';
import 'package:task_flow/core/error/failures.dart';
import 'package:task_flow/core/usecase/usecase.dart';
import 'package:task_flow/features/notifications/domain/entities/notification_entity.dart';
import 'package:task_flow/features/notifications/domain/repositories/notification_repository.dart';

class MarkNotificationReadUseCase extends UseCase<NotificationEntity, String> {
  final NotificationRepository repository;

  MarkNotificationReadUseCase(this.repository);

  @override
  Future<Either<Failure, NotificationEntity>> call(String notificationId) {
    return repository.markAsRead(notificationId);
  }
}
