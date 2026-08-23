import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:task_flow/core/di/injection_container.dart';
import 'package:task_flow/features/users/presentation/cubit/org_members_cubit.dart';
import 'package:task_flow/shared/widgets/app_avatar.dart';
import 'package:task_flow/shared/widgets/error_view.dart';
import 'package:task_flow/shared/widgets/loading_view.dart';

class AssigneePickerBottomSheet extends StatelessWidget {
  final String orgId;
  final String? selectedAssigneeId;

  const AssigneePickerBottomSheet({
    super.key,
    required this.orgId,
    this.selectedAssigneeId,
  });

  @override
  @override
  Widget build(BuildContext context) {
    // OrgMembersCubit is at root level — load members for this org
    sl<OrgMembersCubit>().loadMembers(orgId);
    return _AssigneePickerBody(
      orgId: orgId,
      selectedAssigneeId: selectedAssigneeId,
    );
  }
}

class _AssigneePickerBody extends StatelessWidget {
  final String orgId;
  final String? selectedAssigneeId;

  const _AssigneePickerBody({required this.orgId, this.selectedAssigneeId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Assign Task',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 12),
          const Divider(),
          Flexible(
            child: BlocBuilder<OrgMembersCubit, OrgMembersState>(
              builder: (context, state) {
                if (state is OrgMembersLoading) {
                  return const SizedBox(
                    height: 200,
                    child: LoadingView(message: 'Loading team members...'),
                  );
                }
                if (state is OrgMembersError) {
                  return SizedBox(
                    height: 200,
                    child: ErrorView(
                      message: state.failure.message,
                      onRetry: () => context.read<OrgMembersCubit>().loadMembers(orgId),
                    ),
                  );
                }

                final members = state is OrgMembersLoaded ? state.members : [];

                return ListView(
                  shrinkWrap: true,
                  children: [
                    ListTile(
                      leading: CircleAvatar(
                        backgroundColor: theme.colorScheme.surfaceVariant,
                        child: Icon(
                          Icons.person_off_rounded,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      title: const Text('Unassigned'),
                      trailing: selectedAssigneeId == null
                          ? Icon(Icons.check_circle_rounded, color: theme.colorScheme.primary)
                          : null,
                      onTap: () => Navigator.of(context).pop(null),
                    ),
                    const Divider(),
                    ...members.map((member) {
                      final isSelected = selectedAssigneeId == member.userId;
                      return ListTile(
                        leading: AppAvatar(
                          imageUrl: member.avatarUrl,
                          name: member.name,
                          radius: 18,
                        ),
                        title: Text(member.name),
                        subtitle: Text(member.roleLabel),
                        trailing: isSelected
                            ? Icon(Icons.check_circle_rounded, color: theme.colorScheme.primary)
                            : null,
                        onTap: () => Navigator.of(context).pop(member),
                      );
                    }),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
