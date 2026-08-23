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
import 'package:task_flow/features/users/domain/entities/org_member.dart';
import 'package:task_flow/features/users/domain/usecases/get_org_members_usecase.dart';

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

  bool _isLoading = false;
  List<OrgMember> _members = [];

  @override
  void initState() {
    super.initState();
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

  Future<void> _loadOrgMembers() async {
    final orgId = context.read<SessionCubit>().currentUser?.orgId;
    if (orgId == null) return;

    final usecase = sl<GetOrgMembersUseCase>();
    final result = await usecase(orgId);
    result.fold(
      (failure) => null,
      (members) => setState(() => _members = members),
    );
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

    setState(() => _isLoading = true);

    final user = context.read<SessionCubit>().currentUser;
    if (user == null) return;

    final taskBloc = sl<TaskBloc>();

    final tags = _tagsController.text
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    if (widget.task == null) {
      taskBloc.add(TaskCreated(CreateTaskParams(
        projectId: widget.projectId,
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        priority: _priority,
        status: _status,
        assigneeId: _assigneeId,
        createdBy: user.id,
        dueDate: _dueDate,
        tags: tags,
      )));
    } else {
      taskBloc.add(TaskUpdated(UpdateTaskParams(
        taskId: widget.task!.id,
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        priority: _priority,
        status: _status,
        assigneeId: _assigneeId,
        dueDate: _dueDate,
        tags: tags,
      )));
    }

    setState(() => _isLoading = false);
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.task != null;

    return Scaffold(
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
                enabled: !_isLoading,
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
                enabled: !_isLoading,
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
                value: _priority,
                decoration: const InputDecoration(labelText: 'Priority'),
                items: const [
                  DropdownMenuItem(value: 'low', child: Text('Low')),
                  DropdownMenuItem(value: 'medium', child: Text('Medium')),
                  DropdownMenuItem(value: 'high', child: Text('High')),
                  DropdownMenuItem(value: 'critical', child: Text('Critical')),
                ],
                onChanged: _isLoading ? null : (val) => setState(() => _priority = val!),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _status,
                decoration: const InputDecoration(labelText: 'Status'),
                items: const [
                  DropdownMenuItem(value: 'todo', child: Text('Todo')),
                  DropdownMenuItem(value: 'in_progress', child: Text('In Progress')),
                  DropdownMenuItem(value: 'review', child: Text('Review')),
                  DropdownMenuItem(value: 'done', child: Text('Done')),
                ],
                onChanged: _isLoading ? null : (val) => setState(() => _status = val!),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String?>(
                value: _assigneeId,
                decoration: const InputDecoration(labelText: 'Assignee'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Unassigned')),
                  ..._members.map((member) => DropdownMenuItem(
                        value: member.userId,
                        child: Text(member.name),
                      )),
                ],
                onChanged: _isLoading ? null : (val) => setState(() => _assigneeId = val),
              ),
              const SizedBox(height: 16),
              // Due Date Picker
              InkWell(
                onTap: _isLoading ? null : () => _selectDueDate(context),
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
                enabled: !_isLoading,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}
