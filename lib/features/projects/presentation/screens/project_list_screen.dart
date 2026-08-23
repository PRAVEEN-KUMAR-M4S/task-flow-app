import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:task_flow/core/di/injection_container.dart';
import 'package:task_flow/features/auth/presentation/cubit/session_cubit.dart';
import 'package:task_flow/features/projects/domain/entities/project.dart';
import 'package:task_flow/features/projects/presentation/cubit/project_list_cubit.dart';
import 'package:task_flow/features/projects/presentation/widgets/project_card.dart';
import 'package:task_flow/shared/widgets/confirm_dialog.dart';
import 'package:task_flow/shared/widgets/empty_view.dart';
import 'package:task_flow/shared/widgets/error_view.dart';
import 'package:task_flow/shared/widgets/loading_view.dart';
import 'package:task_flow/shared/widgets/stale_data_banner.dart';

class ProjectListScreen extends StatelessWidget {
  const ProjectListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ProjectListCubit>()
        ..loadProjects(orgId: context.read<SessionCubit>().currentUser?.orgId ?? ''),
      child: const _ProjectListView(),
    );
  }
}

class _ProjectListView extends StatelessWidget {
  const _ProjectListView();

  @override
  Widget build(BuildContext context) {
    final user = context.read<SessionCubit>().currentUser;
    final isAdmin = user?.isAdmin ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Projects'),
        actions: [
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: 'New Project',
              onPressed: () => _showProjectForm(context, isAdmin: isAdmin),
            ),
        ],
      ),
      body: BlocBuilder<ProjectListCubit, ProjectListState>(
        builder: (context, state) {
          if (state is ProjectListLoading) {
            return const LoadingView();
          }
          if (state is ProjectListError) {
            return ErrorView(
              message: state.failure.message,
              onRetry: () => context
                  .read<ProjectListCubit>()
                  .loadProjects(orgId: user?.orgId ?? ''),
            );
          }
          if (state is ProjectListEmpty) {
            return EmptyView(
              icon: Icons.folder_outlined,
              title: 'No projects yet',
              subtitle: isAdmin
                  ? 'Create your first project to get started.'
                  : 'No projects have been created for your organization.',
              actionLabel: isAdmin ? 'Create Project' : null,
              onAction: isAdmin
                  ? () => _showProjectForm(context, isAdmin: isAdmin)
                  : null,
            );
          }

          final projects = state is ProjectListSuccess
              ? state.projects
              : state is ProjectMutationLoading
                  ? state.currentProjects
                  : <Project>[];
          final isStale =
              state is ProjectListSuccess ? state.isStale : false;
          final isMutating = state is ProjectMutationLoading;

          return RefreshIndicator(
            onRefresh: () => context.read<ProjectListCubit>().refresh(),
            child: Column(
              children: [
                if (isStale)
                  StaleDataBanner(
                    onRefresh: () => context
                        .read<ProjectListCubit>()
                        .loadProjects(orgId: user?.orgId ?? ''),
                  ),
                if (isMutating) const LinearProgressIndicator(),
                Expanded(
                  child: ListView.builder(
                    itemCount: projects.length,
                    itemBuilder: (context, index) {
                      final project = projects[index];
                      return ProjectCard(
                        project: project,
                        onTap: () => context.push(
                          '/projects/${project.id}',
                        ),
                        onEdit: isAdmin
                            ? () => _showProjectForm(
                                context,
                                isAdmin: isAdmin,
                                project: project,
                              )
                            : null,
                        onDelete: isAdmin
                            ? () => _confirmDelete(context, project, isAdmin)
                            : null,
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _showProjectForm(
    BuildContext context, {
    required bool isAdmin,
    Project? project,
  }) async {
    await context.push(
      '/projects/form',
      extra: {'project': project, 'isAdmin': isAdmin},
    );
    debugPrint('[ProjectList] 🔄 Returned from form — refreshing...');
    if (context.mounted) {
      context.read<ProjectListCubit>().refresh();
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    Project project,
    bool isAdmin,
  ) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete Project',
      message:
          'Are you sure you want to delete "${project.name}"? This action cannot be undone.',
      confirmLabel: 'Delete',
      isDestructive: true,
    );
    if (confirmed == true && context.mounted) {
      final error = await context.read<ProjectListCubit>().deleteProject(
            id: project.id,
          );
      if (error != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
}
