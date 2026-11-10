import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:flowtop/core/constants/app_constants.dart';
import 'package:flowtop/core/di/injection_container.dart';
import 'package:flowtop/features/tasks/domain/entities/task_entity.dart';

/// Personal overview, scoped to the selected workspace.
class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final workspaceId = ref.watch(selectedWorkspaceProvider);
    final user = ref.watch(currentUserProvider);
    final name = user?.displayName?.trim();
    final greeting = name == null || name.isEmpty ? 'there' : name.split(' ').first;
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
          child: Center(child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(color: theme.colorScheme.primary, borderRadius: BorderRadius.circular(12)),
                  child: Icon(Icons.check_rounded, color: theme.colorScheme.onPrimary, size: 23),
                ),
                const SizedBox(width: 10),
                Text('flowTop', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -.6)),
                const Spacer(),
                _HeaderButton(icon: Icons.workspaces_outlined, label: 'Workspaces', onTap: () => context.go(AppRoutes.workspaces)),
                const SizedBox(width: 8),
                _HeaderButton(icon: Icons.person_outline_rounded, label: 'Profile', onTap: () => context.go(AppRoutes.profile)),
              ]),
              const SizedBox(height: 28),
              Center(child: Column(children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: theme.colorScheme.primary, width: 1.5)),
                  child: CircleAvatar(radius: 36, backgroundColor: theme.cardColor,
                    child: Icon(Icons.person_rounded, size: 42, color: theme.colorScheme.primary)),
                ),
                const SizedBox(height: 12),
                Text('Hello, $greeting', textAlign: TextAlign.center, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -.6)),
                const SizedBox(height: 3),
                Text('Your space to get things done', style: theme.textTheme.bodyMedium, textAlign: TextAlign.center),
              ])),
              const SizedBox(height: 25),
              if (workspaceId == null)
                _WorkspacePrompt(onPressed: () => context.go(AppRoutes.workspaces))
              else
                ref.watch(taskListProvider(workspaceId)).when(
                  loading: () => const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator())),
                  error: (_, __) => _WorkspacePrompt(title: 'Could not load your tasks', subtitle: 'Check your connection and try again.', action: 'Try again', onPressed: () => ref.invalidate(taskListProvider(workspaceId))),
                  data: (tasks) => _Overview(tasks: tasks),
                ),
            ]),
          )),
        ),
      ),
    );
  }
}

class _HeaderButton extends StatelessWidget {
  const _HeaderButton({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: label, onPressed: onTap, icon: Icon(icon, size: 21),
    style: IconButton.styleFrom(backgroundColor: Theme.of(context).cardColor),
  );
}

class _WorkspacePrompt extends StatelessWidget {
  const _WorkspacePrompt({required this.onPressed, this.title = 'Your space to focus', this.subtitle = 'Select or create a workspace to bring your tasks together.', this.action = 'Choose workspace'});
  final VoidCallback onPressed;
  final String title, subtitle, action;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(22)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(Icons.space_dashboard_outlined, color: theme.colorScheme.primary, size: 30),
        const SizedBox(height: 18),
        Text(title, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8), Text(subtitle, style: theme.textTheme.bodyMedium),
        const SizedBox(height: 20), FilledButton(onPressed: onPressed, child: Text(action)),
      ]),
    );
  }
}

