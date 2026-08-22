import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:task_flow/features/auth/presentation/cubit/session_cubit.dart';
import 'package:task_flow/features/notifications/presentation/cubit/notification_cubit.dart';
import 'package:task_flow/features/notifications/presentation/widgets/notification_tile.dart';
import 'package:task_flow/shared/widgets/empty_view.dart';
import 'package:task_flow/shared/widgets/error_view.dart';
import 'package:task_flow/shared/widgets/loading_view.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.read<SessionCubit>().currentUser;
    if (user != null) {
      context.read<NotificationCubit>().loadNotifications(user.id);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inbox'),
        actions: [
          BlocBuilder<NotificationCubit, NotificationState>(
            builder: (context, state) {
              if (state is NotificationSuccess && state.unreadCount > 0) {
                return TextButton(
                  onPressed: () => context.read<NotificationCubit>().markAllAsRead(),
                  child: const Text('Mark all as read'),
                );
              }
              return const SizedBox();
            },
          ),
        ],
      ),
      body: BlocBuilder<NotificationCubit, NotificationState>(
        builder: (context, state) {
          if (state is NotificationLoading) {
            return const LoadingView();
          }
          if (state is NotificationError) {
            return ErrorView(
              message: state.failure.message,
              onRetry: () {
                if (user != null) {
                  context.read<NotificationCubit>().loadNotifications(user.id);
                }
              },
            );
          }
          if (state is NotificationEmpty) {
            return const EmptyView(
              icon: Icons.notifications_none_rounded,
              title: 'Your inbox is clear',
              subtitle: 'When tasks get assigned or updated, you will receive notifications here.',
            );
          }
          if (state is NotificationSuccess) {
            final notifs = state.notifications;
            return RefreshIndicator(
              onRefresh: () async {
                if (user != null) {
                  await context.read<NotificationCubit>().loadNotifications(user.id);
                }
              },
              child: ListView.separated(
                itemCount: notifs.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final notif = notifs[index];
                  return NotificationTile(
                    notification: notif,
                    onTap: () {
                      context.read<NotificationCubit>().markAsRead(notif.id);
                      if (notif.taskId != null) {
                        context.push('/tasks/${notif.taskId}');
                      }
                    },
                  );
                },
              ),
            );
          }
          return const SizedBox();
        },
      ),
    );
  }
}
