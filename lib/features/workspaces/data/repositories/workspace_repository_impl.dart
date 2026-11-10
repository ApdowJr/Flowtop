import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flowtop/features/workspaces/domain/entities/workspace_entity.dart';
import 'package:flowtop/features/workspaces/domain/repositories/workspace_repository.dart';
import 'package:flowtop/features/workspaces/data/models/workspace_model.dart';

class WorkspaceRepositoryImpl implements WorkspaceRepository {
  WorkspaceRepositoryImpl(this._firestore, [this._functions]);

  final FirebaseFirestore _firestore;
  final FirebaseFunctions? _functions;

  static const String _workspacesCollection = 'workspaces';

  CollectionReference<Map<String, dynamic>> _workspacesRef() =>
      _firestore.collection(_workspacesCollection);

  CollectionReference<Map<String, dynamic>> _membersRef(String workspaceId) =>
      _workspacesRef().doc(workspaceId).collection('members');

  DocumentReference<Map<String, dynamic>> _workspaceDoc(String workspaceId) =>
      _workspacesRef().doc(workspaceId);

  DocumentReference<Map<String, dynamic>> _memberDoc(
      String workspaceId, String userId) {
    return _membersRef(workspaceId).doc(userId);
  }

  /// Watch workspaces for a specific user ID (used by the provider with auth context).
  Stream<List<WorkspaceEntity>> watchWorkspacesForUser(String userId) {
    return _firestore
        .collectionGroup('members')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .asyncExpand((memberSnapshot) async* {
      if (memberSnapshot.docs.isEmpty) {
        yield const [];
        return;
      }
      final roles = {
        for (final doc in memberSnapshot.docs)
          if (doc.ref.parent.parent != null)
            doc.ref.parent.parent!.id: WorkspaceMemberModel.fromMap(doc.id, doc.data()).toEntity().role,
      };
      final workspaceIds = roles.keys;

      final workspaces = await Future.wait(
        workspaceIds.map((id) => _workspaceDoc(id).get()),
      );
      yield workspaces
          .where((doc) => doc.exists)
          .map((doc) => WorkspaceModel.fromMap(doc.id, doc.data()!).toEntity().copyWith(role: roles[doc.id]))
          .toList();
    });
  }

  /// Get all workspaces for a specific user.
  Future<List<WorkspaceEntity>> getWorkspacesForUser(String userId) async {
    final memberSnapshot = await _firestore
        .collectionGroup('members')
        .where('userId', isEqualTo: userId)
        .get();

    if (memberSnapshot.docs.isEmpty) return const [];

    final roles = {
      for (final doc in memberSnapshot.docs)
        if (doc.ref.parent.parent != null)
          doc.ref.parent.parent!.id: WorkspaceMemberModel.fromMap(doc.id, doc.data()).toEntity().role,
    };
    final workspaceIds = roles.keys;

    final workspaces = await Future.wait(
      workspaceIds.map((id) => _workspaceDoc(id).get()),
    );
    return workspaces
        .where((doc) => doc.exists)
        .map((doc) => WorkspaceModel.fromMap(doc.id, doc.data()!).toEntity().copyWith(role: roles[doc.id]))
        .toList();
  }

  @override
  Future<String> createWorkspace(WorkspaceEntity workspace) async {
    final id = _firestore.collection(_workspacesCollection).doc().id;
    final now = DateTime.now();

    // Create the workspace document.
    final model = WorkspaceModel.fromEntity(workspace.copyWith(
      id: id,
      createdAt: now,
      isPersonal: workspace.isPersonal,
    ));
    await _workspaceDoc(id).set(model.toMap());

    // Create the owner membership record.
    await _memberDoc(id, workspace.ownerId).set(
      WorkspaceMemberModel.fromEntity(
        WorkspaceMemberEntity(
          workspaceId: id,
          userId: workspace.ownerId,
          role: WorkspaceRole.owner,
          joinedAt: now,
        ),
      ).toMap(),
    );

    return id;
  }

