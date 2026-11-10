import 'package:flutter_test/flutter_test.dart';
import 'package:flowtop/features/workspaces/domain/entities/workspace_entity.dart';

void main() {
  group('WorkspaceEntity', () {
    final workspace = WorkspaceEntity(
      id: 'ws1',
      name: 'My Workspace',
      ownerId: 'u1',
      role: WorkspaceRole.owner,
      memberCount: 3,
      isPersonal: false,
    );

    test('role labels are correct', () {
      expect(WorkspaceRole.owner.label, equals('Owner'));
      expect(WorkspaceRole.admin.label, equals('Admin'));
      expect(WorkspaceRole.manager.label, equals('Manager'));
      expect(WorkspaceRole.member.label, equals('Member'));
      expect(WorkspaceRole.viewer.label, equals('Viewer'));
    });

    test('canInvite is true for owner/admin/manager', () {
      expect(WorkspaceRole.owner.canInvite, isTrue);
      expect(WorkspaceRole.admin.canInvite, isTrue);
      expect(WorkspaceRole.manager.canInvite, isTrue);
      expect(WorkspaceRole.member.canInvite, isFalse);
      expect(WorkspaceRole.viewer.canInvite, isFalse);
    });

    test('canChangeRoles is true for owner/admin only', () {
      expect(WorkspaceRole.owner.canChangeRoles, isTrue);
      expect(WorkspaceRole.admin.canChangeRoles, isTrue);
      expect(WorkspaceRole.manager.canChangeRoles, isFalse);
    });

    test('canEdit is false for viewer only', () {
      expect(WorkspaceRole.owner.canEdit, isTrue);
      expect(WorkspaceRole.admin.canEdit, isTrue);
      expect(WorkspaceRole.manager.canEdit, isTrue);
      expect(WorkspaceRole.member.canEdit, isTrue);
      expect(WorkspaceRole.viewer.canEdit, isFalse);
    });

    test('copyWith updates fields', () {
      final updated = workspace.copyWith(name: 'Renamed', memberCount: 5);
      expect(updated.name, equals('Renamed'));
      expect(updated.memberCount, equals(5));
      expect(updated.id, equals('ws1'));
    });
  });
}
