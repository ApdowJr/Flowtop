import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flowtop/core/constants/app_constants.dart';
import 'package:flowtop/core/theme/app_theme.dart';
import 'package:flowtop/core/widgets/app_loading.dart';
import 'package:flowtop/core/widgets/app_text_field.dart';
import 'package:flowtop/core/widgets/app_empty_state.dart';
import 'package:flowtop/core/widgets/app_error_state.dart';
import 'package:flowtop/core/widgets/app_button.dart';
import 'package:flowtop/core/di/injection_container.dart';
import 'package:flowtop/features/auth/presentation/providers/auth_provider.dart';
import 'package:flowtop/features/tasks/domain/entities/task_entity.dart';
import 'package:flowtop/features/tasks/presentation/providers/task_provider.dart';

/// Task list for a workspace with search, filter, priority and status chips.
class TaskListPage extends ConsumerStatefulWidget {
  const TaskListPage({super.key});

  @override
  ConsumerState<TaskListPage> createState() => _TaskListPageState();
}

class _TaskListPageState extends ConsumerState<TaskListPage> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final selectedWorkspaceId = ref.watch(selectedWorkspaceProvider);

    if (user == null) {
      return const AppEmptyState(
        title: 'Sign in to view tasks',
        subtitle: 'Please sign in to see your tasks.',
        icon: Icons.task_outlined,
      );
    }

    if (selectedWorkspaceId == null) {
      return const AppEmptyState(
        title: 'No workspace selected',
        subtitle: 'Please select a workspace from the Workspaces tab.',
        icon: Icons.workspaces_outlined,
      );
    }

    final workspaceId = selectedWorkspaceId;
    final tasksAsync = ref.watch(taskListProvider(workspaceId));
    final filter = ref.watch(taskFilterProvider(workspaceId));

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(AppStrings.tasks),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.go(AppRoutes.taskCreate),
            tooltip: AppStrings.addTask,
          ),
        ],
      ),
      body: tasksAsync.when(
        data: (tasks) {
          final filtered = _applyFilter(tasks, filter);
          if (filtered.isEmpty) {
            return AppEmptyState(
              title: AppStrings.noItems,
              subtitle: 'Create your first task to get started.',
              icon: Icons.task_outlined,
              action: () => context.go(AppRoutes.taskCreate),
              actionLabel: AppStrings.addTask,
            );
          }
          return Column(
            children: [
              _buildSearchAndFilter(context, ref, workspaceId, filter),
              Expanded(
                child: ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final task = filtered[index];
                    return _TaskCard(task: task, workspaceId: workspaceId);
                  },
                ),
              ),
            ],
          );
        },
        loading: () => const AppPageLoading(message: AppStrings.loading),
        error: (error, _) => AppErrorState(
          message: error.toString(),
          onRetry: () => ref.invalidate(taskListProvider(workspaceId)),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go(AppRoutes.taskCreate),
        label: const Text(AppStrings.addTask),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSearchAndFilter(BuildContext context, WidgetRef ref, String workspaceId, TaskFilter filter) {
    return Container(
      color: Theme.of(context).cardTheme.color,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppTextField(
            label: 'Search tasks',
            hint: 'Search by title',
            icon: Icons.search,
            controller: _searchController,
            onChanged: (v) => ref.read(taskFilterProvider(workspaceId).notifier).state =
                filter.copyWith(query: v),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _FilterChip(
                label: AppStrings.allTasks,
                selected: filter.status == null && filter.priority == null,
                onSelected: () => ref.read(taskFilterProvider(workspaceId).notifier).state =
                    const TaskFilter(),
              ),
              ...TaskStatus.values.map((s) => _FilterChip(
                    label: s.label,
                    selected: filter.status == s,
                    color: s.color,
                    onSelected: () => ref.read(taskFilterProvider(workspaceId).notifier).state =
                        filter.copyWith(status: s),
                  )),
              ...TaskPriority.values.map((p) => _FilterChip(
                    label: p.label,
                    selected: filter.priority == p,
                    color: p.color,
                    onSelected: () => ref.read(taskFilterProvider(workspaceId).notifier).state =
                        filter.copyWith(priority: p),
                  )),
            ],
          ),
        ],
      ),
    );
  }

  List<TaskEntity> _applyFilter(List<TaskEntity> tasks, TaskFilter filter) {
    return tasks.where((task) {
      if (filter.status != null && task.status != filter.status) return false;
      if (filter.priority != null && task.priority != filter.priority) return false;
      if (filter.query != null && filter.query!.isNotEmpty) {
        if (!task.title.toLowerCase().contains(filter.query!.toLowerCase())) return false;
      }
      return true;
    }).toList();
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    this.color,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final Color? color;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      selected: selected,
      onSelected: (_) => onSelected(),
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: selected ? Colors.white : AppColors.textSecondary,
        ),
      ),
      backgroundColor: AppColors.surfaceVariant,
      selectedColor: color ?? AppColors.primary,
      checkmarkColor: Colors.white,
      side: BorderSide(
        color: selected ? (color ?? AppColors.primary) : AppColors.divider,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );
  }
}

class _TaskCard extends ConsumerWidget {
  const _TaskCard({required this.task, required this.workspaceId});

  final TaskEntity task;
  final String workspaceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overdue = task.isOverdue;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        contentPadding: const EdgeInsets.all(14),
        leading: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: task.status == TaskStatus.done ? Colors.transparent : Colors.white,
            border: Border.all(
              color: task.status == TaskStatus.done ? AppColors.success : AppColors.divider,
              width: 2,
            ),
            shape: BoxShape.circle,
          ),
          child: task.status == TaskStatus.done
              ? const Icon(Icons.check, size: 16, color: AppColors.success)
              : null,
        ),
        title: Text(
          task.title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: task.status == TaskStatus.done ? AppColors.textSecondary : AppColors.textPrimary,
            decoration: task.status == TaskStatus.done
                ? TextDecoration.lineThrough
                : TextDecoration.none,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            if (task.description.isNotEmpty)
              Text(
                task.description,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
            if (task.dueDate != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.schedule, size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Text(
                    '${task.dueDate!.day}/${task.dueDate!.month}/${task.dueDate!.year}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: overdue ? AppColors.error : AppColors.textSecondary,
                    ),
                  ),
                  if (overdue) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        AppStrings.overdue,
                        style: TextStyle(fontSize: 10, color: AppColors.error, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
        trailing: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: task.priority.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                task.priority.label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: task.priority.color,
                ),
              ),
            ),
          ],
        ),
        onTap: () => context.go('${AppRoutes.taskDetail}/${task.id}'),
      ),
    );
  }
}
