import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:task_flow/core/di/injection_container.dart';
import 'package:task_flow/features/projects/domain/entities/project.dart';
import 'package:task_flow/features/projects/presentation/cubit/project_form_cubit.dart';
import 'package:task_flow/features/projects/presentation/cubit/project_list_cubit.dart';

/// Project create/edit form.
///
/// [ProjectFormCubit] is a root-level singleton provided in [main.dart].
/// We call [reset] when the screen opens so stale state from a previous
/// submission doesn't leak into this form.
class ProjectFormScreen extends StatefulWidget {
  final Project? project;
  final bool isAdmin;

  const ProjectFormScreen({
    super.key,
    this.project,
    required this.isAdmin,
  });

  @override
  State<ProjectFormScreen> createState() => _ProjectFormScreenState();
}

class _ProjectFormScreenState extends State<ProjectFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descController;
  late String _status;

  @override
  void initState() {
    super.initState();
    // Reset so a previous success/error doesn't persist
    sl<ProjectFormCubit>().reset();
    _nameController = TextEditingController(text: widget.project?.name ?? '');
    _descController = TextEditingController(text: widget.project?.description ?? '');
    _status = widget.project?.status ?? 'active';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final cubit = context.read<ProjectFormCubit>();

    if (widget.project == null) {
      cubit.createProject(
        name: _nameController.text.trim(),
        description: _descController.text.trim(),
      );
    } else {
      cubit.updateProject(
        id: widget.project!.id,
        name: _nameController.text.trim(),
        description: _descController.text.trim(),
        status: _status,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.project != null;

    return BlocListener<ProjectFormCubit, ProjectFormState>(
      listener: (context, state) {
        if (state is ProjectFormError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.failure.message),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        } else if (state is ProjectFormSuccess) {
          sl<ProjectListCubit>().refresh();
          context.pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(isEditing ? 'Edit Project' : 'New Project'),
        ),
        body: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Project Name',
                    hintText: 'e.g. Website Overhaul',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Project name is required';
                    }
                    if (value.trim().length > 100) {
                      return 'Name cannot exceed 100 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'Provide details about the project goals...',
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
                if (isEditing) ...[
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _status,
                    decoration: const InputDecoration(
                      labelText: 'Status',
                    ),
                    items: const [
                      DropdownMenuItem(value: 'active', child: Text('Active')),
                      DropdownMenuItem(value: 'completed', child: Text('Completed')),
                      DropdownMenuItem(value: 'archived', child: Text('Archived')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _status = val);
                    },
                  ),
                ],
                const SizedBox(height: 32),
                BlocBuilder<ProjectFormCubit, ProjectFormState>(
                  builder: (context, state) {
                    final isSubmitting = state is ProjectFormSubmitting;
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
                            : Text(isEditing ? 'Save Changes' : 'Create Project'),
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
