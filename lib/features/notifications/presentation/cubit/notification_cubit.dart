import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:task_flow/core/error/failures.dart';
import 'package:task_flow/features/notifications/domain/entities/notification_entity.dart';
import 'package:task_flow/features/notifications/domain/usecases/get_notifications_usecase.dart';
import 'package:task_flow/features/notifications/domain/usecases/mark_notification_read_usecase.dart';
import 'package:task_flow/features/notifications/domain/repositories/notification_repository.dart';

abstract class NotificationState extends Equatable {
  const NotificationState();
  @override
  List<Object?> get props => [];
}

class NotificationInitial extends NotificationState {
  const NotificationInitial();
}

class NotificationLoading extends NotificationState {
  const NotificationLoading();
}

class NotificationSuccess extends NotificationState {
  final List<NotificationEntity> notifications;

  const NotificationSuccess(this.notifications);

  int get unreadCount => notifications.where((n) => !n.isRead).length;

  @override
  List<Object?> get props => [notifications];
}

class NotificationEmpty extends NotificationState {
  const NotificationEmpty();
}

class NotificationError extends NotificationState {
  final Failure failure;
  const NotificationError(this.failure);
  @override
  List<Object?> get props => [failure];
}

class NotificationCubit extends Cubit<NotificationState> {
  final GetNotificationsUseCase _getNotificationsUseCase;
  final MarkNotificationReadUseCase _markNotificationReadUseCase;
  final NotificationRepository _repository; // Inject repo for markAllAsRead directly

  String? _currentUserId;

  NotificationCubit({
    required GetNotificationsUseCase getNotificationsUseCase,
    required MarkNotificationReadUseCase markNotificationReadUseCase,
    required NotificationRepository repository,
  })  : _getNotificationsUseCase = getNotificationsUseCase,
        _markNotificationReadUseCase = markNotificationReadUseCase,
        _repository = repository,
        super(const NotificationInitial());

  Future<void> loadNotifications(String userId) async {
    _currentUserId = userId;
    emit(const NotificationLoading());
    final result = await _getNotificationsUseCase(userId);
    result.fold(
      (failure) => emit(NotificationError(failure)),
      (notifs) {
        if (notifs.isEmpty) {
          emit(const NotificationEmpty());
        } else {
          emit(NotificationSuccess(notifs));
        }
      },
    );
  }

  Future<void> markAsRead(String id) async {
    if (state is! NotificationSuccess) return;
    final current = (state as NotificationSuccess).notifications;

    final result = await _markNotificationReadUseCase(id);
    result.fold(
      (_) => null,
      (updatedNotif) {
        final index = current.indexWhere((n) => n.id == id);
        if (index != -1) {
          final updated = List<NotificationEntity>.from(current);
          updated[index] = updatedNotif;
          emit(NotificationSuccess(updated));
        }
      },
    );
  }

  Future<void> markAllAsRead() async {
    if (_currentUserId == null || state is! NotificationSuccess) return;
    final current = (state as NotificationSuccess).notifications;

    final result = await _repository.markAllAsRead(_currentUserId!);
    result.fold(
      (_) => null,
      (_) {
        final updated = current.map((n) => n.copyWith(isRead: true)).toList();
        emit(NotificationSuccess(updated));
      },
    );
  }

  int get unreadCount {
    if (state is NotificationSuccess) {
      return (state as NotificationSuccess).unreadCount;
    }
    return 0;
  }
}
