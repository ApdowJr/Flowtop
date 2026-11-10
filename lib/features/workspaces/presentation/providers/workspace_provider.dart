import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flowtop/features/workspaces/data/models/workspace_model.dart';
import 'package:flowtop/features/workspaces/data/repositories/workspace_repository_impl.dart';
import 'package:flowtop/features/workspaces/domain/entities/workspace_entity.dart';
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

  Future<void> createWorkspace(WorkspaceEntity workspace) async {
    state = const AsyncValue.loading();
    try {
      final id = await _repository.createWorkspace(workspace);
      state = AsyncValue.data([
        ...(state.valueOrNull ?? []),
        workspace.copyWith(id: id),
      ]);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateWorkspace(String workspaceId, WorkspaceEntity workspace) async {
    state = const AsyncValue.loading();
    try {
      await _repository.updateWorkspace(workspaceId, workspace);
      state = AsyncValue.data([
        for (final w in state.valueOrNull ?? [])
          if (w.id == workspaceId) workspace.copyWith(id: workspaceId) else w,
      ]);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteWorkspace(String workspaceId) async {
    state = const AsyncValue.loading();
    try {
      await _repository.deleteWorkspace(workspaceId);
      state = AsyncValue.data([
        for (final w in state.valueOrNull ?? [])
          if (w.id != workspaceId) w,
      ]);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
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

  Future<void> changeRole(String userId, WorkspaceRole role) async {
    state = const AsyncValue.loading();
    try {
      await _repository.changeMemberRole(_workspaceId, userId, role);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> removeMember(String userId) async {
    state = const AsyncValue.loading();
    try {
      await _repository.removeMember(_workspaceId, userId);
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

/// Workspace members provider — family over workspace ID.
final workspaceMembersProvider = StateNotifierProvider.family<
    WorkspaceMembersNotifier, AsyncValue<List<WorkspaceMemberEntity>>, String>(
  (ref, workspaceId) {
    final repository = ref.watch(workspaceRepositoryProvider);
    return WorkspaceMembersNotifier(repository, workspaceId);
  },
);
