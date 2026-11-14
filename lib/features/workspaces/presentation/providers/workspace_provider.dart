import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flowtop/features/auth/presentation/providers/auth_provider.dart';
import 'package:flowtop/features/workspaces/data/repositories/workspace_repository_impl.dart';
import 'package:flowtop/features/workspaces/domain/entities/workspace_entity.dart';
import 'package:flowtop/features/workspaces/domain/entities/workspace_invitation_entity.dart';
import 'package:flowtop/features/workspaces/domain/repositories/workspace_repository.dart';

/// Workspace repository provider — wired to the real Firestore implementation.
final workspaceRepositoryProvider = Provider<WorkspaceRepository>((ref) {
  final firestore = FirebaseFirestore.instance;
  return WorkspaceRepositoryImpl(firestore);
});

/// Current authenticated user ID provider.
final currentUserIdProvider = Provider<String?>((ref) {
  return FirebaseAuth.instance.currentUser?.uid;
});

/// Workspace list notifier — watches workspaces for the current user.
class WorkspaceListNotifier extends StateNotifier<AsyncValue<List<WorkspaceEntity>>> {
  WorkspaceListNotifier(this._repository, this._userIdStream)
      : super(const AsyncValue.loading()) {
    _subscription = _userIdStream.listen((userId) {
      if (userId == null) {
        state = const AsyncValue.data([]);
        return;
      }
      _watchWorkspaces(userId);
    });
  }

  final WorkspaceRepository _repository;
  final Stream<String?> _userIdStream;
  StreamSubscription<String?>? _subscription;
  StreamSubscription<List<WorkspaceEntity>>? _workspaceSubscription;

  void _watchWorkspaces(String userId) {
    _workspaceSubscription?.cancel();
    _workspaceSubscription = _repository.watchWorkspacesForUser(userId).listen(
      (workspaces) => state = AsyncValue.data(workspaces),
      onError: (e) => state = AsyncValue.error(e, StackTrace.current),
    );
  }

  Future<void> createWorkspace(
    WorkspaceEntity workspace, {
    String? ownerEmail,
    String? ownerName,
  }) async {
    state = const AsyncValue.loading();
    try {
      final id = await _repository.createWorkspace(
        workspace,
        ownerEmail: ownerEmail,
        ownerName: ownerName,
      );
      state = AsyncValue.data([
        ...(state.valueOrNull ?? []),
        workspace.copyWith(id: id),
      ]);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Saves the editable fields of a workspace and shows the result right away.
  /// The workspace list only refreshes when memberships change, so the local
  /// state is updated here too. Failures are rethrown for the caller to report.
  Future<void> updateWorkspace(String workspaceId, WorkspaceEntity workspace) async {
    await _repository.updateWorkspace(workspaceId, workspace);
    state = AsyncValue.data([
      for (final w in state.valueOrNull ?? const <WorkspaceEntity>[])
        if (w.id == workspaceId)
          w.copyWith(
            name: workspace.name,
            description: workspace.description,
            color: workspace.color,
          )
        else
          w,
    ]);
  }

  /// Deletes a workspace with everything in it. Failures are rethrown.
  Future<void> deleteWorkspace(String workspaceId) async {
    await _repository.deleteWorkspace(workspaceId);
    state = AsyncValue.data([
      for (final w in state.valueOrNull ?? const <WorkspaceEntity>[])
        if (w.id != workspaceId) w,
    ]);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _workspaceSubscription?.cancel();
    super.dispose();
  }
}

/// Workspace list provider — family over user ID.
final workspaceListProvider = StateNotifierProvider.family<
    WorkspaceListNotifier, AsyncValue<List<WorkspaceEntity>>, String?>(
  (ref, userId) {
    // Create a stream that emits the user ID once.
    final userIdStream = Stream<String?>.value(userId);
    final repository = ref.watch(workspaceRepositoryProvider);
    return WorkspaceListNotifier(repository, userIdStream);
  },
);

/// Members list notifier for a workspace.
class WorkspaceMembersNotifier extends StateNotifier<AsyncValue<List<WorkspaceMemberEntity>>> {
  WorkspaceMembersNotifier(this._repository, this._workspaceId)
      : super(const AsyncValue.loading()) {
    _watch();
  }

  final WorkspaceRepository _repository;
  final String _workspaceId;
  StreamSubscription<List<WorkspaceMemberEntity>>? _subscription;

  void _watch() {
    _subscription?.cancel();
    _subscription = _repository.watchMembers(_workspaceId).listen(
      (members) => state = AsyncValue.data(members),
      onError: (e) => state = AsyncValue.error(e, StackTrace.current),
    );
  }

  /// Changes the role of a member. The list updates through the members stream.
  /// Failures are rethrown so the caller can tell the user.
  Future<void> changeRole(String userId, WorkspaceRole role) {
    return _repository.changeMemberRole(_workspaceId, userId, role);
  }

  /// Removes a member (or lets the signed-in user leave). The list updates
  /// through the members stream. Failures are rethrown.
  Future<void> removeMember(String userId) {
    return _repository.removeMember(_workspaceId, userId);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

/// Workspace members provider — family over workspace ID.
final workspaceMembersProvider = StateNotifierProvider.family<
    WorkspaceMembersNotifier, AsyncValue<List<WorkspaceMemberEntity>>, String>(
  (ref, workspaceId) {
    final repository = ref.watch(workspaceRepositoryProvider);
    return WorkspaceMembersNotifier(repository, workspaceId);
  },
);

/// Invitations addressed to the signed-in user, in every workspace.
///
/// Only users with a verified email may read them (see firestore.rules), so
/// everybody else gets an empty list instead of a permission error.
final myInvitationsProvider =
    StreamProvider.autoDispose<List<WorkspaceInvitationEntity>>((ref) {
  final user = ref.watch(currentUserProvider);
  final email = user?.email;
  if (user == null || email == null || email.isEmpty || !user.emailVerified) {
    return Stream.value(const <WorkspaceInvitationEntity>[]);
  }
  return ref.watch(workspaceRepositoryProvider).watchInvitationsForEmail(email);
});

/// The invitations the signed-in user can still accept or decline.
final openInvitationsProvider =
    Provider.autoDispose<List<WorkspaceInvitationEntity>>((ref) {
  final now = DateTime.now();
  final invitations = ref.watch(myInvitationsProvider).valueOrNull ?? const [];
  return [
    for (final invitation in invitations)
      if (invitation.isOpenAt(now)) invitation,
  ];
});

/// Every invitation sent from a workspace (pending, accepted and declined).
final workspaceInvitationsProvider = StreamProvider.autoDispose
    .family<List<WorkspaceInvitationEntity>, String>((ref, workspaceId) {
  return ref.watch(workspaceRepositoryProvider).watchWorkspaceInvitations(workspaceId);
});

/// The signed-in user's role in a workspace, or null while it is unknown.
final myWorkspaceRoleProvider =
    Provider.autoDispose.family<WorkspaceRole?, String>((ref, workspaceId) {
  final uid = ref.watch(currentUserProvider)?.uid;
  final members = ref.watch(workspaceMembersProvider(workspaceId)).valueOrNull;
  if (uid == null || members == null) return null;
  for (final member in members) {
    if (member.userId == uid) return member.role;
  }
  return null;
});
