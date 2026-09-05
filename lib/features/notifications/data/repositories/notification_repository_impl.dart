import 'package:dartz/dartz.dart';
import 'package:task_flow/core/error/failure_mapper.dart';
import 'package:task_flow/core/error/failures.dart';
import 'package:task_flow/core/network/network_info.dart';
import 'package:task_flow/core/utils/cached.dart';
import 'package:task_flow/features/notifications/data/datasources/notification_local_datasource.dart';
import 'package:task_flow/features/notifications/domain/entities/notification_entity.dart';
import 'package:task_flow/features/notifications/domain/repositories/notification_repository.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  final NotificationLocalDatasource datasource;
  final NetworkInfo _networkInfo;

  NotificationRepositoryImpl({
    required this.datasource,
    required NetworkInfo networkInfo,
  }) : _networkInfo = networkInfo;

  Future<bool> get _isOffline async => !await _networkInfo.isConnected;

  @override
  Future<Either<Failure, Cached<List<NotificationEntity>>>> getNotifications(
    String userId,
  ) async {
    if (await _isOffline) {
      final cached = datasource.getCachedNotifications(userId);
      if (cached != null) return Right(Cached.stale(cached));
      return const Left(
        NetworkFailure(
          message: 'You are offline and no notifications have been saved yet.',
        ),
      );
    }
    try {
      return Right(Cached.fresh(await datasource.getNotifications(userId)));
    } catch (error) {
      final cached = datasource.getCachedNotifications(userId);
      if (cached != null) return Right(Cached.stale(cached));
      return Left(mapExceptionToFailure(error));
    }
  }

  @override
  Future<Either<Failure, NotificationEntity>> markAsRead(
    String notificationId,
  ) async {
    if (await _isOffline) return Left(_offlineWrite());
    try {
      return Right(await datasource.markAsRead(notificationId));
    } catch (error) {
      return Left(mapExceptionToFailure(error));
    }
  }

  @override
  Future<Either<Failure, Unit>> markAllAsRead(String userId) async {
    if (await _isOffline) return Left(_offlineWrite());
    try {
      await datasource.markAllAsRead(userId);
      return const Right(unit);
    } catch (error) {
      return Left(mapExceptionToFailure(error));
    }
  }

  NetworkFailure _offlineWrite() => const NetworkFailure(
        message: 'You need to be online to update notifications.',
      );
}