  @override
  Future<void> updateWorkspace(String workspaceId, WorkspaceEntity workspace) async {
    await _workspaceDoc(workspaceId).update(
      WorkspaceModel.fromEntity(
        workspace.copyWith(id: workspaceId),
      ).toMap(),
    );
  }

  @override
  Future<void> deleteWorkspace(String workspaceId) async {
    // Delete all subcollections then the workspace doc.
    final batch = _firestore.batch();

    // Delete members.
    final membersSnap = await _membersRef(workspaceId).get();
    for (final doc in membersSnap.docs) {
      batch.delete(doc.reference);
    }

    // Delete invitations.
    final invSnap = await _workspaceDoc(workspaceId).collection('invitations').get();
    for (final doc in invSnap.docs) {
      batch.delete(doc.reference);
    }

    // Delete projects.
    final projSnap = await _workspaceDoc(workspaceId).collection('projects').get();
    for (final doc in projSnap.docs) {
      batch.delete(doc.reference);
    }

    // Delete tasks and their subtasks.
    final tasksSnap = await _workspaceDoc(workspaceId).collection('tasks').get();
    for (final taskDoc in tasksSnap.docs) {
      batch.delete(taskDoc.reference);
      final subsSnap = await taskDoc.reference.collection('subtasks').get();
      for (final subDoc in subsSnap.docs) {
        batch.delete(subDoc.reference);
      }
    }

    // Delete categories.
    final catSnap = await _workspaceDoc(workspaceId).collection('categories').get();
    for (final doc in catSnap.docs) {
      batch.delete(doc.reference);
    }

    // Delete task attachments metadata.
    final attSnap =
        await _workspaceDoc(workspaceId).collection('task_attachments').get();
    for (final doc in attSnap.docs) {
      batch.delete(doc.reference);
    }

    // Delete activity logs.
    final logSnap =
        await _workspaceDoc(workspaceId).collection('activity_logs').get();
    for (final doc in logSnap.docs) {
      batch.delete(doc.reference);
    }

    batch.delete(_workspaceDoc(workspaceId));
    await batch.commit();
  }

  @override
  Stream<List<WorkspaceMemberEntity>> watchMembers(String workspaceId) {
    return _membersRef(workspaceId).snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => WorkspaceMemberModel.fromMap(doc.id, doc.data()).toEntity())
          .toList();
    });
  }

  @override
  Future<List<WorkspaceMemberEntity>> getMembers(String workspaceId) async {
    final snapshot = await _membersRef(workspaceId).get();
    return snapshot.docs
        .map((doc) => WorkspaceMemberModel.fromMap(doc.id, doc.data()).toEntity())
        .toList();
  }

  @override
  Future<void> inviteMember(String workspaceId, String email, WorkspaceRole role,
      {required String invitedBy}) async {
    // Delegate to the createInvitation Cloud Function for server-side
    // authorization, role validation, email normalization, expiry handling,
    // and FCM notification dispatch. The function validates the caller is a
    // workspace member with invite rights, normalizes the email to lowercase,
    // enforces role constraints (only owners can grant owner role), sets a
    // 7-day expiry, and dispatches an FCM invitation notification.
    final functions = _functions ?? FirebaseFunctions.instance;
    final callable = functions.httpsCallable('createInvitation');
    await callable.call({
      'workspaceId': workspaceId,
      'email': email.toLowerCase(),
      'role': _roleName(role),
    });
  }

  @override
  Future<void> changeMemberRole(String workspaceId, String userId, WorkspaceRole role) async {
    await _memberDoc(workspaceId, userId).update({'role': _roleName(role)});
  }

  @override
  Future<void> removeMember(String workspaceId, String userId) async {
    await _memberDoc(workspaceId, userId).delete();
  }

  static String _roleName(WorkspaceRole role) {
    switch (role) {
      case WorkspaceRole.owner: return 'owner';
      case WorkspaceRole.admin: return 'admin';
      case WorkspaceRole.manager: return 'manager';
      case WorkspaceRole.member: return 'member';
      case WorkspaceRole.viewer: return 'viewer';
    }
  }
}
