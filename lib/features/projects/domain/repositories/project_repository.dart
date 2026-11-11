import 'package:flowtop/features/projects/domain/entities/project_entity.dart';

abstract class ProjectRepository {
  Stream<List<ProjectEntity>> watchProjects(String workspaceId);
  Stream<ProjectEntity?> watchProject(String workspaceId, String projectId);
  Future<List<ProjectEntity>> getProjects(String workspaceId);
  Future<String> createProject(ProjectEntity project);
  Future<void> updateProject(String projectId, ProjectEntity project);
  Future<void> deleteProject(String workspaceId, String projectId);

  /// Recalculate project progress based on task statuses.
  /// Call this after task CRUD operations to keep progress in sync.
  Future<void> recalculateProgress(String workspaceId, String projectId);
}
