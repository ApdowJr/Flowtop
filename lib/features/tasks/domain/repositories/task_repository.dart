import 'package:flowtop/features/tasks/domain/entities/task_entity.dart';
import 'package:flowtop/features/tasks/domain/entities/subtask_entity.dart';

/// Contract for task data operations.
///
/// Tasks are scoped to a workspace (personal or team). Firestore Security Rules
/// enforce that users only read/write tasks in workspaces they belong to.
abstract class TaskRepository {
  /// Stream of tasks for a workspace, optionally filtered by project/assignee.
  Stream<List<TaskEntity>> watchTasks({
    required String workspaceId,
    String? projectId,
    String? assigneeId,
    TaskStatus? status,
    TaskPriority? priority,
    String? query,
  });

  /// Stream of a single task by ID.
  Stream<TaskEntity?> watchTask(String workspaceId, String taskId);

  /// Future fetch of tasks (used for offline-first / cache reads).
  Future<List<TaskEntity>> getTasks({
    required String workspaceId,
    String? projectId,
    String? assigneeId,
  });

  /// Create a new task. Returns the created task ID.
  Future<String> createTask(TaskEntity task);

  /// Update an existing task (partial update via copyWith semantics).
  Future<void> updateTask(String taskId, TaskEntity task);

  /// Delete a task and its attachments/subtasks.
  Future<void> deleteTask(String workspaceId, String taskId);

  /// Mark a task complete/incomplete.
  Future<void> toggleTaskCompletion(String workspaceId, String taskId, bool completed);

  /// Stream of subtasks for a task within a workspace.
  Stream<List<SubtaskEntity>> watchSubtasks(String workspaceId, String taskId);

  /// Create a subtask within a workspace.
  Future<void> createSubtask(String workspaceId, SubtaskEntity subtask);

  /// Update a subtask within a workspace.
  Future<void> updateSubtask(String workspaceId, String subtaskId, SubtaskEntity subtask);

  /// Delete a subtask within a workspace.
  Future<void> deleteSubtask(String workspaceId, String taskId, String subtaskId);
}
