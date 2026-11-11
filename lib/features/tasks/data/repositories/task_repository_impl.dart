import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flowtop/features/tasks/domain/entities/task_entity.dart';
import 'package:flowtop/features/tasks/domain/entities/subtask_entity.dart';
import 'package:flowtop/features/tasks/domain/repositories/task_repository.dart';
import 'package:flowtop/features/tasks/data/models/task_model.dart';

class TaskRepositoryImpl implements TaskRepository {
  TaskRepositoryImpl(this._firestore);

  final FirebaseFirestore _firestore;

  static const String _tasksCollection = 'tasks';

  CollectionReference<Map<String, dynamic>> _tasksRef(String workspaceId) =>
      _firestore.collection('workspaces').doc(workspaceId).collection(_tasksCollection);

  DocumentReference<Map<String, dynamic>> _taskDoc(String workspaceId, String taskId) =>
      _tasksRef(workspaceId).doc(taskId);

  /// Subtasks are stored as a subcollection of the task doc:
  /// /workspaces/{workspaceId}/tasks/{taskId}/subtasks/{subtaskId}
  CollectionReference<Map<String, dynamic>> _subtasksRef(
      String workspaceId, String taskId) {
    return _taskDoc(workspaceId, taskId).collection('subtasks');
  }

  @override
  Stream<List<TaskEntity>> watchTasks({
    required String workspaceId,
    String? projectId,
    String? assigneeId,
    TaskStatus? status,
    TaskPriority? priority,
    String? query,
  }) async* {
    Query<Map<String, dynamic>> queryRef = _tasksRef(workspaceId);
    // Firestore supports at most one range/inquality filter; client-side filter
    // for text search after fetching (bounded by Security Rules page size).
    if (projectId != null) queryRef = queryRef.where('projectId', isEqualTo: projectId);
    if (assigneeId != null) queryRef = queryRef.where('assigneeId', isEqualTo: assigneeId);

    yield* queryRef.snapshots().map((snapshot) {
      List<TaskEntity> tasks = snapshot.docs
          .map((doc) => TaskModel.fromMap(doc.id, doc.data()).toEntity())
          .toList();

      if (status != null) {
        tasks = tasks.where((t) => t.status == status).toList();
      }
      if (priority != null) {
        tasks = tasks.where((t) => t.priority == priority).toList();
      }
      if (query != null && query.isNotEmpty) {
        final q = query.toLowerCase();
        tasks = tasks.where((t) => t.title.toLowerCase().contains(q)).toList();
      }

      tasks.sort((a, b) {
        final ad = a.dueDate?.millisecondsSinceEpoch;
        final bd = b.dueDate?.millisecondsSinceEpoch;
        if (ad == null) return bd == null ? 0 : 1;
        if (bd == null) return -1;
        return ad.compareTo(bd); // soonest due first
      });
      return tasks;
    });
  }

  @override
  Stream<TaskEntity?> watchTask(String workspaceId, String taskId) {
    return _taskDoc(workspaceId, taskId).snapshots().map((doc) {
      final data = doc.data();
      return data == null ? null : TaskModel.fromMap(doc.id, data).toEntity();
    });
  }

  @override
  Future<List<TaskEntity>> getTasks({
    required String workspaceId,
    String? projectId,
    String? assigneeId,
  }) async {
    Query<Map<String, dynamic>> ref = _tasksRef(workspaceId);
    if (projectId != null) ref = ref.where('projectId', isEqualTo: projectId);
    if (assigneeId != null) ref = ref.where('assigneeId', isEqualTo: assigneeId);
    final snapshot = await ref.get();
    return snapshot.docs
        .map((doc) => TaskModel.fromMap(doc.id, doc.data()).toEntity())
        .toList();
  }

  @override
  Future<String> createTask(TaskEntity task) async {
    // Validate workspaceId before constructing any Firestore document path.
    if (task.workspaceId == null || task.workspaceId!.isEmpty) {
      throw ArgumentError('Task must belong to a workspace to create.');
    }

    final id = _firestore.collection(_tasksCollection).doc().id;
    final now = DateTime.now();
    final model = TaskModel.fromEntity(task.copyWith(
      id: id,
      createdAt: now,
      updatedAt: now,
    ));
    await _taskDoc(task.workspaceId!, id).set(model.toMap());
    return id;
  }

  @override
  Future<void> updateTask(String taskId, TaskEntity task) async {
    // Determine workspace from task (must be set by caller).
    final workspaceId = task.workspaceId;
    if (workspaceId == null) {
      throw ArgumentError('Task must belong to a workspace to update.');
    }
    await _taskDoc(workspaceId, taskId).update(
      TaskModel.fromEntity(task.copyWith(updatedAt: DateTime.now(), id: taskId)).toMap(),
    );
  }

  @override
  Future<void> deleteTask(String workspaceId, String taskId) async {
    final subtasks = await _subtasksRef(workspaceId, taskId).get();
    if (subtasks.docs.length > 499) {
      throw StateError('Too many subtasks to delete in one operation.');
    }
    final batch = _firestore.batch();
    for (final subtask in subtasks.docs) {
      batch.delete(subtask.reference);
    }
    batch.delete(_taskDoc(workspaceId, taskId));
    await batch.commit();
  }

  @override
  Future<void> toggleTaskCompletion(String workspaceId, String taskId, bool completed) async {
    await _taskDoc(workspaceId, taskId).update({
      'status': completed ? 'done' : 'todo',
      if (completed) 'completedAt': Timestamp.fromDate(DateTime.now())
      else 'completedAt': FieldValue.delete(),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  @override
  Stream<List<SubtaskEntity>> watchSubtasks(String workspaceId, String taskId) {
    return _subtasksRef(workspaceId, taskId).snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) {
            final data = doc.data();
            return SubtaskEntity(
              id: doc.id,
              taskId: data['taskId'] as String? ?? taskId,
              workspaceId: data['workspaceId'] as String? ?? workspaceId,
              title: data['title'] as String? ?? '',
              isCompleted: (data['isCompleted'] as bool?) ?? false,
              createdAt: _toDateTime(data['createdAt']),
            );
          })
          .toList();
    });
  }

  @override
  Future<void> createSubtask(String workspaceId, SubtaskEntity subtask) async {
    final id = _firestore.collection(_tasksCollection).doc().id;
    await _subtasksRef(workspaceId, subtask.taskId).doc(id).set({
      'id': id,
      'taskId': subtask.taskId,
      'workspaceId': workspaceId,
      'title': subtask.title,
      'isCompleted': subtask.isCompleted,
      'createdAt': Timestamp.fromDate(subtask.createdAt ?? DateTime.now()),
    });
  }

  @override
  Future<void> updateSubtask(String workspaceId, String subtaskId, SubtaskEntity subtask) async {
    await _subtasksRef(workspaceId, subtask.taskId).doc(subtaskId).update({
      'title': subtask.title,
      'isCompleted': subtask.isCompleted,
    });
  }

  @override
  Future<void> deleteSubtask(String workspaceId, String taskId, String subtaskId) async {
    await _subtasksRef(workspaceId, taskId).doc(subtaskId).delete();
  }

  static DateTime? _toDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}
