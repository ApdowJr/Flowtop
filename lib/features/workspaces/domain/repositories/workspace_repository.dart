import 'package:flowtop/features/workspaces/domain/entities/workspace_entity.dart';
import 'package:flowtop/features/workspaces/domain/entities/workspace_invitation_entity.dart';

abstract class WorkspaceRepository {
  Stream<List<WorkspaceEntity>> watchWorkspacesForUser(String userId);
  Future<List<WorkspaceEntity>> getWorkspacesForUser(String userId);

  /// Creates the workspace and the owner's membership record. [ownerEmail] and
  /// [ownerName] are stored on that record so other members can see who the
  /// owner is.
  Future<String> createWorkspace(
    WorkspaceEntity workspace, {
    String? ownerEmail,
    String? ownerName,
  });
  Future<void> updateWorkspace(String workspaceId, WorkspaceEntity workspace);
  Future<void> deleteWorkspace(String workspaceId);
  Stream<List<WorkspaceMemberEntity>> watchMembers(String workspaceId);
  Future<List<WorkspaceMemberEntity>> getMembers(String workspaceId);
  Future<void> changeMemberRole(String workspaceId, String userId, WorkspaceRole role);
  Future<void> removeMember(String workspaceId, String userId);

  // Invitations
  Future<void> inviteMember(String workspaceId, String email, WorkspaceRole role, {required String invitedBy});

  /// Every invitation of a workspace (visible to its members).
  Stream<List<WorkspaceInvitationEntity>> watchWorkspaceInvitations(String workspaceId);

  /// Invitations addressed to [email] in any workspace (visible to that user).
  Stream<List<WorkspaceInvitationEntity>> watchInvitationsForEmail(String email);
  Future<void> acceptInvitation(String workspaceId, String invitationId);
  Future<void> declineInvitation(String workspaceId, String invitationId);

  /// Withdraws an invitation that was sent from the workspace.
  Future<void> revokeInvitation(String workspaceId, String invitationId);
}
