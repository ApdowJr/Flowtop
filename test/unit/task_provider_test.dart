import 'package:flutter_test/flutter_test.dart';
import 'package:flowtop/core/di/injection_container.dart' show selectedWorkspaceProvider;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flowtop/features/tasks/domain/entities/task_entity.dart';
import 'package:flowtop/features/tasks/domain/repositories/task_repository.dart';
import 'package:flowtop/features/tasks/presentation/providers/task_provider.dart';

class MockTaskRepository extends Mock implements TaskRepository {}

void main() {
  group('TaskProvider', () {
    late ProviderContainer container;
    late MockTaskRepository mockRepository;

    setUp(() {
      mockRepository = MockTaskRepository();
      container = ProviderContainer(
        overrides: [
          selectedWorkspaceProvider.overrideWith((ref) => 'ws1'),
          taskRepositoryProvider.overrideWithValue(mockRepository),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('taskProvider returns data when task exists', () async {
      final task = TaskEntity(
        id: 't1',
        title: 'Test Task',
        status: TaskStatus.todo,
        priority: TaskPriority.medium,
        category: TaskCategory.personal,
        ownerId: 'u1',
        workspaceId: 'ws1',
      );

      when(() => mockRepository.watchTask('ws1', 't1')).thenAnswer(
        (_) => Stream.value(task),
      );

      await container.read(taskProvider('t1').future);
      expect(container.read(taskProvider('t1')).value, equals(task));
    });

    test('taskProvider returns null when task does not exist', () async {
      when(() => mockRepository.watchTask('ws1', 'missing')).thenAnswer(
        (_) => Stream.value(null),
      );

      await container.read(taskProvider('missing').future);
      expect(container.read(taskProvider('missing')).value, isNull);
    });
  });
}
