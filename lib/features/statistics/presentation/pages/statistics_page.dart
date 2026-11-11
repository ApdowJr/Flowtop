import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flowtop/core/constants/app_constants.dart';
import 'package:flowtop/core/di/injection_container.dart';
import 'package:flowtop/core/widgets/app_empty_state.dart';
import 'package:flowtop/core/widgets/app_error_state.dart';
import 'package:flowtop/features/tasks/domain/entities/task_entity.dart';

/// Workspace task statistics based on the live task stream.
class StatisticsPage extends ConsumerWidget {
  const StatisticsPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workspaceId = ref.watch(selectedWorkspaceProvider);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.statistics)),
      body: workspaceId == null
          ? AppEmptyState(title: 'Choose your workspace', subtitle: 'Select a workspace to see your statistics.', icon: Icons.bar_chart_rounded,
              actionLabel: 'Choose workspace', action: () => context.go(AppRoutes.workspaces))
          : ref.watch(taskListProvider(workspaceId)).when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => AppErrorState(message: 'Could not load your statistics.', onRetry: () => ref.invalidate(taskListProvider(workspaceId))),
              data: (tasks) {
                final done = tasks.where((task) => task.status == TaskStatus.done).length;
                final overdue = tasks.where((task) => task.isOverdue).length;
                final progress = tasks.isEmpty ? 0.0 : done / tasks.length;
                return ListView(padding: const EdgeInsets.all(20), children: [
                  Text('Your workspace at a glance', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Text(tasks.isEmpty ? 'Add a task to start tracking your progress.' : 'Based on all tasks in your selected workspace.', style: theme.textTheme.bodyMedium),
                  const SizedBox(height: 24),
                  Card(margin: EdgeInsets.zero, child: Padding(padding: const EdgeInsets.all(24), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Completion', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 10),
                    Text('${(progress * 100).round()}%', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 14),
                    LinearProgressIndicator(value: progress, minHeight: 8, borderRadius: BorderRadius.circular(8)),
                    const SizedBox(height: 10), Text('$done of ${tasks.length} tasks completed', style: theme.textTheme.bodyMedium),
                  ]))),
                  const SizedBox(height: 16),
                  _Stat(label: 'Open tasks', value: '${tasks.length - done}', icon: Icons.pending_actions_rounded),
                  _Stat(label: 'Completed tasks', value: '$done', icon: Icons.check_circle_outline_rounded),
                  _Stat(label: 'Overdue tasks', value: '$overdue', icon: Icons.schedule_rounded),
                ]);
              },
            ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, required this.icon});
  final String label, value;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 10),
    child: ListTile(leading: Icon(icon, color: Theme.of(context).colorScheme.primary), title: Text(label), trailing: Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700))),
  );
}
