import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flowtop/features/workspaces/domain/entities/workspace_entity.dart';
import 'package:flowtop/features/workspaces/domain/entities/workspace_invitation_entity.dart';

/// Reads invitation documents (workspaces/{id}/invitations/{invitationId}).
///
/// Invitations are created by the createInvitation Cloud Function, so there is
/// no write path here.
class WorkspaceInvitationModel {
  WorkspaceInvitationModel._();

  /// [fallbackWorkspaceId] is used for documents that lack a workspaceId field.
  static WorkspaceInvitationEntity fromMap(
    String id,
    Map<String, dynamic> map, {
    String fallbackWorkspaceId = '',
  }) {
    return WorkspaceInvitationEntity(
      id: id,
      workspaceId: map['workspaceId'] as String? ?? fallbackWorkspaceId,
      email: map['email'] as String? ?? '',
      role: _parseRole(map['role'] as String?),
      status: _parseStatus(map['status'] as String?),
      workspaceName: map['workspaceName'] as String?,
      invitedBy: map['invitedBy'] as String?,
      invitedByName: map['invitedByName'] as String?,
      createdAt: _toDateTime(map['createdAt']),
      expiresAt: _toDateTime(map['expiresAt']),
    );
  }

  static WorkspaceRole _parseRole(String? value) {
    return WorkspaceRole.values.firstWhere(
      (role) => role.name == value,
      orElse: () => WorkspaceRole.member,
    );
  }

  static InvitationStatus _parseStatus(String? value) {
    return InvitationStatus.values.firstWhere(
      (status) => status.name == value,
      // Unknown values must never look answerable.
      orElse: () => InvitationStatus.declined,
    );
  }

  static DateTime? _toDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}
