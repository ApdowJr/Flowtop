import 'package:equatable/equatable.dart';
import 'package:flowtop/features/workspaces/domain/entities/workspace_entity.dart';

enum InvitationStatus { pending, accepted, declined }

/// An invitation to join a workspace, addressed to an email address.
class WorkspaceInvitationEntity extends Equatable {
  const WorkspaceInvitationEntity({
    required this.id,
    required this.workspaceId,
    required this.email,
    required this.role,
    required this.status,
    this.workspaceName,
    this.invitedBy,
    this.invitedByName,
    this.createdAt,
    this.expiresAt,
  });

  final String id;
  final String workspaceId;
  final String email;
  final WorkspaceRole role;
  final InvitationStatus status;

  /// Copied into the invitation when it is created, because an invitee cannot
  /// read the workspace itself before joining it.
  final String? workspaceName;
  final String? invitedBy;
  final String? invitedByName;
  final DateTime? createdAt;
  final DateTime? expiresAt;

  /// Whether the invitation ran out before it was answered.
  bool isExpiredAt(DateTime now) {
    final expiry = expiresAt;
    return expiry != null && !expiry.isAfter(now);
  }

  /// Whether the invitee can still accept or decline it.
  bool isOpenAt(DateTime now) =>
      status == InvitationStatus.pending && !isExpiredAt(now);

  @override
  List<Object?> get props => [
        id,
        workspaceId,
        email,
        role,
        status,
        workspaceName,
        invitedBy,
        invitedByName,
        createdAt,
        expiresAt,
      ];
}
