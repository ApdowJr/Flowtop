import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flowtop/features/workspaces/data/models/workspace_invitation_model.dart';
import 'package:flowtop/features/workspaces/data/models/workspace_model.dart';
import 'package:flowtop/features/workspaces/domain/entities/workspace_entity.dart';
import 'package:flowtop/features/workspaces/domain/entities/workspace_invitation_entity.dart';

void main() {
  group('WorkspaceInvitationModel', () {
    test('reads a complete invitation document', () {
      final invitation = WorkspaceInvitationModel.fromMap('i1', {
        'email': 'amina@example.com',
        'role': 'manager',
        'status': 'pending',
        'workspaceId': 'w1',
        'workspaceName': 'Design studio',
        'invitedBy': 'u1',
        'invitedByName': 'Omar',
        'createdAt': Timestamp.fromDate(DateTime.utc(2026, 11, 1)),
        'expiresAt': Timestamp.fromDate(DateTime.utc(2026, 11, 8)),
      });

      expect(invitation.id, 'i1');
      expect(invitation.workspaceId, 'w1');
      expect(invitation.email, 'amina@example.com');
      expect(invitation.role, WorkspaceRole.manager);
      expect(invitation.status, InvitationStatus.pending);
      expect(invitation.workspaceName, 'Design studio');
      expect(invitation.invitedByName, 'Omar');
      expect(invitation.createdAt!.toUtc(), DateTime.utc(2026, 11, 1));
      expect(invitation.expiresAt!.toUtc(), DateTime.utc(2026, 11, 8));
    });

    test('falls back to the parent workspace id and a member role', () {
      final invitation = WorkspaceInvitationModel.fromMap(
        'i2',
        {'email': 'omar@example.com', 'status': 'accepted'},
        fallbackWorkspaceId: 'w9',
      );

      expect(invitation.workspaceId, 'w9');
      expect(invitation.role, WorkspaceRole.member);
      expect(invitation.status, InvitationStatus.accepted);
      expect(invitation.expiresAt, isNull);
    });

    test('an unknown status never looks answerable', () {
      final invitation = WorkspaceInvitationModel.fromMap('i3', {
        'email': 'omar@example.com',
        'status': 'something-new',
      });

      expect(invitation.status, InvitationStatus.declined);
      expect(invitation.isOpenAt(DateTime.utc(2026, 11, 2)), isFalse);
    });
  });

  group('WorkspaceInvitationEntity', () {
    final expiry = DateTime.utc(2026, 11, 8);

    WorkspaceInvitationEntity build(InvitationStatus status, {DateTime? expiresAt}) {
      return WorkspaceInvitationEntity(
        id: 'i1',
        workspaceId: 'w1',
        email: 'amina@example.com',
        role: WorkspaceRole.member,
        status: status,
        expiresAt: expiresAt,
      );
    }

    test('a pending invitation is open until it expires', () {
      final invitation = build(InvitationStatus.pending, expiresAt: expiry);

      expect(invitation.isOpenAt(DateTime.utc(2026, 11, 7)), isTrue);
      expect(invitation.isExpiredAt(DateTime.utc(2026, 11, 7)), isFalse);
      expect(invitation.isOpenAt(expiry), isFalse);
      expect(invitation.isExpiredAt(DateTime.utc(2026, 11, 9)), isTrue);
    });

    test('answered invitations are not open', () {
      final now = DateTime.utc(2026, 11, 2);

      expect(build(InvitationStatus.accepted, expiresAt: expiry).isOpenAt(now), isFalse);
      expect(build(InvitationStatus.declined, expiresAt: expiry).isOpenAt(now), isFalse);
    });

    test('an invitation without an expiry date stays open', () {
      expect(build(InvitationStatus.pending).isOpenAt(DateTime.utc(2030)), isTrue);
    });
  });

  group('WorkspaceMemberModel', () {
    test('keeps the name and email of a member', () {
      final model = WorkspaceMemberModel.fromMap('u1', {
        'workspaceId': 'w1',
        'userId': 'u1',
        'role': 'admin',
        'email': 'amina@example.com',
        'displayName': 'Amina Yusuf',
      });

      final entity = model.toEntity();
      expect(entity.role, WorkspaceRole.admin);
      expect(entity.email, 'amina@example.com');
      expect(entity.displayName, 'Amina Yusuf');
      expect(entity.label, 'Amina Yusuf');
      expect(model.toMap()['email'], 'amina@example.com');
      expect(model.toMap()['displayName'], 'Amina Yusuf');
    });

    test('labels fall back to the email and then to a generic name', () {
      const withEmail = WorkspaceMemberEntity(
        workspaceId: 'w1',
        userId: 'u1',
        role: WorkspaceRole.member,
        email: 'amina@example.com',
      );
      const bare = WorkspaceMemberEntity(
        workspaceId: 'w1',
        userId: 'u2',
        role: WorkspaceRole.member,
      );
      const blankName = WorkspaceMemberEntity(
        workspaceId: 'w1',
        userId: 'u3',
        role: WorkspaceRole.member,
        displayName: '   ',
        email: 'omar@example.com',
      );

      expect(withEmail.label, 'amina@example.com');
      expect(bare.label, 'Member');
      expect(blankName.label, 'omar@example.com');
    });

    test('records created before names were stored still load', () {
      final model = WorkspaceMemberModel.fromMap('u1', {
        'workspaceId': 'w1',
        'userId': 'u1',
        'role': 'viewer',
      });

      expect(model.toEntity().displayName, isNull);
      expect(model.toMap().containsKey('email'), isFalse);
      expect(model.toMap().containsKey('displayName'), isFalse);
    });
  });
}
