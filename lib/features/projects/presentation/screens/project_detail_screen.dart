import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:task_flow/core/di/injection_container.dart';
import 'package:task_flow/features/auth/presentation/cubit/session_cubit.dart';
import 'package:task_flow/features/projects/domain/entities/project.dart';
import 'package:task_flow/features/projects/presentation/cubit/project_detail_cubit.dart';
import 'package:task_flow/features/projects/presentation/cubit/project_list_cubit.dart';
import 'package:task_flow/features/projects/presentation/widgets/task_summary_row.dart';
import 'package:task_flow/features/tasks/presentation/cubit/task_list_cubit.dart';
import 'package:task_flow/features/tasks/presentation/widgets/task_card.dart';
import 'package:task_flow/features/tasks/presentation/widgets/task_filter_bar.dart';
import 'package:task_flow/features/users/domain/entities/org_member.dart';
import 'package:task_flow/features/users/domain/usecases/get_org_members_usecase.dart';
import 'package:task_flow/shared/widgets/confirm_dialog.dart';
import 'package:task_flow/shared/widgets/empty_view.dart';
import 'package:task_flow/shared/widgets/error_view.dart';
import 'package:task_flow/shared/widgets/skeleton_loader.dart';
import 'package:task_flow/shared/widgets/skeleton_task_card.dart';

class ProjectDetailScreen extends StatefulWidget {
  final String projectId;

  const ProjectDetailScreen({super.key, required this.projectId});

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  List<OrgMember> _members = [];

  @override
  void initState() {
    super.initState();
    // Reset cubits and load data — all are root-level singletons
    sl<ProjectDetailCubit>().reset();
    sl<ProjectDetailCubit>().loadProject(widget.projectId);
    sl<TaskListCubit>().loadTasks(widget.projectId);
    _loadMembers();
  }

  void _loadMembers() async {
    final orgId = context.read<SessionCubit>().currentUser?.orgId;
    if (orgId == null) return;
    final result = await sl<GetOrgMembersUseCase>()(orgId);
    result.fold((_) {}, (members) {
      if (mounted) setState(() => _members = members);
    });
  }

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
                            context.read<ProjectDetailCubit>().refresh(widget.projectId);
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
            return const _ProjectDetailSkeleton();
          }
          if (projectState is ProjectDetailError) {
            return ErrorView(
              message: projectState.failure.message,
              onRetry: () => context.read<ProjectDetailCubit>().loadProject(widget.projectId),
            );
          }
          if (projectState is ProjectDetailSuccess) {
            final project = projectState.project;

            return RefreshIndicator(
              onRefresh: () async {
                context.read<ProjectDetailCubit>().refresh(widget.projectId);
                sl<TaskListCubit>().loadTasks(widget.projectId);
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
                                    extra: {'projectId': widget.projectId},
                                  ).then((_) {
                                    if (context.mounted) {
                                      sl<TaskListCubit>().loadTasks(widget.projectId);
                                      context.read<ProjectDetailCubit>().refresh(widget.projectId);
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
                  // ── Filter Bar ──────────────────────────────────────────────
                  SliverToBoxAdapter(
                    child: TaskFilterBar(
                      members: _members,
                      onFilterChanged: ({
                        String? status,
                        String? priority,
                        String? assigneeId,
                        DateTime? dueFrom,
                        DateTime? dueTo,
                      }) {
                        final cubit = sl<TaskListCubit>();
                        cubit.filterByStatus(status);
                        cubit.filterByPriority(priority);
                        cubit.filterByAssignee(assigneeId);
                      },
                    ),
                  ),
                  BlocBuilder<TaskListCubit, TaskListState>(
                    builder: (context, taskState) {
                      if (taskState is TaskListInitial || taskState is TaskListLoading) {
                        return SliverPadding(
                          padding: const EdgeInsets.only(top: 8),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) => const SkeletonTaskCard(),
                              childCount: 5,
                            ),
                          ),
                        );
                      }
                      if (taskState is TaskListError) {
                        return SliverFillRemaining(
                          child: ErrorView(
                            message: taskState.failure.message,
                            onRetry: () => sl<TaskListCubit>().loadTasks(widget.projectId),
                          ),
                        );
                      }
                      if (taskState is TaskListEmpty) {
                        return const SliverFillRemaining(
                          child: EmptyView(
                            icon: Icons.task_alt_rounded,
                            title: 'No tasks yet',
                            subtitle: 'Get started by creating a new task for this project.',
                          ),
                        );
                      }
                      if (taskState is TaskListSuccess) {
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
                                      sl<TaskListCubit>().loadTasks(widget.projectId);
                                      context.read<ProjectDetailCubit>().refresh(widget.projectId);
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
      final error = await sl<ProjectListCubit>().deleteProject(id: project.id);

      if (!context.mounted) return;

      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      } else {
        context.pop();
      }
    }
  }
}

/// Skeleton placeholder shown while project detail is loading.
class _ProjectDetailSkeleton extends StatelessWidget {
  const _ProjectDetailSkeleton();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Description skeleton
          SkeletonBox(height: 14, width: MediaQuery.of(context).size.width * 0.85),
          const SizedBox(height: 8),
          SkeletonBox(height: 14, width: MediaQuery.of(context).size.width * 0.6),
          const SizedBox(height: 24),
          // Task Summary skeleton
          SkeletonBox(height: 18, width: MediaQuery.of(context).size.width * 0.35),
          const SizedBox(height: 12),
          Row(
            children: List.generate(
              4,
              (i) => Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: i < 3 ? 8 : 0),
                  child: const SkeletonBox(height: 40),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Tasks header skeleton
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SkeletonBox(height: 18, width: MediaQuery.of(context).size.width * 0.25),
              SkeletonBox(height: 32, width: MediaQuery.of(context).size.width * 0.2),
            ],
          ),
          const SizedBox(height: 12),
          // Task list skeleton
          ...List.generate(5, (_) => const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: SkeletonTaskCard(),
          )),
        ],
      ),
    );
  }
}
