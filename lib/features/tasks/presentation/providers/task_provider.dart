import 'dart:async';
import 'package:flowtop/core/di/injection_container.dart' show selectedWorkspaceProvider;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flowtop/features/tasks/domain/entities/task_entity.dart';
import 'package:flowtop/features/tasks/domain/entities/subtask_entity.dart';
import 'package:flowtop/features/tasks/domain/repositories/task_repository.dart';
import 'package:flowtop/features/tasks/data/repositories/task_repository_impl.dart';
import 'package:flowtop/features/projects/presentation/providers/project_provider.dart';

/// Task repository provider.
final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  final firestore = FirebaseFirestore.instance;
  return TaskRepositoryImpl(firestore);
});

/// Filter criteria for the task list.
class TaskFilter {
  const TaskFilter({
    this.status,
    this.priority,
    this.query,
    this.assigneeId,
  });

  final TaskStatus? status;
  final TaskPriority? priority;
  final String? query;
  final String? assigneeId;

  TaskFilter copyWith({
    TaskStatus? status,
    TaskPriority? priority,
    String? query,
    String? assigneeId,
  }) {
    return TaskFilter(
      status: status ?? this.status,
      priority: priority ?? this.priority,
      query: query ?? this.query,
      assigneeId: assigneeId ?? this.assigneeId,
    );
  }
}

/// Notifier for the task list of a workspace.
class TaskListNotifier extends StateNotifier<AsyncValue<List<TaskEntity>>> {
  TaskListNotifier(this._repository, this._workspaceId, this._ref)
      : super(const AsyncValue.loading()) {
    _watch();
  }

  final TaskRepository _repository;
  final String _workspaceId;
  final Ref _ref;
  StreamSubscription<List<TaskEntity>>? _subscription;
  TaskFilter _filter = const TaskFilter();

  void _watch() {
    _subscription?.cancel();
    _subscription = _repository.watchTasks(
      workspaceId: _workspaceId,
      projectId: null,
      assigneeId: _filter.assigneeId,
      status: _filter.status,
      priority: _filter.priority,
      query: _filter.query,
    ).listen(
      (tasks) => state = AsyncValue.data(tasks),
      onError: (e) => state = AsyncValue.error(e, StackTrace.current),
    );
  }

  void setFilter(TaskFilter filter) {
    _filter = filter;
    _watch();
  }

  void clearFilter() {
    _filter = const TaskFilter();
    _watch();
  }

  Future<void> createTask(TaskEntity task) async {
    final old = state.value;
    state = const AsyncValue.loading();
    try {
      await _repository.createTask(task);
      state = AsyncValue.data(old ?? const []);
      if (task.projectId != null) {
        _ref
            .read(projectListProvider(_workspaceId).notifier)
            .recalculateProgress(task.projectId!);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateTask(String taskId, TaskEntity task) async {
    final old = state.value;
    state = const AsyncValue.loading();
    try {
      await _repository.updateTask(taskId, task);
      state = AsyncValue.data(old ?? const []);
      if (task.projectId != null) {
        _ref
            .read(projectListProvider(_workspaceId).notifier)
            .recalculateProgress(task.projectId!);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteTask(String taskId) async {
    final old = state.value;
    state = const AsyncValue.loading();
    try {
      await _repository.deleteTask(_workspaceId, taskId);
      state = AsyncValue.data(old?.where((t) => t.id != taskId).toList() ?? const []);
      TaskEntity? deleted;
      if (old != null) {
        for (final item in old) { if (item.id == taskId) { deleted = item; break; } }
      }
      if (deleted?.projectId != null) {
        _ref
            .read(projectListProvider(_workspaceId).notifier)
            .recalculateProgress(deleted!.projectId!);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> toggleCompletion(String taskId, bool completed) async {
    final old = state.value;
    state = const AsyncValue.loading();
    try {
      await _repository.toggleTaskCompletion(_workspaceId, taskId, completed);
      state = AsyncValue.data(old ?? const []);
      TaskEntity? task;
      if (old != null) {
        for (final item in old) { if (item.id == taskId) { task = item; break; } }
      }
      if (task?.projectId != null) {
        _ref
            .read(projectListProvider(_workspaceId).notifier)
            .recalculateProgress(task!.projectId!);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

/// Provider factory for a workspace's task list.
final taskListProvider = StateNotifierProvider.family<
    TaskListNotifier, AsyncValue<List<TaskEntity>>, String>(
  (ref, workspaceId) {
    final repository = ref.watch(taskRepositoryProvider);
    return TaskListNotifier(repository, workspaceId, ref);
  },
);

/// Current filter provider for a workspace.
final taskFilterProvider = StateProvider.family<TaskFilter, String>((ref, workspaceId) {
  return const TaskFilter();
});

/// Single task provider — watches a task stream from Firestore.
final taskProvider = StreamProvider.family<TaskEntity?, String>((ref, taskId) {
  final repository = ref.watch(taskRepositoryProvider);
  final workspaceId = ref.watch(selectedWorkspaceProvider);
  if (workspaceId == null) return Stream.value(null);
  return repository.watchTask(workspaceId, taskId);
});

/// Subtasks notifier family.
/// Key is a MapEntry where key = workspaceId and value = taskId.
final subtasksProvider = StreamProvider.family<
    List<SubtaskEntity>, MapEntry<String, String>>((ref, key) {
  final repository = ref.watch(taskRepositoryProvider);
  return repository.watchSubtasks(key.key, key.value);
});
