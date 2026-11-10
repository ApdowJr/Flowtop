import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flowtop/features/tasks/data/repositories/task_repository_impl.dart';
import 'package:flowtop/features/tasks/domain/entities/task_entity.dart';
import 'package:flowtop/features/tasks/domain/repositories/task_repository.dart';
import 'package:flowtop/features/tasks/presentation/providers/task_provider.dart';
import 'package:flowtop/features/projects/data/repositories/project_repository_impl.dart';
import 'package:flowtop/features/projects/domain/entities/project_entity.dart';
import 'package:flowtop/features/projects/domain/repositories/project_repository.dart';

class MockTaskRepository extends Mock implements TaskRepository {}

class MockProjectRepository extends Mock implements ProjectRepository {}

TaskEntity _task({
  String id = 't1',
  String? projectId = 'p1',
  String? workspaceId = 'ws1',
}) {
  return TaskEntity(
    id: id,
    title: 'Task $id',
    status: TaskStatus.todo,
    priority: TaskPriority.medium,
    category: TaskCategory.personal,
    ownerId: 'u1',
    workspaceId: workspaceId,
    projectId: projectId,
  );
}

void main() {
  group('TaskListNotifier project progress recalculation', () {
    late ProviderContainer container;
    late MockTaskRepository mockTaskRepository;
    late MockProjectRepository mockProjectRepository;

    setUp(() {
      mockTaskRepository = MockTaskRepository();
      mockProjectRepository = MockProjectRepository();
      container = ProviderContainer(
        overrides: [
          taskRepositoryProvider.overrideWithValue(mockTaskRepository),
          projectRepositoryProvider.overrideWithValue(mockProjectRepository),
        ],
      );

      // Prevent ProjectListNotifier._watch() from throwing on null stream
      when(() => mockProjectRepository.watchProjects(any))
          .thenAnswer((_) => Stream.value([]));
    });

    tearDown(() {
      container.dispose();
    });

    test('createTask recalculates progress when task has projectId', () async {
      final task = _task(projectId: 'p1');

      when(() => mockTaskRepository.createTask(any))
          .thenAnswer((_) async => 't1');
      when(() => mockProjectRepository.recalculateProgress('ws1', 'p1'))
          .thenAnswer((_) async => null);

      final notifier = container.read(taskListProvider('ws1').notifier);
      await notifier.createTask(task);

      verify(() => mockProjectRepository.recalculateProgress('ws1', 'p1'))
          .called(1);
    });

    test('createTask does not recalculate when projectId is null', () async {
      final task = _task(projectId: null);

      when(() => mockTaskRepository.createTask(any))
          .thenAnswer((_) async => 't1');

      final notifier = container.read(taskListProvider('ws1').notifier);
      await notifier.createTask(task);

      verifyNever(() => mockProjectRepository.recalculateProgress(any, any));
    });

    test('updateTask recalculates progress when task has projectId', () async {
      final task = _task(id: 't1', projectId: 'p1');

      when(() => mockTaskRepository.updateTask('t1', any))
          .thenAnswer((_) async => null);
      when(() => mockProjectRepository.recalculateProgress('ws1', 'p1'))
          .thenAnswer((_) async => null);

      final notifier = container.read(taskListProvider('ws1').notifier);
      await notifier.updateTask('t1', task);

      verify(() => mockProjectRepository.recalculateProgress('ws1', 'p1'))
          .called(1);
    });

    test('updateTask does not recalculate when projectId is null', () async {
      final task = _task(id: 't1', projectId: null);

      when(() => mockTaskRepository.updateTask('t1', any))
          .thenAnswer((_) async => null);

      final notifier = container.read(taskListProvider('ws1').notifier);
      await notifier.updateTask('t1', task);

      verifyNever(() => mockProjectRepository.recalculateProgress(any, any));
    });

    test('deleteTask recalculates progress when deleted task has projectId',
        () async {
      final task = _task(id: 't1', projectId: 'p1');

      // Populate notifier state so deleteTask can find the task in old state
      when(() => mockTaskRepository.watchTasks(
            workspaceId: 'ws1',
            projectId: any(named: 'projectId'),
            assigneeId: any(named: 'assigneeId'),
            status: any(named: 'status'),
            priority: any(named: 'priority'),
            query: any(named: 'query'),
          ))
          .thenAnswer((_) => Stream.value([task]));

      when(() => mockTaskRepository.deleteTask('t1'))
          .thenAnswer((_) async => null);
      when(() => mockProjectRepository.recalculateProgress('ws1', 'p1'))
          .thenAnswer((_) async => null);

      final notifier = container.read(taskListProvider('ws1').notifier);

      // Wait for the watch stream to emit and populate state
      await Future.delayed(Duration.zero);
      expect(notifier.state.value, hasLength(1));

      await notifier.deleteTask('t1');

      verify(() => mockProjectRepository.recalculateProgress('ws1', 'p1'))
          .called(1);
    });

    test('deleteTask does not recalculate when deleted task has null projectId',
        () async {
      final task = _task(id: 't1', projectId: null, workspaceId: 'ws1');

      when(() => mockTaskRepository.watchTasks(
            workspaceId: 'ws1',
            projectId: any(named: 'projectId'),
            assigneeId: any(named: 'assigneeId'),
            status: any(named: 'status'),
            priority: any(named: 'priority'),
            query: any(named: 'query'),
          ))
          .thenAnswer((_) => Stream.value([task]));

      when(() => mockTaskRepository.deleteTask('t1'))
          .thenAnswer((_) async => null);

      final notifier = container.read(taskListProvider('ws1').notifier);
      await Future.delayed(Duration.zero);
      expect(notifier.state.value, hasLength(1));

      await notifier.deleteTask('t1');

      verifyNever(() => mockProjectRepository.recalculateProgress(any, any));
    });

    test('toggleCompletion recalculates progress when task has projectId',
        () async {
      final task = _task(id: 't1', projectId: 'p1');

      when(() => mockTaskRepository.watchTasks(
            workspaceId: 'ws1',
            projectId: any(named: 'projectId'),
            assigneeId: any(named: 'assigneeId'),
            status: any(named: 'status'),
            priority: any(named: 'priority'),
            query: any(named: 'query'),
          ))
          .thenAnswer((_) => Stream.value([task]));

      when(() => mockTaskRepository.toggleTaskCompletion('t1', true))
          .thenAnswer((_) async => null);
      when(() => mockProjectRepository.recalculateProgress('ws1', 'p1'))
          .thenAnswer((_) async => null);

      final notifier = container.read(taskListProvider('ws1').notifier);
      await Future.delayed(Duration.zero);
      expect(notifier.state.value, hasLength(1));

      await notifier.toggleCompletion('t1', true);

      verify(() => mockProjectRepository.recalculateProgress('ws1', 'p1'))
          .called(1);
    });

    test('deleteTask recalculates progress after createTask populates state',
        () async {
      final task = _task(id: '', projectId: 'p1');

      when(() => mockTaskRepository.createTask(any))
          .thenAnswer((_) async => 't1');
      when(() => mockTaskRepository.watchTasks(
            workspaceId: 'ws1',
            projectId: any(named: 'projectId'),
            assigneeId: any(named: 'assigneeId'),
            status: any(named: 'status'),
            priority: any(named: 'priority'),
            query: any(named: 'query'),
          ))
          .thenAnswer((_) => Stream.value([task]));
      when(() => mockTaskRepository.deleteTask('t1'))
          .thenAnswer((_) async => null);
      when(() => mockProjectRepository.recalculateProgress('ws1', 'p1'))
          .thenAnswer((_) async => null);

      final notifier = container.read(taskListProvider('ws1').notifier);
      await notifier.createTask(task);
      await Future.delayed(Duration.zero); // populate state from watch
      await notifier.deleteTask('t1');

      // Called once from createTask, once from deleteTask
      verify(() => mockProjectRepository.recalculateProgress('ws1', 'p1'))
          .called(2);
    });

    test('toggleCompletion recalculates progress after createTask populates state',
        () async {
      final task = _task(id: '', projectId: 'p1');

      when(() => mockTaskRepository.createTask(any))
          .thenAnswer((_) async => 't1');
      when(() => mockTaskRepository.watchTasks(
            workspaceId: 'ws1',
            projectId: any(named: 'projectId'),
            assigneeId: any(named: 'assigneeId'),
            status: any(named: 'status'),
            priority: any(named: 'priority'),
            query: any(named: 'query'),
          ))
          .thenAnswer((_) => Stream.value([task]));
      when(() => mockTaskRepository.toggleTaskCompletion('t1', true))
          .thenAnswer((_) async => null);
      when(() => mockProjectRepository.recalculateProgress('ws1', 'p1'))
          .thenAnswer((_) async => null);

      final notifier = container.read(taskListProvider('ws1').notifier);
      await notifier.createTask(task);
      await Future.delayed(Duration.zero); // populate state from watch
      await notifier.toggleCompletion('t1', true);

      // Called once from createTask, once from toggleCompletion
      verify(() => mockProjectRepository.recalculateProgress('ws1', 'p1'))
          .called(2);
    });
  });

  group('TaskEntity null workspaceId', () {
    test('workspaceId can be null', () {
      final task = TaskEntity(
        id: 't1',
        title: 'Orphan task',
        status: TaskStatus.todo,
        priority: TaskPriority.medium,
        category: TaskCategory.personal,
        ownerId: 'u1',
        workspaceId: null,
      );
      expect(task.workspaceId, isNull);
    });

    test('copyWith preserves null workspaceId', () {
      final task = TaskEntity(
        id: 't1',
        title: 'Task',
        status: TaskStatus.todo,
        priority: TaskPriority.medium,
        category: TaskCategory.personal,
        ownerId: 'u1',
        workspaceId: null,
      );
      final updated = task.copyWith(title: 'Updated');
      expect(updated.workspaceId, isNull);
      expect(updated.title, equals('Updated'));
    });

    test('copyWith can set workspaceId from null to a value', () {
      final task = TaskEntity(
        id: 't1',
        title: 'Task',
        status: TaskStatus.todo,
        priority: TaskPriority.medium,
        category: TaskCategory.personal,
        ownerId: 'u1',
        workspaceId: null,
      );
      final updated = task.copyWith(workspaceId: 'ws1');
      expect(updated.workspaceId, equals('ws1'));
    });
  });
}
