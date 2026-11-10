import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flowtop/core/constants/app_constants.dart';
import 'package:flowtop/core/widgets/app_button.dart';
import 'package:flowtop/core/theme/app_theme.dart';
import 'package:flowtop/core/widgets/app_loading.dart';
import 'package:flowtop/core/widgets/app_empty_state.dart';
import 'package:flowtop/core/widgets/app_error_state.dart';
import 'package:flowtop/features/tasks/domain/entities/task_entity.dart';
import 'package:flowtop/features/tasks/presentation/providers/task_provider.dart';

/// Task details page showing full info and completion toggle.
class TaskDetailPage extends ConsumerWidget {
  const TaskDetailPage({super.key, required this.taskId});

  final String taskId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final taskAsync = ref.watch(taskProvider(taskId));

    return taskAsync.when(
      data: (task) {
        if (task == null) {
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            appBar: AppBar(title: const Text(AppStrings.taskDetails)),
            body: const AppEmptyState(
              title: 'Task not found',
              subtitle: 'The requested task does not exist or you do not have access to it.',
              icon: Icons.task_outlined,
            ),
          );
        }
        return _buildTaskDetail(context, ref, task);
      },
      loading: () => Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(title: const Text(AppStrings.taskDetails)),
        body: const AppPageLoading(message: AppStrings.loading),
      ),
      error: (error, _) => Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(title: const Text(AppStrings.taskDetails)),
        body: AppErrorState(
          message: error.toString(),
          onRetry: () => ref.invalidate(taskProvider(taskId)),
        ),
      ),
    );
  }

  Widget _buildTaskDetail(BuildContext context, WidgetRef ref, TaskEntity task) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(task.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => context.go('${AppRoutes.taskEdit}/$taskId'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Priority', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        const SizedBox(height: 4),
                        Text(task.priority.label,
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: task.priority.color)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: task.status.color.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(AppStrings.status, style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        const SizedBox(height: 4),
                        Text(task.status.label,
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: task.status.color)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (task.description.isNotEmpty) ...[
              const Text(AppStrings.description, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              Text(task.description, style: const TextStyle(fontSize: 15, color: AppColors.textSecondary)),
              const SizedBox(height: 24),
            ],
            if (task.dueDate != null) ...[
              const Text(AppStrings.dueDate, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.schedule, size: 18, color: AppColors.textSecondary),
                  const SizedBox(width: 8),
                  Text(
                    '${task.dueDate!.day}/${task.dueDate!.month}/${task.dueDate!.year}',
                    style: const TextStyle(fontSize: 15, color: AppColors.textPrimary),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
            if (task.assigneeId != null && task.assigneeId!.isNotEmpty) ...[
              const Text(AppStrings.assignee, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              Text(
                task.assigneeId!,
                style: const TextStyle(fontSize: 15, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),
            ],
            SizedBox(
              width: double.infinity,
              child: AppButton(
                text: task.status == TaskStatus.done ? AppStrings.reopen : AppStrings.markComplete,
                onPressed: task.workspaceId == null
                    ? null
                    : () async {
                        await ref.read(taskListProvider(task.workspaceId!).notifier)
                            .toggleCompletion(taskId, task.status != TaskStatus.done);
                      },
                icon: Icon(
                  task.status == TaskStatus.done ? Icons.replay : Icons.check_circle,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
