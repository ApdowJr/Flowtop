import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flowtop/features/workspaces/domain/entities/workspace_entity.dart';
import 'package:flowtop/features/workspaces/domain/entities/workspace_invitation_entity.dart';
import 'package:flowtop/features/workspaces/domain/repositories/workspace_repository.dart';
import 'package:flowtop/features/workspaces/data/models/workspace_invitation_model.dart';
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

  CollectionReference<Map<String, dynamic>> _invitationsRef(String workspaceId) =>
      _workspaceDoc(workspaceId).collection('invitations');

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
          if (doc.reference.parent.parent != null)
            doc.reference.parent.parent!.id: WorkspaceMemberModel.fromMap(doc.id, doc.data()).toEntity().role,
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
        if (doc.reference.parent.parent != null)
          doc.reference.parent.parent!.id: WorkspaceMemberModel.fromMap(doc.id, doc.data()).toEntity().role,
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
  Future<String> createWorkspace(
    WorkspaceEntity workspace, {
    String? ownerEmail,
    String? ownerName,
  }) async {
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
    final email = ownerEmail?.trim().toLowerCase();
    final name = ownerName?.trim();
    await _memberDoc(id, workspace.ownerId).set(
      WorkspaceMemberModel.fromEntity(
        WorkspaceMemberEntity(
          workspaceId: id,
          userId: workspace.ownerId,
          role: WorkspaceRole.owner,
          joinedAt: now,
          email: (email == null || email.isEmpty) ? null : email,
          displayName: (name == null || name.isEmpty) ? null : name,
        ),
      ).toMap(),
    );

    return id;
  }

  @override
  Future<void> updateWorkspace(String workspaceId, WorkspaceEntity workspace) async {
    // Only the fields a user can edit. The rest of the document (owner, creation
    // time) must stay untouched.
    await _workspaceDoc(workspaceId).update({
      'name': workspace.name,
      'description': workspace.description,
      'color': workspace.color,
    });
  }

  @override
  Future<void> deleteWorkspace(String workspaceId) async {
    final workspace = _workspaceDoc(workspaceId);

    // Content first, in chunks (a batch holds at most 500 writes). The caller
    // stays a member until the very end, which the security rules need to
    // authorize every one of these deletes. Activity logs are append-only for
    // clients, so they are left behind; nobody can read them without access.
    final tasks = await workspace.collection('tasks').get();
    for (final task in tasks.docs) {
      await _deleteAll(await task.reference.collection('subtasks').get());
    }
    await _deleteAll(tasks);
    for (final name in const ['projects', 'categories', 'task_attachments']) {
      await _deleteAll(await workspace.collection(name).get());
    }

    // Finally the invitations, every membership (the owner's included) and the
    // workspace document in one atomic batch. The rules only let the owner drop
    // their own membership in the same batch that deletes the workspace.
    final batch = _firestore.batch();
    final invitations = await _invitationsRef(workspaceId).get();
    for (final doc in invitations.docs) {
      batch.delete(doc.reference);
    }
    final members = await _membersRef(workspaceId).get();
    for (final doc in members.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(workspace);
    await batch.commit();
  }

  /// Deletes every document of [snapshot], at most 400 per batch.
  Future<void> _deleteAll(QuerySnapshot<Map<String, dynamic>> snapshot) async {
    const chunkSize = 400;
    final docs = snapshot.docs;
    for (var start = 0; start < docs.length; start += chunkSize) {
      final batch = _firestore.batch();
      final end = start + chunkSize < docs.length ? start + chunkSize : docs.length;
      for (final doc in docs.sublist(start, end)) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }
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
  Stream<List<WorkspaceInvitationEntity>> watchWorkspaceInvitations(String workspaceId) {
    return _invitationsRef(workspaceId).snapshots().map((snapshot) {
      return _newestFirst(snapshot.docs, workspaceId);
    });
  }

  @override
  Stream<List<WorkspaceInvitationEntity>> watchInvitationsForEmail(String email) {
    return _firestore
        .collectionGroup('invitations')
        .where('email', isEqualTo: email.trim().toLowerCase())
        .snapshots()
        .map((snapshot) => _newestFirst(snapshot.docs, ''));
  }

  List<WorkspaceInvitationEntity> _newestFirst(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    String fallbackWorkspaceId,
  ) {
    final invitations = [
      for (final doc in docs)
        WorkspaceInvitationModel.fromMap(
          doc.id,
          doc.data(),
          fallbackWorkspaceId: doc.reference.parent.parent?.id ?? fallbackWorkspaceId,
        ),
    ];
    invitations.sort((a, b) {
      final first = a.createdAt;
      final second = b.createdAt;
      if (first == null && second == null) return 0;
      if (first == null) return -1; // Still being written: show it first.
      if (second == null) return 1;
      return second.compareTo(first);
    });
    return invitations;
  }

  @override
  Future<void> acceptInvitation(String workspaceId, String invitationId) async {
    // Accepting creates the membership, which only the server may do.
    final functions = _functions ?? FirebaseFunctions.instance;
    await functions.httpsCallable('acceptInvitation').call({
      'workspaceId': workspaceId,
      'invitationId': invitationId,
    });
  }

  @override
  Future<void> declineInvitation(String workspaceId, String invitationId) async {
    await _invitationsRef(workspaceId).doc(invitationId).update({'status': 'declined'});
  }

  @override
  Future<void> revokeInvitation(String workspaceId, String invitationId) async {
    await _invitationsRef(workspaceId).doc(invitationId).delete();
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
