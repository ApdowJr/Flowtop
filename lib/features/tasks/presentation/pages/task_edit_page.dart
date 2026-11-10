import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flowtop/core/constants/app_constants.dart';
import 'package:flowtop/core/widgets/app_text_field.dart';
import 'package:flowtop/core/widgets/app_empty_state.dart';
import 'package:flowtop/core/widgets/app_loading.dart';
import 'package:flowtop/core/widgets/app_error_state.dart';
import 'package:flowtop/core/widgets/app_button.dart';
import 'package:flowtop/features/tasks/domain/entities/task_entity.dart';
import 'package:flowtop/features/tasks/presentation/providers/task_provider.dart';

/// Edit an existing task.
class TaskEditPage extends ConsumerStatefulWidget {
  const TaskEditPage({super.key, required this.taskId});

  final String taskId;

  @override
  ConsumerState<TaskEditPage> createState() => _TaskEditPageState();
}

class _TaskEditPageState extends ConsumerState<TaskEditPage> {
  String get taskId => widget.taskId;
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  late TaskPriority _priority;
  late TaskCategory _category;
  DateTime? _dueDate;

  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _priority = TaskPriority.medium;
    _category = TaskCategory.personal;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final taskAsync = ref.read(taskProvider(taskId));
    final existingTask = taskAsync.value;

    if (existingTask == null || existingTask.workspaceId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to save: task not found.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }

    final updatedTask = existingTask.copyWith(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      priority: _priority,
      category: _category,
      dueDate: _dueDate,
      updatedAt: DateTime.now(),
    );

    try {
      await ref.read(taskListProvider(existingTask.workspaceId!).notifier).updateTask(
        widget.taskId,
        updatedTask,
      );
      if (mounted) context.go(AppRoutes.taskList);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save task: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final taskAsync = ref.watch(taskProvider(taskId));

    return taskAsync.when(
      data: (task) {
        if (task == null) {
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            appBar: AppBar(title: const Text('Edit task')),
            body: const AppEmptyState(
              title: 'Task not found',
              subtitle: 'The requested task does not exist or you do not have access to it.',
              icon: Icons.task_outlined,
            ),
          );
        }

        // Initialize form fields from the task data (once).
        if (!_initialized) {
          _titleController.text = task.title;
          _descriptionController.text = task.description;
          _priority = task.priority;
          _category = task.category;
          _dueDate = task.dueDate;
          _initialized = true;
        }

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(title: const Text('Edit task')),
          body: Form(
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
                AppButton(text: AppStrings.save, onPressed: _save),
              ],
            ),
          ),
        );
      },
      loading: () => Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(title: const Text('Edit task')),
        body: const AppPageLoading(message: AppStrings.loading),
      ),
      error: (error, _) => Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(title: const Text('Edit task')),
        body: AppErrorState(
          message: error.toString(),
          onRetry: () => ref.invalidate(taskProvider(taskId)),
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) setState(() => _dueDate = date);
  }

  Widget _buildSectionTitle(String text) {
    return Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary));
  }
}
