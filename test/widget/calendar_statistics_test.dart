import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flowtop/core/di/injection_container.dart';
import 'package:flowtop/features/calendar/presentation/pages/calendar_page.dart';
import 'package:flowtop/features/statistics/presentation/pages/statistics_page.dart';
import 'package:flowtop/features/tasks/domain/entities/task_entity.dart';
import 'package:flowtop/features/tasks/domain/repositories/task_repository.dart';

class MockTaskRepository extends Mock implements TaskRepository {}

void main() {
  late MockTaskRepository repository;
  setUp(() {
    repository = MockTaskRepository();
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    when(() => repository.watchTasks(workspaceId: 'ws1')).thenAnswer((_) => Stream.value([
      TaskEntity(id: 'one', title: 'Today task', ownerId: 'u1', workspaceId: 'ws1',
          status: TaskStatus.todo, priority: TaskPriority.medium, category: TaskCategory.work, dueDate: DateTime.now()),
      TaskEntity(id: 'two', title: 'Tomorrow task', ownerId: 'u1', workspaceId: 'ws1',
          status: TaskStatus.done, priority: TaskPriority.medium, category: TaskCategory.work, dueDate: tomorrow),
    ]));
  });

  Widget wrap(Widget child) => ProviderScope(overrides: [
    selectedWorkspaceProvider.overrideWith((ref) => 'ws1'),
    taskRepositoryProvider.overrideWithValue(repository),
  ], child: MaterialApp(home: child));

  testWidgets('calendar displays tasks due on the selected day', (tester) async {
    await tester.pumpWidget(wrap(const CalendarPage()));
    await tester.pumpAndSettle();
    expect(find.text('Today task'), findsOneWidget);
    expect(find.text('Tomorrow task'), findsNothing);
  });

  testWidgets('statistics calculate real workspace task counts', (tester) async {
    await tester.pumpWidget(wrap(const StatisticsPage()));
    await tester.pumpAndSettle();
    expect(find.text('50%'), findsOneWidget);
    expect(find.text('1 of 2 tasks completed'), findsOneWidget);
    expect(find.text('Completed tasks'), findsOneWidget);
  });
}
