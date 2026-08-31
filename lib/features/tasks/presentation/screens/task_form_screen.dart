import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:task_flow/core/di/injection_container.dart';
import 'package:task_flow/features/auth/presentation/cubit/session_cubit.dart';
import 'package:task_flow/features/tasks/domain/entities/task_entity.dart';
import 'package:task_flow/features/tasks/domain/usecases/create_task_usecase.dart';
import 'package:task_flow/features/tasks/domain/usecases/update_task_usecase.dart';
import 'package:task_flow/features/tasks/presentation/cubit/task_list_cubit.dart';
import 'package:task_flow/features/users/presentation/cubit/org_members_cubit.dart';

/// Task create/edit form — uses [TaskListCubit] directly.
class TaskFormScreen extends StatefulWidget {
  final String projectId;
  final TaskEntity? task;

  const TaskFormScreen({super.key, required this.projectId, this.task});

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
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
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
    sl<OrgMembersCubit>().loadMembers(orgId);
  }

  Future<void> _selectDueDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final user = context.read<SessionCubit>().currentUser;
    if (user == null) return;

    final tags = _tagsController.text
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    setState(() => _isSubmitting = true);

    String? error;
    if (widget.task == null) {
      error = await sl<TaskListCubit>().createTask(CreateTaskParams(
        projectId: widget.projectId,
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        priority: _priority,
        status: _status,
        assigneeId: _assigneeId,
        createdBy: user.id,
        dueDate: _dueDate,
        tags: tags,
      ));
    } else {
      error = await sl<TaskListCubit>().updateTask(UpdateTaskParams(
        taskId: widget.task!.id,
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        priority: _priority,
        status: _status,
        assigneeId: _assigneeId,
        orgId: user.orgId,
        dueDate: _dueDate,
        tags: tags,
      ));
    }

    if (!mounted) return;

    if (error != null) {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Theme.of(context).colorScheme.error),
      );
    } else {
      sl<TaskListCubit>().refresh();
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.task != null;

    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Edit Task' : 'Create Task')),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Task Title', hintText: 'e.g. Implement onboarding validation'),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Title is required';
                  if (v.trim().length > 100) return 'Title cannot exceed 100 characters';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(labelText: 'Description', hintText: 'Provide task details...'),
                maxLines: 4,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Description is required';
                  if (v.trim().length > 500) return 'Description cannot exceed 500 characters';
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
                  final resolved = _assigneeId != null && members.any((m) => m.userId == _assigneeId) ? _assigneeId : null;
                  return DropdownButtonFormField<String?>(
                    initialValue: resolved,
                    decoration: const InputDecoration(labelText: 'Assignee'),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Unassigned')),
                      ...members.map((m) => DropdownMenuItem(value: m.userId, child: Text(m.name))),
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
                  decoration: const InputDecoration(labelText: 'Due Date', prefixIcon: Icon(Icons.calendar_today_rounded)),
                  child: Text(_dueDate == null ? 'No due date set' : DateFormat('MMMM dd, yyyy').format(_dueDate!)),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _tagsController,
                decoration: const InputDecoration(labelText: 'Tags (comma separated)', hintText: 'e.g. frontend, bugs, release'),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isSubmitting ? null : _submit,
                  child: _isSubmitting
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                      : Text(isEditing ? 'Save Changes' : 'Create Task'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
