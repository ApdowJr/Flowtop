import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flowtop/core/di/injection_container.dart';
import 'package:flowtop/features/auth/domain/entities/user_entity.dart';
import 'package:flowtop/features/workspaces/domain/entities/workspace_entity.dart';
import 'package:flowtop/features/workspaces/domain/entities/workspace_invitation_entity.dart';
import 'package:flowtop/features/workspaces/domain/repositories/workspace_repository.dart';

class MockWorkspaceRepository extends Mock implements WorkspaceRepository {}

const _verifiedUser =
    UserEntity(uid: 'u1', email: 'amina@example.com', emailVerified: true);

WorkspaceInvitationEntity _invitation(
  String id,
  InvitationStatus status,
  DateTime expiresAt,
) {
  return WorkspaceInvitationEntity(
    id: id,
    workspaceId: 'w-$id',
    email: 'amina@example.com',
    role: WorkspaceRole.member,
    status: status,
    expiresAt: expiresAt,
  );
}

void main() {
  late MockWorkspaceRepository repository;

  ProviderContainer containerFor(UserEntity? user) {
    final container = ProviderContainer(overrides: [
      currentUserProvider.overrideWithValue(user),
      workspaceRepositoryProvider.overrideWithValue(repository),
    ]);
    addTearDown(container.dispose);
    return container;
  }

  setUp(() {
    repository = MockWorkspaceRepository();
  });

  group('myInvitationsProvider', () {
    test('is empty and does not query anything for an unverified email', () async {
      final container = containerFor(
        const UserEntity(uid: 'u1', email: 'amina@example.com'),
      );

      expect(await container.read(myInvitationsProvider.future), isEmpty);
      verifyNever(() => repository.watchInvitationsForEmail('amina@example.com'));
    });

    test('is empty when nobody is signed in', () async {
      final container = containerFor(null);

      expect(await container.read(myInvitationsProvider.future), isEmpty);
    });

    test('streams the invitations addressed to a verified email', () async {
      final soon = DateTime.now().add(const Duration(days: 2));
      when(() => repository.watchInvitationsForEmail('amina@example.com'))
          .thenAnswer((_) => Stream.value([
                _invitation('a', InvitationStatus.pending, soon),
              ]));
      final container = containerFor(_verifiedUser);

      final invitations = await container.read(myInvitationsProvider.future);

      expect(invitations.map((invitation) => invitation.id), ['a']);
    });
  });

  group('openInvitationsProvider', () {
    test('keeps only pending invitations that have not expired', () async {
      final now = DateTime.now();
      when(() => repository.watchInvitationsForEmail('amina@example.com'))
          .thenAnswer((_) => Stream.value([
                _invitation('open', InvitationStatus.pending, now.add(const Duration(days: 1))),
                _invitation('expired', InvitationStatus.pending, now.subtract(const Duration(days: 1))),
                _invitation('accepted', InvitationStatus.accepted, now.add(const Duration(days: 1))),
                _invitation('declined', InvitationStatus.declined, now.add(const Duration(days: 1))),
              ]));
      final container = containerFor(_verifiedUser);
      final subscription = container.listen(myInvitationsProvider, (_, __) {});
      addTearDown(subscription.close);
      await container.read(myInvitationsProvider.future);

      final open = container.read(openInvitationsProvider);

      expect(open.map((invitation) => invitation.id), ['open']);
    });

    test('is empty before the invitations have loaded', () {
      final container = containerFor(null);

      expect(container.read(openInvitationsProvider), isEmpty);
    });
  });

  group('myWorkspaceRoleProvider', () {
    test('finds the role of the signed-in user among the members', () async {
      when(() => repository.watchMembers('w1')).thenAnswer((_) => Stream.value(const [
            WorkspaceMemberEntity(workspaceId: 'w1', userId: 'u0', role: WorkspaceRole.owner),
            WorkspaceMemberEntity(workspaceId: 'w1', userId: 'u1', role: WorkspaceRole.manager),
          ]));
      final container = containerFor(_verifiedUser);
      final subscription = container.listen(workspaceMembersProvider('w1'), (_, __) {});
      addTearDown(subscription.close);
      await Future<void>.delayed(Duration.zero);

      expect(container.read(myWorkspaceRoleProvider('w1')), WorkspaceRole.manager);
    });

    test('is unknown for somebody who is not a member', () async {
      when(() => repository.watchMembers('w1')).thenAnswer((_) => Stream.value(const [
            WorkspaceMemberEntity(workspaceId: 'w1', userId: 'u0', role: WorkspaceRole.owner),
          ]));
      final container = containerFor(_verifiedUser);
      final subscription = container.listen(workspaceMembersProvider('w1'), (_, __) {});
      addTearDown(subscription.close);
      await Future<void>.delayed(Duration.zero);

      expect(container.read(myWorkspaceRoleProvider('w1')), isNull);
    });
  });
}
