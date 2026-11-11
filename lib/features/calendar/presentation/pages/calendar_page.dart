import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:flowtop/core/constants/app_constants.dart';
import 'package:flowtop/core/di/injection_container.dart';
import 'package:flowtop/core/widgets/app_empty_state.dart';
import 'package:flowtop/core/widgets/app_error_state.dart';
import 'package:flowtop/features/tasks/domain/entities/task_entity.dart';

/// Shows due dates from the currently selected workspace.
class CalendarPage extends ConsumerStatefulWidget {
  const CalendarPage({super.key});
  @override
  ConsumerState<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends ConsumerState<CalendarPage> {
  CalendarFormat _format = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final workspaceId = ref.watch(selectedWorkspaceProvider);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.calendar)),
      body: workspaceId == null
          ? AppEmptyState(title: 'Choose your workspace', subtitle: 'Select a workspace to see your calendar.', icon: Icons.calendar_today_outlined,
              actionLabel: 'Choose workspace', action: () => context.go(AppRoutes.workspaces))
          : ref.watch(taskListProvider(workspaceId)).when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => AppErrorState(message: 'Could not load your calendar.', onRetry: () => ref.invalidate(taskListProvider(workspaceId))),
              data: (tasks) {
                List<TaskEntity> tasksOn(DateTime day) => tasks.where((task) => task.dueDate != null && isSameDay(task.dueDate, day)).toList();
                final selectedTasks = tasksOn(_selectedDay);
                return Column(children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TableCalendar<TaskEntity>(
                      firstDay: DateTime.utc(2020, 1, 1), lastDay: DateTime.utc(2100, 12, 31),
                      focusedDay: _focusedDay, calendarFormat: _format,
                      availableCalendarFormats: const {CalendarFormat.month: 'Month', CalendarFormat.week: 'Week'},
                      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                      eventLoader: tasksOn,
                      onDaySelected: (selected, focused) => setState(() { _selectedDay = selected; _focusedDay = focused; }),
                      onFormatChanged: (format) => setState(() => _format = format),
                      onPageChanged: (focused) => _focusedDay = focused,
                      headerStyle: const HeaderStyle(titleCentered: true),
                      calendarStyle: CalendarStyle(
                        selectedDecoration: BoxDecoration(color: theme.colorScheme.primary, shape: BoxShape.circle),
                        selectedTextStyle: TextStyle(color: theme.colorScheme.onPrimary),
                        todayDecoration: BoxDecoration(color: theme.colorScheme.primary.withValues(alpha: .2), shape: BoxShape.circle),
                        markerDecoration: BoxDecoration(color: theme.colorScheme.primary, shape: BoxShape.circle),
                      ),
                    ),
                  ),
                  Padding(padding: const EdgeInsets.fromLTRB(20, 18, 20, 8), child: Row(children: [
                    Expanded(child: Text(DateFormat('EEEE, MMM d').format(_selectedDay), style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700))),
                    Text('${selectedTasks.length} ${selectedTasks.length == 1 ? 'task' : 'tasks'}', style: theme.textTheme.bodyMedium),
                  ])),
                  Expanded(child: selectedTasks.isEmpty
                      ? const Center(child: Text('No tasks due on this day.'))
                      : ListView.builder(
                          padding: const EdgeInsets.only(bottom: 24), itemCount: selectedTasks.length,
                          itemBuilder: (context, index) {
                            final task = selectedTasks[index];
                            return Card(child: ListTile(
                              leading: Icon(task.status == TaskStatus.done ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded, color: theme.colorScheme.primary),
                              title: Text(task.title), subtitle: Text(task.status.label),
                              trailing: const Icon(Icons.chevron_right_rounded),
                              onTap: () => context.go('${AppRoutes.taskDetail}/${task.id}'),
                            ));
                          },
                        )),
                ]);
              },
            ),
    );
  }
}
