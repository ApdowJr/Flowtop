import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flowtop/features/projects/data/models/project_model.dart';
import 'package:flowtop/features/projects/domain/entities/project_entity.dart';
import 'package:flowtop/features/projects/domain/repositories/project_repository.dart';

final projectRepositoryProvider = Provider<ProjectRepository>((ref) {
  return ProjectRepositoryImpl(FirebaseFirestore.instance);
});

class ProjectListNotifier extends StateNotifier<AsyncValue<List<ProjectEntity>>> {
  ProjectListNotifier(this._repository, this._workspaceId)
      : super(const AsyncValue.loading()) {
    _watch();
  }

  final ProjectRepository _repository;
  final String _workspaceId;
  StreamSubscription? _sub;

  void _watch() {
    _sub?.cancel();
    _sub = _repository.watchProjects(_workspaceId).listen(
      (p) => state = AsyncValue.data(p),
      onError: (e) => state = AsyncValue.error(e, StackTrace.current),
    );
  }

  Future<void> createProject(ProjectEntity p) async {
    state = const AsyncValue.loading();
    try {
      final id = await _repository.createProject(p);
      state = AsyncValue.data([
        ...(state.valueOrNull ?? []),
        p.copyWith(id: id),
      ]);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> recalculateProgress(String projectId) async {
    await _repository.recalculateProgress(_workspaceId, projectId);
  }

  @override
  void dispose() { _sub?.cancel(); super.dispose(); }
}

final projectListProvider = StateNotifierProvider.family<
    ProjectListNotifier, AsyncValue<List<ProjectEntity>>, String>(
  (ref, workspaceId) => ProjectListNotifier(
    ref.watch(projectRepositoryProvider), workspaceId,
  ),
);

/// Single project provider — watches a project stream from Firestore.
final projectProvider = StreamProvider.family<ProjectEntity?, String>((ref, projectId) {
  final repository = ref.watch(projectRepositoryProvider);
  return repository.watchProject(projectId);
});
