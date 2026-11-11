import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flowtop/core/constants/app_constants.dart';
import 'package:flowtop/core/widgets/app_loading.dart';
import 'package:flowtop/core/widgets/app_empty_state.dart';
import 'package:flowtop/core/widgets/app_error_state.dart';
import 'package:flowtop/features/projects/domain/entities/project_entity.dart';
import 'package:flowtop/features/projects/presentation/providers/project_provider.dart';
import 'package:flowtop/features/tasks/domain/entities/task_entity.dart';
import 'package:flowtop/features/tasks/presentation/providers/task_provider.dart';

/// Project detail page showing project info, progress, and associated tasks.
class ProjectDetailPage extends ConsumerWidget {
  const ProjectDetailPage({super.key, required this.projectId});

  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectAsync = ref.watch(projectProvider(projectId));

    return projectAsync.when(
      data: (project) {
        if (project == null) {
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            appBar: AppBar(title: const Text(AppStrings.projectDetails)),
            body: const AppEmptyState(
              title: 'Project not found',
              subtitle: 'The requested project does not exist or you do not have access to it.',
              icon: Icons.folder_outlined,
            ),
          );
        }
        return _buildProjectDetail(context, ref, project);
      },
      loading: () => Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(title: const Text(AppStrings.projectDetails)),
        body: const AppPageLoading(message: AppStrings.loading),
      ),
      error: (error, _) => Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(title: const Text(AppStrings.projectDetails)),
        body: AppErrorState(
          message: error.toString(),
          onRetry: () => ref.invalidate(projectProvider(projectId)),
        ),
      ),
    );
  }

  Widget _buildProjectDetail(BuildContext context, WidgetRef ref, ProjectEntity project) {
    final tasksAsync = ref.watch(taskListProvider(project.workspaceId));

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(project.name),
      ),
      body: Column(
        children: [
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    project.name,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  if (project.description.isNotEmpty) ...[
                    Text(
                      project.description,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Color(project.color).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${(project.progress * 100).toInt()}% complete',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(project.color),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${project.taskIds.length} tasks',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  LinearProgressIndicator(
                    value: project.progress,
                    backgroundColor: AppColors.divider,
                    color: Color(project.color),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: tasksAsync.when(
              data: (tasks) {
                if (tasks.isEmpty) {
                  return const AppEmptyState(
                    title: 'No tasks',
                    subtitle: 'Add tasks to this project to track progress.',
                    icon: Icons.task_outlined,
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    if (task.projectId != project.id) return const SizedBox.shrink();
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
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
                            fontSize: 14,
                            color: task.status == TaskStatus.done ? Theme.of(context).colorScheme.onSurfaceVariant : Theme.of(context).colorScheme.onSurface,
                            decoration: task.status == TaskStatus.done
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                          ),
                        ),
                        trailing: const Icon(Icons.chevron_right, size: 18),
                        onTap: () => context.go('${AppRoutes.taskDetail}/${task.id}'),
                      ),
                    );
                  },
                );
              },
              loading: () => const AppPageLoading(message: AppStrings.loading),
              error: (error, _) => AppErrorState(
                message: error.toString(),
                onRetry: () => ref.invalidate(taskListProvider(project.workspaceId)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
