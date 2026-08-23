import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:task_flow/core/di/injection_container.dart';
import 'package:task_flow/features/projects/domain/entities/project.dart';
import 'package:task_flow/features/projects/domain/usecases/create_project_usecase.dart';
import 'package:task_flow/features/projects/domain/usecases/update_project_usecase.dart';

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
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
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

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);

    debugPrint('[ProjectForm] 📝 Submitting ${widget.project == null ? 'CREATE' : 'UPDATE'}...');
    final result = widget.project == null
        ? await sl<CreateProjectUseCase>()(CreateProjectParams(
            name: _nameController.text.trim(),
            description: _descController.text.trim(),
          ))
        : await sl<UpdateProjectUseCase>()(UpdateProjectParams(
            id: widget.project!.id,
            name: _nameController.text.trim(),
            description: _descController.text.trim(),
            status: _status,
          ));

    if (!mounted) return;

    result.fold(
      (failure) {
        debugPrint('[ProjectForm] ❌ Failed: ${failure.message}');
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(failure.message),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      },
      (project) {
        debugPrint('[ProjectForm] ✅ Success: ${project.id} — popping');
        // Success — pop. The list screen refreshes on return.
        context.pop();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.project != null;

    return Scaffold(
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
                enabled: !_isLoading,
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
                  onChanged: _isLoading
                      ? null
                      : (val) {
                          if (val != null) setState(() => _status = val);
                        },
                ),
              ],
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
                      : Text(isEditing ? 'Save Changes' : 'Create Project'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
