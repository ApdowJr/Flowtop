import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flowtop/features/projects/data/models/project_model.dart';
import 'package:flowtop/features/projects/domain/entities/project_entity.dart';
import 'package:flowtop/features/projects/domain/repositories/project_repository.dart';

class ProjectRepositoryImpl implements ProjectRepository {
  ProjectRepositoryImpl(this._firestore);

  final FirebaseFirestore _firestore;

  static const String _col = 'projects';

  CollectionReference<Map<String, dynamic>> _ref(String workspaceId) =>
      _firestore.collection('workspaces').doc(workspaceId).collection(_col);

  DocumentReference<Map<String, dynamic>> _doc(
      String workspaceId, String projectId) {
    return _ref(workspaceId).doc(projectId);
  }

  @override
  Stream<List<ProjectEntity>> watchProjects(String workspaceId) {
    return _ref(workspaceId).snapshots().map((s) =>
        s.docs.map((d) => ProjectModel.fromMap(d.id, d.data()).toEntity()).toList());
  }

  @override
  Stream<ProjectEntity?> watchProject(String workspaceId, String projectId) {
    return _doc(workspaceId, projectId).snapshots().map((doc) {
      final data = doc.data();
      return data == null ? null : ProjectModel.fromMap(doc.id, data).toEntity();
    });
  }

  @override
  Future<List<ProjectEntity>> getProjects(String workspaceId) async {
    final s = await _ref(workspaceId).get();
    return s.docs.map((d) => ProjectModel.fromMap(d.id, d.data()).toEntity()).toList();
  }

  @override
  Future<String> createProject(ProjectEntity project) async {
    final id = _firestore.collection(_col).doc().id;
    final now = DateTime.now();
    final model = ProjectModel.fromEntity(project.copyWith(
      id: id,
      updatedAt: now,
    ));
    await _ref(project.workspaceId).doc(id).set(model.toMap());
    return id;
  }

  @override
  Future<void> updateProject(String projectId, ProjectEntity project) async {
    // Determine workspace from project (must be set by caller).
    final workspaceId = project.workspaceId;
    if (workspaceId.isEmpty) {
      throw ArgumentError('Project must belong to a workspace to update.');
    }
    await _doc(workspaceId, projectId).update(
      ProjectModel.fromEntity(
        project.copyWith(updatedAt: DateTime.now(), id: projectId),
      ).toMap(),
    );
  }

  @override
  Future<void> deleteProject(String workspaceId, String projectId) async {
    // Delete all tasks associated with this project.
    final tasksSnap = await _firestore
        .collection('workspaces')
        .doc(workspaceId)
        .collection('tasks')
        .where('projectId', isEqualTo: projectId)
        .get();

    final batch = _firestore.batch();
    for (final taskDoc in tasksSnap.docs) {
      batch.delete(taskDoc.reference);
      // Delete subtasks for each task.
      final subsSnap = await taskDoc.reference.collection('subtasks').get();
      for (final subDoc in subsSnap.docs) {
        batch.delete(subDoc.reference);
      }
    }

    // Delete the project document.
    batch.delete(_doc(workspaceId, projectId));
    await batch.commit();
  }

  @override
  Future<void> recalculateProgress(String workspaceId, String projectId) async {
    final projectDoc = _doc(workspaceId, projectId);
    final projectSnap = await projectDoc.get();
    if (!projectSnap.exists) return;

    // Use the actual projectId field rather than the stale taskIds array.
    final tasksSnap = await _firestore
        .collection('workspaces')
        .doc(workspaceId)
        .collection('tasks')
        .where('projectId', isEqualTo: projectId)
        .get();

    int completed = 0;
    int total = 0;
    for (final doc in tasksSnap.docs) {
      final status = doc.data()['status'] as String?;
      total++;
      if (status == 'done') completed++;
    }

    final progress = total > 0 ? completed / total : 0.0;
    await projectDoc.update({
      'progress': progress,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }
}
