import 'package:flutter_test/flutter_test.dart';
import 'package:flowtop/features/tasks/domain/entities/task_entity.dart';

void main() {
  group('TaskEntity', () {
    final task = TaskEntity(
      id: 't1',
      title: 'Finish report',
      status: TaskStatus.todo,
      priority: TaskPriority.high,
      category: TaskCategory.work,
      ownerId: 'u1',
      dueDate: DateTime(2026, 11, 15),
    );

    test('isOverdue is true when due date is in the past and not done', () {
      final overdue = task.copyWith(dueDate: DateTime(2020, 1, 1));
      expect(overdue.isOverdue, isTrue);
    });

    test('isOverdue is false when completed', () {
      final done = task.copyWith(status: TaskStatus.done, dueDate: DateTime(2020, 1, 1));
      expect(done.isOverdue, isFalse);
    });

    test('copyWith updates fields', () {
      final updated = task.copyWith(title: 'Updated title');
      expect(updated.title, equals('Updated title'));
      expect(updated.id, equals('t1'));
    });

    test('priority and status labels are non-empty', () {
      expect(task.priority.label, isNotEmpty);
      expect(task.status.label, isNotEmpty);
      expect(task.category.label, isNotEmpty);
    });
  });
}
