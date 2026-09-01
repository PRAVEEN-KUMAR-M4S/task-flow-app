import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:task_flow/features/tasks/domain/entities/task_entity.dart';
import 'package:task_flow/features/tasks/presentation/widgets/priority_badge.dart';
import 'package:task_flow/features/tasks/presentation/widgets/status_chip.dart';
import 'package:task_flow/shared/widgets/app_avatar.dart';

class TaskCard extends StatelessWidget {
  final TaskEntity task;
  final VoidCallback onTap;
  final VoidCallback onFavorite;

  const TaskCard({
    super.key,
    required this.task,
    required this.onTap,
    required this.onFavorite,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isOverdue =
        task.dueDate != null &&
        task.dueDate!.isBefore(DateTime.now()) &&
        task.status != 'done';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      task.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: onFavorite,
                    child: Icon(
                      task.isFavorite ? Icons.star : Icons.star_border,
                      color: task.isFavorite ? Colors.amber : Colors.grey,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 4),
                  PriorityBadge(priority: task.priority),
                ],
              ),
              const SizedBox(height: 6),
              if (task.description.isNotEmpty) ...[
                Text(
                  task.description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
              ],
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      StatusChip(status: task.status),
                      if (task.dueDate != null) ...[
                        const SizedBox(width: 12),
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today_rounded,
                              size: 14,
                              color: isOverdue
                                  ? theme.colorScheme.error
                                  : theme.colorScheme.onSurface.withOpacity(
                                      0.4,
                                    ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              DateFormat('MMM d').format(task.dueDate!),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: isOverdue
                                    ? theme.colorScheme.error
                                    : theme.colorScheme.onSurface.withOpacity(
                                        0.5,
                                      ),
                                fontWeight: isOverdue ? FontWeight.bold : null,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                  Row(
                    children: [
                      if (task.assigneeId != null) ...[
                        Text(
                          task.assigneeName ?? '',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                        const SizedBox(width: 8),
                        AppAvatar(
                          imageUrl: task.assigneeAvatarUrl,
                          name: task.assigneeName ?? '?',
                          radius: 12,
                        ),
                      ] else ...[
                        Icon(
                          Icons.account_circle_outlined,
                          size: 24,
                          color: theme.colorScheme.onSurface.withOpacity(0.3),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
