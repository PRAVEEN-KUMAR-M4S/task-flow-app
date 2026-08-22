import 'package:dartz/dartz.dart';
import 'package:task_flow/core/error/failures.dart';
import 'package:task_flow/core/utils/cached.dart';
import 'package:task_flow/features/notifications/domain/entities/notification_entity.dart';

abstract class NotificationRepository {
  /// Reads may be served from cache while offline — [Cached.isStale] says which.
  Future<Either<Failure, Cached<List<NotificationEntity>>>> getNotifications(
    String userId,
  );

  Future<Either<Failure, NotificationEntity>> markAsRead(String notificationId);

  Future<Either<Failure, Unit>> markAllAsRead(String userId);
}
