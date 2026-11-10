import 'package:flowtop/features/workspaces/domain/entities/workspace_entity.dart';

abstract class WorkspaceRepository {
  Stream<List<WorkspaceEntity>> watchWorkspacesForUser(String userId);
  Future<List<WorkspaceEntity>> getWorkspacesForUser(String userId);
  Future<String> createWorkspace(WorkspaceEntity workspace);
  Future<void> updateWorkspace(String workspaceId, WorkspaceEntity workspace);
  Future<void> deleteWorkspace(String workspaceId);
  Stream<List<WorkspaceMemberEntity>> watchMembers(String workspaceId);
  Future<void> inviteMember(String workspaceId, String email, WorkspaceRole role, {required String invitedBy});
  Future<void> changeMemberRole(String workspaceId, String userId, WorkspaceRole role);
  Future<void> removeMember(String workspaceId, String userId);
}
