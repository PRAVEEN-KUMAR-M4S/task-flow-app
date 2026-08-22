import 'package:flutter/material.dart';
import 'package:task_flow/core/di/injection_container.dart';
import 'package:task_flow/features/users/domain/entities/org_member.dart';
import 'package:task_flow/features/users/domain/usecases/get_org_members_usecase.dart';
import 'package:task_flow/shared/widgets/app_avatar.dart';
import 'package:task_flow/shared/widgets/error_view.dart';
import 'package:task_flow/shared/widgets/loading_view.dart';

class AssigneePickerBottomSheet extends StatefulWidget {
  final String orgId;
  final String? selectedAssigneeId;

  const AssigneePickerBottomSheet({
    super.key,
    required this.orgId,
    this.selectedAssigneeId,
  });

  @override
  State<AssigneePickerBottomSheet> createState() => _AssigneePickerBottomSheetState();
}

class _AssigneePickerBottomSheetState extends State<AssigneePickerBottomSheet> {
  late final Future<List<OrgMember>> _membersFuture;

  @override
  void initState() {
    super.initState();
    _membersFuture = _fetchMembers();
  }

  Future<List<OrgMember>> _fetchMembers() async {
    final usecase = sl<GetOrgMembersUseCase>();
    final result = await usecase(widget.orgId);
    return result.fold(
      (failure) => throw Exception(failure.message),
      (members) => members,
    );
  }

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
            child: FutureBuilder<List<OrgMember>>(
              future: _membersFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                    height: 200,
                    child: LoadingView(message: 'Loading team members...'),
                  );
                }
                if (snapshot.hasError) {
                  return SizedBox(
                    height: 200,
                    child: ErrorView(
                      message: snapshot.error.toString(),
                      onRetry: () {
                        setState(() {
                          _membersFuture = _fetchMembers();
                        });
                      },
                    ),
                  );
                }

                final members = snapshot.data ?? [];

                return ListView(
                  shrinkWrap: true,
                  children: [
                    // Unassigned option
                    ListTile(
                      leading: CircleAvatar(
                        backgroundColor: theme.colorScheme.surfaceVariant,
                        child: Icon(
                          Icons.person_off_rounded,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      title: const Text('Unassigned'),
                      trailing: widget.selectedAssigneeId == null
                          ? Icon(Icons.check_circle_rounded, color: theme.colorScheme.primary)
                          : null,
                      onTap: () => Navigator.of(context).pop(null),
                    ),
                    const Divider(),
                    ...members.map((member) {
                      final isSelected = widget.selectedAssigneeId == member.userId;
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