class _Overview extends StatelessWidget {
  const _Overview({required this.tasks});
  final List<TaskEntity> tasks;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final done = tasks.where((task) => task.status == TaskStatus.done).length;
    final open = tasks.length - done;
    final overdue = tasks.where((task) => task.isOverdue).length;
    final progress = tasks.isEmpty ? 0.0 : done / tasks.length;
    final upcoming = tasks.where((task) => task.status != TaskStatus.done && task.dueDate != null && !task.isOverdue).toList()
      ..sort((a, b) => a.dueDate!.compareTo(b.dueDate!));
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(child: _Metric(icon: Icons.timelapse_rounded, value: '${(progress * 100).round()}%', label: 'Complete')),
        _divider(context),
        Expanded(child: _Metric(icon: Icons.check_circle_rounded, value: '$done', label: 'Done')),
        _divider(context),
        Expanded(child: _Metric(icon: Icons.layers_rounded, value: '$open', label: 'Open')),
      ]),
      const SizedBox(height: 26),
      Row(children: [
        Expanded(child: Text('This week', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700))),
        TextButton(onPressed: () => context.go(AppRoutes.calendar), child: const Text('Calendar  ›')),
      ]),
      const SizedBox(height: 6),
      _WeekStrip(tasks: tasks),
      const SizedBox(height: 18),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.cardColor, borderRadius: BorderRadius.circular(22),
          border: Border.all(color: theme.dividerColor.withValues(alpha: .45)),
        ),
        child: Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('YOUR PROGRESS', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.primary, letterSpacing: 1.1, fontWeight: FontWeight.w800)),
            const SizedBox(height: 9),
            Text(tasks.isEmpty ? 'Let’s get started' : 'Keep it up!', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 5),
            Text(tasks.isEmpty ? 'Add your first task and find your flow.' : '$done of ${tasks.length} tasks completed', style: theme.textTheme.bodyMedium),
            const SizedBox(height: 16),
            ClipRRect(borderRadius: BorderRadius.circular(8), child: LinearProgressIndicator(value: progress, minHeight: 5, color: theme.colorScheme.primary, backgroundColor: theme.dividerColor)),
          ])),
          const SizedBox(width: 20),
          Container(width: 68, height: 68, decoration: BoxDecoration(shape: BoxShape.circle, color: theme.colorScheme.primary.withValues(alpha: .13)), child: Icon(Icons.bolt_rounded, color: theme.colorScheme.primary, size: 40)),
        ]),
      ),
      const SizedBox(height: 12),
      Material(
        color: theme.colorScheme.primary, borderRadius: BorderRadius.circular(22),
        child: InkWell(
          onTap: () => context.go(AppRoutes.taskCreate), borderRadius: BorderRadius.circular(22),
          child: Padding(padding: const EdgeInsets.all(18), child: Row(children: [
            Container(width: 52, height: 52, decoration: BoxDecoration(color: theme.colorScheme.onPrimary.withValues(alpha: .12), borderRadius: BorderRadius.circular(16)), child: Icon(Icons.add_task_rounded, color: theme.colorScheme.onPrimary)),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Create a new task', style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onPrimary, fontWeight: FontWeight.w800)),
              const SizedBox(height: 3),
              Text('Turn your next idea into action', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onPrimary.withValues(alpha: .75))),
            ])),
            Icon(Icons.arrow_forward_rounded, color: theme.colorScheme.onPrimary),
          ])),
        ),
      ),
      const SizedBox(height: 24),
      Row(children: [
        Expanded(child: Text('Coming up', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700))),
        TextButton(onPressed: () => context.go(AppRoutes.taskList), child: const Text('See all  ›')),
      ]),
      if (upcoming.isEmpty)
        Container(width: double.infinity, padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(20)),
          child: Text(overdue > 0 ? '$overdue overdue ${overdue == 1 ? 'task needs' : 'tasks need'} your attention.' : 'No upcoming deadlines. You’re all caught up!', style: theme.textTheme.bodyMedium))
      else
        ...upcoming.take(3).map((task) => Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            leading: Icon(Icons.radio_button_unchecked_rounded, color: theme.colorScheme.primary),
            title: Text(task.title, maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text(DateFormat('MMM d, yyyy').format(task.dueDate!)),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.go('${AppRoutes.taskDetail}/${task.id}'),
          ),
        )),
    ]);
  }

  Widget _divider(BuildContext context) => Container(width: 1, height: 38, color: Theme.of(context).dividerColor);
}

class _Metric extends StatelessWidget {
  const _Metric({required this.icon, required this.value, required this.label});
  final IconData icon;
  final String value, label;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(children: [
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, color: theme.colorScheme.primary, size: 19), const SizedBox(width: 6),
        Flexible(child: Text(value, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800), overflow: TextOverflow.ellipsis)),
      ]),
      const SizedBox(height: 5), Text(label, style: theme.textTheme.bodySmall),
    ]);
  }
}

class _WeekStrip extends StatelessWidget {
  const _WeekStrip({required this.tasks});
  final List<TaskEntity> tasks;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final monday = today.subtract(Duration(days: today.weekday - 1));
    return Row(children: List.generate(7, (index) {
      final day = monday.add(Duration(days: index));
      final active = day == today;
      final hasTask = tasks.any((task) => task.dueDate != null && DateUtils.isSameDay(task.dueDate, day));
      return Expanded(child: Padding(
        padding: EdgeInsets.only(right: index == 6 ? 0 : 5),
        child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: active ? theme.colorScheme.primary : Colors.transparent)),
            child: Column(children: [
              Container(width: 5, height: 5, decoration: BoxDecoration(shape: BoxShape.circle, color: hasTask ? theme.colorScheme.primary : theme.dividerColor)),
              const SizedBox(height: 10),
              Text(DateFormat('E').format(day).substring(0, 1), style: theme.textTheme.bodySmall),
              const SizedBox(height: 3),
              Text('${day.day}', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface, fontWeight: active ? FontWeight.w800 : FontWeight.w500)),
            ]),
        ),
      ));
    }));
  }
}
