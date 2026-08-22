import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:task_flow/core/di/injection_container.dart';
import 'package:task_flow/features/auth/presentation/cubit/session_cubit.dart';
import 'package:task_flow/features/projects/domain/entities/project.dart';
import 'package:task_flow/features/projects/presentation/cubit/project_detail_cubit.dart';
import 'package:task_flow/features/projects/presentation/cubit/project_list_cubit.dart';
import 'package:task_flow/features/projects/presentation/widgets/task_summary_row.dart';
import 'package:task_flow/features/tasks/presentation/bloc/task_bloc.dart';
import 'package:task_flow/features/tasks/presentation/widgets/task_card.dart';
import 'package:task_flow/shared/widgets/confirm_dialog.dart';
import 'package:task_flow/shared/widgets/empty_view.dart';
import 'package:task_flow/shared/widgets/error_view.dart';
import 'package:task_flow/shared/widgets/loading_view.dart';

class ProjectDetailScreen extends StatelessWidget {
  final String projectId;

  const ProjectDetailScreen({super.key, required this.projectId});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => sl<ProjectDetailCubit>()..loadProject(projectId),
        ),
        BlocProvider(
          create: (_) => sl<TaskBloc>()..add(TasksLoadRequested(projectId)),
        ),
      ],
      child: _ProjectDetailView(projectId: projectId),
    );
  }
}

class _ProjectDetailView extends StatelessWidget {
  final String projectId;

  const _ProjectDetailView({required this.projectId});

  @override
  Widget build(BuildContext context) {
    final user = context.read<SessionCubit>().currentUser;
    final isAdmin = user?.isAdmin ?? false;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: BlocBuilder<ProjectDetailCubit, ProjectDetailState>(
          builder: (context, state) {
            if (state is ProjectDetailSuccess) {
              return Text(state.project.name);
            }
            return const Text('Project Details');
          },
        ),
        actions: [
          if (isAdmin)
            BlocBuilder<ProjectDetailCubit, ProjectDetailState>(
              builder: (context, state) {
                if (state is ProjectDetailSuccess) {
                  return PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        context.push(
                          '/projects/form',
                          extra: {'project': state.project, 'isAdmin': isAdmin},
                        ).then((_) {
                          if (context.mounted) {
                            context.read<ProjectDetailCubit>().refresh(projectId);
                          }
                        });
                      } else if (value == 'delete') {
                        _confirmDelete(context, state.project, isAdmin);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined, size: 20),
                            SizedBox(width: 8),
                            Text('Edit Project'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20),
                            SizedBox(width: 8),
                            Text('Delete Project', style: TextStyle(color: Colors.red)),
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
      body: BlocBuilder<ProjectDetailCubit, ProjectDetailState>(
        builder: (context, projectState) {
          if (projectState is ProjectDetailLoading) {
            return const LoadingView();
          }
          if (projectState is ProjectDetailError) {
            return ErrorView(
              message: projectState.failure.message,
              onRetry: () => context.read<ProjectDetailCubit>().loadProject(projectId),
            );
          }
          if (projectState is ProjectDetailSuccess) {
            final project = projectState.project;

            return RefreshIndicator(
              onRefresh: () async {
                context.read<ProjectDetailCubit>().refresh(projectId);
                context.read<TaskBloc>().add(TasksLoadRequested(projectId));
              },
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (project.description.isNotEmpty) ...[
                            Text(
                              project.description,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurface.withOpacity(0.7),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                          Text(
                            'Task Summary',
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          TaskSummaryRow(project: project),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Tasks',
                                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              FilledButton.icon(
                                onPressed: () {
                                  context.push(
                                    '/tasks/form',
                                    extra: {'projectId': projectId},
                                  ).then((_) {
                                    if (context.mounted) {
                                      context.read<TaskBloc>().add(TasksLoadRequested(projectId));
                                      context.read<ProjectDetailCubit>().refresh(projectId);
                                    }
                                  });
                                },
                                icon: const Icon(Icons.add_rounded, size: 18),
                                label: const Text('Add Task'),
                                style: FilledButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  minimumSize: Size.zero,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ),
                  BlocBuilder<TaskBloc, TaskState>(
                    builder: (context, taskState) {
                      if (taskState is TaskLoading) {
                        return const SliverFillRemaining(
                          child: LoadingView(message: 'Loading tasks...'),
                        );
                      }
                      if (taskState is TaskError) {
                        return SliverFillRemaining(
                          child: ErrorView(
                            message: taskState.failure.message,
                            onRetry: () => context.read<TaskBloc>().add(TasksLoadRequested(projectId)),
                          ),
                        );
                      }
                      if (taskState is TaskEmpty) {
                        return const SliverFillRemaining(
                          child: EmptyView(
                            icon: Icons.task_alt_rounded,
                            title: 'No tasks yet',
                            subtitle: 'Get started by creating a new task for this project.',
                          ),
                        );
                      }
                      if (taskState is TaskSuccess) {
                        final tasks = taskState.tasks;
                        return SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final task = tasks[index];
                              return TaskCard(
                                task: task,
                                onTap: () {
                                  context.push('/tasks/${task.id}').then((_) {
                                    if (context.mounted) {
                                      context.read<TaskBloc>().add(TasksLoadRequested(projectId));
                                      context.read<ProjectDetailCubit>().refresh(projectId);
                                    }
                                  });
                                },
                              );
                            },
                            childCount: tasks.length,
                          ),
                        );
                      }
                      return const SliverToBoxAdapter(child: SizedBox());
                    },
                  ),
                  const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
                ],
              ),
            );
          }
          return const SizedBox();
        },
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, Project project, bool isAdmin) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete Project',
      message: 'Are you sure you want to delete "${project.name}" and all its tasks? This action cannot be undone.',
      confirmLabel: 'Delete',
      isDestructive: true,
    );

    if (confirmed == true && context.mounted) {
      // We will perform deletion using ProjectListCubit through sl
      final listCubit = sl<ProjectListCubit>();
      final error = await listCubit.deleteProject(
        id: project.id,
      );

      if (error != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      } else if (context.mounted) {
        context.pop();
      }
    }
  }
}
