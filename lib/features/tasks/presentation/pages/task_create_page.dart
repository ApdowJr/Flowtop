import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flowtop/core/constants/app_constants.dart';
import 'package:flowtop/core/widgets/app_text_field.dart';
import 'package:flowtop/core/widgets/app_empty_state.dart';
import 'package:flowtop/core/widgets/app_button.dart';
import 'package:flowtop/core/di/injection_container.dart';
import 'package:flowtop/features/tasks/domain/entities/task_entity.dart';

/// Create a new task within the selected workspace.
class TaskCreatePage extends ConsumerStatefulWidget {
  const TaskCreatePage({super.key});

  @override
  ConsumerState<TaskCreatePage> createState() => _TaskCreatePageState();
}

class _TaskCreatePageState extends ConsumerState<TaskCreatePage> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;

  TaskPriority _priority = TaskPriority.medium;
  TaskCategory _category = TaskCategory.personal;
  DateTime? _dueDate;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;

    final user = ref.read(currentUserProvider);
    final workspaceId = ref.read(selectedWorkspaceProvider);

    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You must be signed in to create a task.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }

    if (workspaceId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a workspace first.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }

    final task = TaskEntity(
      id: '',
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      status: TaskStatus.todo,
      priority: _priority,
      category: _category,
      ownerId: user.uid,
      workspaceId: workspaceId,
      dueDate: _dueDate,
      createdAt: DateTime.now(),
    );

    setState(() => _saving = true);
    try {
      await ref.read(taskRepositoryProvider).createTask(task);
      if (mounted) context.go(AppRoutes.taskList);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create task: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) setState(() => _dueDate = date);
  }

  @override
  Widget build(BuildContext context) {
    final workspaceId = ref.watch(selectedWorkspaceProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Create task'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.taskList),
        ),
      ),
      body: workspaceId == null
          ? const AppEmptyState(
              title: 'No workspace selected',
              subtitle: 'Please select a workspace before creating a task.',
              icon: Icons.task_outlined,
            )
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  AppTextField(
                    label: AppStrings.title,
                    hint: 'e.g. Review quarterly report',
                    icon: Icons.title,
                    controller: _titleController,
                    validator: (v) => (v == null || v.isEmpty) ? 'Title is required' : null,
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: AppStrings.description,
                    hint: 'Add details...',
                    icon: Icons.note,
                    controller: _descriptionController,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 20),
                  _buildSectionTitle(AppStrings.priority),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: TaskPriority.values.map((p) => ChoiceChip(
                      label: Text(p.label),
                      selected: _priority == p,
                      selectedColor: p.color.withValues(alpha: 0.15),
                      checkmarkColor: p.color,
                      labelStyle: TextStyle(color: _priority == p ? p.color : AppColors.textSecondary),
                      onSelected: (_) => setState(() => _priority = p),
                    )).toList(),
                  ),
                  const SizedBox(height: 20),
                  _buildSectionTitle(AppStrings.category),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: TaskCategory.values.map((c) => ChoiceChip(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(c.icon, size: 16, color: _category == c ? AppColors.primary : AppColors.textSecondary),
                          const SizedBox(width: 6),
                          Text(c.label),
                        ],
                      ),
                      selected: _category == c,
                      onSelected: (_) => setState(() => _category = c),
                    )).toList(),
                  ),
                  const SizedBox(height: 20),
                  _buildSectionTitle(AppStrings.dueDate),
                  const SizedBox(height: 8),
                  ListTile(
                    leading: const Icon(Icons.schedule, color: AppColors.textSecondary),
                    title: Text(_dueDate == null
                        ? AppStrings.noDueDate
                        : '${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year}'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _pickDate,
                  ),
                  const SizedBox(height: 30),
                  AppButton(text: AppStrings.save, loading: _saving, onPressed: _save),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String text) {
    return Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary));
  }
}
