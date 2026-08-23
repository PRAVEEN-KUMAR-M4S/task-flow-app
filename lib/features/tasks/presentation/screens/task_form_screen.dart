import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:task_flow/core/di/injection_container.dart';
import 'package:task_flow/features/auth/presentation/cubit/session_cubit.dart';
import 'package:task_flow/features/tasks/domain/entities/task_entity.dart';
import 'package:task_flow/features/tasks/domain/usecases/create_task_usecase.dart';
import 'package:task_flow/features/tasks/domain/usecases/update_task_usecase.dart';
import 'package:task_flow/features/tasks/presentation/bloc/task_bloc.dart';
import 'package:task_flow/features/tasks/presentation/cubit/task_form_cubit.dart';
import 'package:task_flow/features/users/presentation/cubit/org_members_cubit.dart';

/// Task create/edit form.
///
/// [TaskFormCubit] and [TaskBloc] are root-level singletons provided in [main.dart].
/// We call [TaskFormCubit.reset] when the screen opens so stale state from a
/// previous submission doesn't leak into this form.
class TaskFormScreen extends StatefulWidget {
  final String projectId;
  final TaskEntity? task;

  const TaskFormScreen({
    super.key,
    required this.projectId,
    this.task,
  });

  @override
  State<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descController;
  late final TextEditingController _tagsController;

  late String _priority;
  late String _status;
  String? _assigneeId;
  DateTime? _dueDate;

  @override
  void initState() {
    super.initState();
    // Reset so a previous success/error doesn't persist
    sl<TaskFormCubit>().reset();
    sl<OrgMembersCubit>().reset();
    _titleController = TextEditingController(text: widget.task?.title ?? '');
    _descController = TextEditingController(text: widget.task?.description ?? '');
    _tagsController = TextEditingController(text: widget.task?.tags.join(', ') ?? '');

    _priority = widget.task?.priority ?? 'medium';
    _status = widget.task?.status ?? 'todo';
    _assigneeId = widget.task?.assigneeId;
    _dueDate = widget.task?.dueDate;

    _loadOrgMembers();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  void _loadOrgMembers() {
    final orgId = context.read<SessionCubit>().currentUser?.orgId;
    if (orgId == null) return;
    // OrgMembersCubit is at root level — safe to read from initState
    sl<OrgMembersCubit>().loadMembers(orgId);
  }

  Future<void> _selectDueDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null) {
      setState(() => _dueDate = picked);
    }
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final user = context.read<SessionCubit>().currentUser;
    if (user == null) return;

    final tags = _tagsController.text
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    final cubit = context.read<TaskFormCubit>();

    if (widget.task == null) {
      cubit.createTask(
        params: CreateTaskParams(
          projectId: widget.projectId,
          title: _titleController.text.trim(),
          description: _descController.text.trim(),
          priority: _priority,
          status: _status,
          assigneeId: _assigneeId,
          createdBy: user.id,
          dueDate: _dueDate,
          tags: tags,
        ),
      );
    } else {
      cubit.updateTask(
        params: UpdateTaskParams(
          taskId: widget.task!.id,
          title: _titleController.text.trim(),
          description: _descController.text.trim(),
          priority: _priority,
          status: _status,
          assigneeId: _assigneeId,
          orgId: user.orgId,
          dueDate: _dueDate,
          tags: tags,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.task != null;

    return BlocListener<TaskFormCubit, TaskFormState>(
        listener: (context, state) {
          if (state is TaskFormError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.failure.message),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          } else if (state is TaskFormSuccess) {
            sl<TaskBloc>().add(TasksLoadRequested(widget.projectId));
            context.pop();
          }
        },
        child: Scaffold(
          appBar: AppBar(
            title: Text(isEditing ? 'Edit Task' : 'Create Task'),
          ),
          body: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Task Title',
                      hintText: 'e.g. Implement onboarding validation',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Title is required';
                      }
                      if (value.trim().length > 100) {
                        return 'Title cannot exceed 100 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      hintText: 'Provide task details...',
                    ),
                    maxLines: 4,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Description is required';
                      }
                      if (value.trim().length > 500) {
                        return 'Description cannot exceed 500 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _priority,
                    decoration: const InputDecoration(labelText: 'Priority'),
                    items: const [
                      DropdownMenuItem(value: 'low', child: Text('Low')),
                      DropdownMenuItem(value: 'medium', child: Text('Medium')),
                      DropdownMenuItem(value: 'high', child: Text('High')),
                      DropdownMenuItem(value: 'urgent', child: Text('Urgent')),
                    ],
                    onChanged: (val) => setState(() => _priority = val!),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _status,
                    decoration: const InputDecoration(labelText: 'Status'),
                    items: const [
                      DropdownMenuItem(value: 'todo', child: Text('Todo')),
                      DropdownMenuItem(value: 'in_progress', child: Text('In Progress')),
                      DropdownMenuItem(value: 'review', child: Text('Review')),
                      DropdownMenuItem(value: 'done', child: Text('Done')),
                    ],
                    onChanged: (val) => setState(() => _status = val!),
                  ),
                  const SizedBox(height: 16),
                  BlocBuilder<OrgMembersCubit, OrgMembersState>(
                    builder: (context, membersState) {
                      final members = membersState is OrgMembersLoaded ? membersState.members : [];
                      final resolvedAssignee = _assigneeId != null &&
                          members.any((m) => m.userId == _assigneeId)
                          ? _assigneeId
                          : null;
                      return DropdownButtonFormField<String?>(
                        initialValue: resolvedAssignee,
                        decoration: const InputDecoration(labelText: 'Assignee'),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('Unassigned')),
                          ...members.map((member) => DropdownMenuItem(
                                value: member.userId,
                                child: Text(member.name),
                              )),
                        ],
                        onChanged: (val) => setState(() => _assigneeId = val),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () => _selectDueDate(context),
                    borderRadius: BorderRadius.circular(10),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Due Date',
                        prefixIcon: Icon(Icons.calendar_today_rounded),
                      ),
                      child: Text(
                        _dueDate == null ? 'No due date set' : DateFormat('MMMM dd, yyyy').format(_dueDate!),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _tagsController,
                    decoration: const InputDecoration(
                      labelText: 'Tags (comma separated)',
                      hintText: 'e.g. frontend, bugs, release',
                    ),
                  ),
                  const SizedBox(height: 32),
                  BlocBuilder<TaskFormCubit, TaskFormState>(
                    builder: (context, state) {
                      final isSubmitting = state is TaskFormSubmitting;
                      return SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: isSubmitting ? null : _submit,
                          child: isSubmitting
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : Text(isEditing ? 'Save Changes' : 'Create Task'),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      );
  }
}
