import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flowtop/core/di/injection_container.dart';
import 'package:flowtop/features/auth/domain/entities/user_entity.dart';
import 'package:flowtop/features/workspaces/domain/entities/workspace_entity.dart';
import 'package:flowtop/features/workspaces/domain/entities/workspace_invitation_entity.dart';
import 'package:flowtop/features/workspaces/domain/repositories/workspace_repository.dart';
import 'package:flowtop/features/workspaces/presentation/pages/my_invitations_page.dart';
import 'package:flowtop/features/workspaces/presentation/pages/workspace_invitations_page.dart';
import 'package:flowtop/features/workspaces/presentation/pages/workspace_members_page.dart';

class MockWorkspaceRepository extends Mock implements WorkspaceRepository {}

const _unverifiedUser = UserEntity(uid: 'u1', email: 'amina@example.com');
const _verifiedUser =
    UserEntity(uid: 'u1', email: 'amina@example.com', emailVerified: true);

WorkspaceInvitationEntity _invitation({
  String id = 'i1',
  String email = 'amina@example.com',
  InvitationStatus status = InvitationStatus.pending,
  Duration expiresIn = const Duration(days: 3),
}) {
  return WorkspaceInvitationEntity(
    id: id,
    workspaceId: 'w1',
    email: email,
    role: WorkspaceRole.member,
    status: status,
    workspaceName: 'Design studio',
    invitedByName: 'Omar',
    expiresAt: DateTime.now().add(expiresIn),
  );
}

Future<void> _pump(
  WidgetTester tester,
  Widget page, {
  required MockWorkspaceRepository repository,
  required UserEntity user,
}) async {
  await tester.binding.setSurfaceSize(const Size(800, 1600));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(ProviderScope(
    overrides: [
      currentUserProvider.overrideWithValue(user),
      workspaceRepositoryProvider.overrideWithValue(repository),
    ],
    child: MaterialApp(home: page),
  ));
  await tester.pumpAndSettle();
}

