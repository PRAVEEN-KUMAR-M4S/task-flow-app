import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:task_flow/core/di/injection_container.dart';
import 'package:task_flow/features/auth/presentation/cubit/session_cubit.dart';
import 'package:task_flow/features/tasks/domain/entities/task_entity.dart';
import 'package:task_flow/features/tasks/presentation/cubit/task_detail_cubit.dart';
import 'package:task_flow/features/tasks/presentation/widgets/assignee_picker_bottom_sheet.dart';
import 'package:task_flow/features/tasks/presentation/widgets/priority_badge.dart';
import 'package:task_flow/features/tasks/presentation/widgets/status_chip.dart';
import 'package:task_flow/features/users/domain/entities/org_member.dart';
import 'package:task_flow/shared/widgets/app_avatar.dart';
import 'package:task_flow/shared/widgets/confirm_dialog.dart';
import 'package:task_flow/shared/widgets/error_view.dart';
import 'package:task_flow/shared/widgets/loading_view.dart';

class TaskDetailScreen extends StatefulWidget {
  final String taskId;

  const TaskDetailScreen({super.key, required this.taskId});

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  @override
  void initState() {
    super.initState();
    // Reset cubit and load data — root-level singletons
    sl<TaskDetailCubit>().reset();
    sl<TaskDetailCubit>().loadTask(widget.taskId);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = context.read<SessionCubit>().currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Details'),
        actions: [
          BlocBuilder<TaskDetailCubit, TaskDetailState>(
            builder: (context, state) {
              if (state is TaskDetailSuccess) {
                return PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      context.push(
                        '/tasks/form',
                        extra: {
                          'projectId': state.task.projectId,
                          'task': state.task,
                        },
                      ).then((_) {
                        if (context.mounted) {
                          context.read<TaskDetailCubit>().refresh(widget.taskId);
                        }
                      });
                    } else if (value == 'delete') {
                      _confirmDelete(context, state.task);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, size: 20),
                          SizedBox(width: 8),
                          Text('Edit Task'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20),
                          SizedBox(width: 8),
                          Text('Delete Task', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                );
              }
              return const SizedBox();
            },
          ),
        ],
      ),
      body: BlocBuilder<TaskDetailCubit, TaskDetailState>(
            builder: (context, state) {
              if (state is TaskDetailLoading) {
                return const LoadingView();
              }
              if (state is TaskDetailError) {
                return ErrorView(
                  message: state.failure.message,
                  onRetry: () => context.read<TaskDetailCubit>().loadTask(widget.taskId),
                );
              }
              if (state is TaskDetailSuccess) {
                final task = state.task;

                return RefreshIndicator(
                  onRefresh: () async {
                    context.read<TaskDetailCubit>().refresh(widget.taskId);
                  },
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.title,
                          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            StatusChip(status: task.status),
                            const SizedBox(width: 8),
                            PriorityBadge(priority: task.priority),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'STATUS',
                                    style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  DropdownButtonFormField<String>(
                                    initialValue: task.status,
                                    isExpanded: true,
                                    decoration: const InputDecoration(
                                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    ),
                                    items: const [
                                      DropdownMenuItem(value: 'todo', child: Text('Todo')),
                                      DropdownMenuItem(value: 'in_progress', child: Text('In Progress')),
                                      DropdownMenuItem(value: 'review', child: Text('Review')),
                                      DropdownMenuItem(value: 'done', child: Text('Done')),
                                    ],
                                    onChanged: (newStatus) {
                                      if (newStatus != null) {
                                        sl<TaskDetailCubit>().updateStatus(task.id, newStatus);
                                        sl<TaskDetailCubit>().updateTaskLocally(
                                              task.copyWith(status: newStatus),
                                            );
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'ASSIGNEE',
                                    style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  InkWell(
                                    onTap: () => _pickAssignee(context, task, user?.orgId ?? ''),
                                    borderRadius: BorderRadius.circular(10),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                      decoration: BoxDecoration(
                                        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.3)),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Row(
                                        children: [
                                          AppAvatar(
                                            imageUrl: task.assigneeAvatarUrl,
                                            name: task.assigneeName ?? '?',
                                            radius: 12,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              task.assigneeName ?? 'Unassigned',
                                              style: theme.textTheme.bodyMedium,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const Icon(Icons.arrow_drop_down),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'DESCRIPTION',
                          style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            task.description.isEmpty ? 'No description provided.' : task.description,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            if (task.dueDate != null)
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'DUE DATE',
                                      style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.calendar_today_rounded, size: 16, color: Colors.grey),
                                        const SizedBox(width: 8),
                                        Text(DateFormat('MMM dd, yyyy').format(task.dueDate!)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (task.tags.isNotEmpty) ...[
                          Text(
                            'TAGS',
                            style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: task.tags.map((t) => Chip(label: Text(t))).toList(),
                          ),
                          const SizedBox(height: 24),
                        ],
                        const Divider(),
                        const SizedBox(height: 16),
                        Text(
                          'COMMENTS',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        _buildCommentsSection(context, state, theme),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                );
              }
              return const SizedBox();
            },
          ),
    );
  }

  Widget _buildCommentsSection(
    BuildContext context,
    TaskDetailSuccess state,
    ThemeData theme,
  ) {
    if (state.commentsLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.comments.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: Text(
            'No comments yet.',
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: state.comments.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final comment = state.comments[index];
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppAvatar(
              imageUrl: comment.authorAvatarUrl,
              name: comment.authorName,
              radius: 16,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        comment.authorName,
                        style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        DateFormat('MMM d, h:mm a').format(comment.createdAt),
                        style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(comment.body),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _pickAssignee(BuildContext context, TaskEntity task, String orgId) async {
    final OrgMember? selectedMember = await showModalBottomSheet<OrgMember?>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.6,
          child: AssigneePickerBottomSheet(
            orgId: orgId,
            selectedAssigneeId: task.assigneeId,
          ),
        );
      },
    );

    if (context.mounted) {
      sl<TaskDetailCubit>().assignTask(task.id, selectedMember?.userId, orgId);

      final updatedTask = task.copyWith(
        assigneeId: selectedMember?.userId,
        assigneeName: selectedMember?.name,
        assigneeAvatarUrl: selectedMember?.avatarUrl,
      );
      sl<TaskDetailCubit>().updateTaskLocally(updatedTask);
    }
  }

  Future<void> _confirmDelete(BuildContext context, TaskEntity task) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete Task',
      message: 'Are you sure you want to delete this task? This action cannot be undone.',
      confirmLabel: 'Delete',
      isDestructive: true,
    );

    if (confirmed == true && context.mounted) {
      final error = await sl<TaskDetailCubit>().deleteTask(task.id);
      if (!context.mounted) return;
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: Theme.of(context).colorScheme.error),
        );
      } else {
        context.pop();
      }
    }
  }
}
