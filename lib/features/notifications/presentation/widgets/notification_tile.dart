import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:task_flow/features/notifications/domain/entities/notification_entity.dart';

class NotificationTile extends StatelessWidget {
  final NotificationEntity notification;
  final VoidCallback onTap;

  const NotificationTile({
    super.key,
    required this.notification,
    required this.onTap,
  });

  IconData _getIcon(String type) {
    return switch (type) {
      'task_assigned' => Icons.assignment_ind_rounded,
      'task_status_changed' => Icons.track_changes_rounded,
      'task_comment' => Icons.comment_rounded,
      _ => Icons.notifications_rounded,
    };
  }

  Color _getColor(BuildContext context, String type) {
    final theme = Theme.of(context);
    return switch (type) {
      'task_assigned' => theme.colorScheme.primary,
      'task_status_changed' => theme.colorScheme.secondary,
      'task_comment' => Colors.orange,
      _ => theme.colorScheme.onSurface,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: _getColor(context, notification.type).withOpacity(0.12),
        child: Icon(
          _getIcon(notification.type),
          color: _getColor(context, notification.type),
        ),
      ),
      title: Text(
        notification.title,
        style: TextStyle(
          fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
          color: notification.isRead ? theme.colorScheme.onSurface : theme.colorScheme.onSurfaceVariant,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(
            notification.message,
            style: TextStyle(
              color: notification.isRead ? theme.colorScheme.onSurface.withOpacity(0.6) : theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            DateFormat('MMM d, h:mm a').format(notification.createdAt),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.4),
            ),
          ),
        ],
      ),
      trailing: !notification.isRead
          ? Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                shape: BoxShape.circle,
              ),
            )
          : null,
    );
  }
}