void main() {
  group('MyInvitationsPage', () {
    testWidgets('asks for a verified email before showing invitations', (tester) async {
      final repository = MockWorkspaceRepository();

      await _pump(tester, const MyInvitationsPage(), repository: repository, user: _unverifiedUser);

      expect(find.text('Verify your email to see invitations'), findsOneWidget);
      expect(find.text('Send verification email'), findsOneWidget);
      verifyNever(() => repository.watchInvitationsForEmail('amina@example.com'));
    });

    testWidgets('shows a friendly message when nothing is pending', (tester) async {
      final repository = MockWorkspaceRepository();
      when(() => repository.watchInvitationsForEmail('amina@example.com'))
          .thenAnswer((_) => Stream.value(const []));

      await _pump(tester, const MyInvitationsPage(), repository: repository, user: _verifiedUser);

      expect(find.text('No pending invitations'), findsOneWidget);
    });

    testWidgets('hides invitations that expired or were already answered', (tester) async {
      final repository = MockWorkspaceRepository();
      when(() => repository.watchInvitationsForEmail('amina@example.com'))
          .thenAnswer((_) => Stream.value([
                _invitation(id: 'old', expiresIn: const Duration(days: -1)),
                _invitation(id: 'done', status: InvitationStatus.accepted),
              ]));

      await _pump(tester, const MyInvitationsPage(), repository: repository, user: _verifiedUser);

      expect(find.text('Design studio'), findsNothing);
      expect(find.text('No pending invitations'), findsOneWidget);
    });

    testWidgets('accepting an invitation calls the repository', (tester) async {
      final repository = MockWorkspaceRepository();
      when(() => repository.watchInvitationsForEmail('amina@example.com'))
          .thenAnswer((_) => Stream.value([_invitation()]));
      when(() => repository.acceptInvitation('w1', 'i1')).thenAnswer((_) async {});

      await _pump(tester, const MyInvitationsPage(), repository: repository, user: _verifiedUser);
      expect(find.text('Design studio'), findsOneWidget);
      expect(find.text('Omar invited you as Member'), findsOneWidget);

      await tester.tap(find.text('Accept'));
      await tester.pumpAndSettle();

      verify(() => repository.acceptInvitation('w1', 'i1')).called(1);
      expect(find.text('You joined Design studio'), findsOneWidget);
    });

    testWidgets('declining an invitation calls the repository', (tester) async {
      final repository = MockWorkspaceRepository();
      when(() => repository.watchInvitationsForEmail('amina@example.com'))
          .thenAnswer((_) => Stream.value([_invitation()]));
      when(() => repository.declineInvitation('w1', 'i1')).thenAnswer((_) async {});

      await _pump(tester, const MyInvitationsPage(), repository: repository, user: _verifiedUser);

      await tester.tap(find.text('Decline'));
      await tester.pumpAndSettle();

      verify(() => repository.declineInvitation('w1', 'i1')).called(1);
      verifyNever(() => repository.acceptInvitation('w1', 'i1'));
    });
  });

  group('WorkspaceInvitationsPage', () {
    MockWorkspaceRepository repositoryWithRole(WorkspaceRole role) {
      final repository = MockWorkspaceRepository();
      when(() => repository.watchMembers('w1')).thenAnswer((_) => Stream.value([
            WorkspaceMemberEntity(workspaceId: 'w1', userId: 'u1', role: role),
          ]));
      when(() => repository.watchWorkspaceInvitations('w1')).thenAnswer(
        (_) => Stream.value([_invitation(id: 'sent', email: 'omar@example.com')]),
      );
      return repository;
    }

    testWidgets('lets a manager invite somebody by email', (tester) async {
      final repository = repositoryWithRole(WorkspaceRole.manager);
      when(() => repository.inviteMember('w1', 'sam@example.com', WorkspaceRole.member,
          invitedBy: 'u1')).thenAnswer((_) async {});

      await _pump(tester, const WorkspaceInvitationsPage(workspaceId: 'w1'),
          repository: repository, user: _verifiedUser);
      expect(find.text('omar@example.com'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField), ' sam@example.com ');
      await tester.tap(find.text('Send invitation'));
      await tester.pumpAndSettle();

      verify(() => repository.inviteMember('w1', 'sam@example.com', WorkspaceRole.member,
          invitedBy: 'u1')).called(1);
      expect(find.text('Invitation sent'), findsOneWidget);
    });

    testWidgets('rejects an invalid email address', (tester) async {
      final repository = repositoryWithRole(WorkspaceRole.owner);

      await _pump(tester, const WorkspaceInvitationsPage(workspaceId: 'w1'),
          repository: repository, user: _verifiedUser);

      await tester.enterText(find.byType(TextFormField), 'not-an-email');
      await tester.tap(find.text('Send invitation'));
      await tester.pumpAndSettle();

      expect(find.text('Enter a valid email address'), findsOneWidget);
      verifyNever(() => repository.inviteMember('w1', 'not-an-email', WorkspaceRole.member,
          invitedBy: 'u1'));
    });

    testWidgets('regular members can only look at the sent invitations', (tester) async {
      final repository = repositoryWithRole(WorkspaceRole.member);

      await _pump(tester, const WorkspaceInvitationsPage(workspaceId: 'w1'),
          repository: repository, user: _verifiedUser);

      expect(find.text('Send invitation'), findsNothing);
      expect(find.text('Only owners, admins and managers can invite people'), findsOneWidget);
      expect(find.text('omar@example.com'), findsOneWidget);
      expect(find.byTooltip('Withdraw invitation'), findsNothing);
    });
  });

  group('WorkspaceMembersPage', () {
    MockWorkspaceRepository repositoryWithMembers() {
      final repository = MockWorkspaceRepository();
      when(() => repository.watchMembers('w1')).thenAnswer((_) => Stream.value(const [
            WorkspaceMemberEntity(
              workspaceId: 'w1',
              userId: 'u1',
              role: WorkspaceRole.owner,
              displayName: 'Amina Yusuf',
              email: 'amina@example.com',
            ),
            WorkspaceMemberEntity(
              workspaceId: 'w1',
              userId: 'u2',
              role: WorkspaceRole.member,
              displayName: 'Omar Hassan',
              email: 'omar@example.com',
            ),
            WorkspaceMemberEntity(
              workspaceId: 'w1',
              userId: 'u3',
              role: WorkspaceRole.viewer,
            ),
          ]));
      return repository;
    }

    testWidgets('shows who is in the workspace instead of raw ids', (tester) async {
      final repository = repositoryWithMembers();

      await _pump(tester, const WorkspaceMembersPage(workspaceId: 'w1'),
          repository: repository, user: _verifiedUser);

      expect(find.text('Amina Yusuf (you)'), findsOneWidget);
      expect(find.text('Owner • amina@example.com'), findsOneWidget);
      expect(find.text('Omar Hassan'), findsOneWidget);
      expect(find.text('Member • omar@example.com'), findsOneWidget);
      expect(find.text('Viewer'), findsOneWidget);
      expect(find.textContaining('u2'), findsNothing);
    });

    testWidgets('the owner can change the role of another member', (tester) async {
      final repository = repositoryWithMembers();
      when(() => repository.changeMemberRole('w1', 'u2', WorkspaceRole.admin))
          .thenAnswer((_) async {});

      await _pump(tester, const WorkspaceMembersPage(workspaceId: 'w1'),
          repository: repository, user: _verifiedUser);

      // The owner cannot manage themselves, so there are two menus: Omar and the viewer.
      expect(find.byType(PopupMenuButton<String>), findsNWidgets(2));
      await tester.tap(find.byType(PopupMenuButton<String>).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Change role'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Admin'));
      await tester.pumpAndSettle();

      verify(() => repository.changeMemberRole('w1', 'u2', WorkspaceRole.admin)).called(1);
    });

    testWidgets('a regular member can leave but not manage others', (tester) async {
      final repository = repositoryWithMembers();
      const regularMember =
          UserEntity(uid: 'u2', email: 'omar@example.com', emailVerified: true);

      await _pump(tester, const WorkspaceMembersPage(workspaceId: 'w1'),
          repository: repository, user: regularMember);

      expect(find.byType(PopupMenuButton<String>), findsNothing);
      expect(find.text('Leave workspace'), findsOneWidget);
    });
  });
}
