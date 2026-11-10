import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flowtop/core/constants/app_constants.dart';
import 'package:flowtop/core/di/injection_container.dart';
import 'package:flowtop/features/auth/domain/entities/user_entity.dart';
import 'package:flowtop/features/workspaces/domain/entities/workspace_entity.dart';
import 'package:flowtop/features/workspaces/domain/repositories/workspace_repository.dart';
import 'package:flowtop/features/workspaces/presentation/pages/workspace_list_page.dart';

class MockWorkspaceRepository extends Mock implements WorkspaceRepository {}

void main() {
  testWidgets('selecting a workspace makes it active', (tester) async {
    final repository = MockWorkspaceRepository();
    when(() => repository.watchWorkspacesForUser('u1')).thenAnswer((_) => Stream.value([
      const WorkspaceEntity(id: 'w1', name: 'My space', ownerId: 'u1', role: WorkspaceRole.owner),
    ]));
    final router = GoRouter(initialLocation: '/', routes: [
      GoRoute(path: '/', builder: (_, __) => const WorkspaceListPage()),
      GoRoute(path: AppRoutes.workspaceCreate, builder: (_, __) => const Scaffold()),
      GoRoute(path: '${AppRoutes.workspaceDetail}/:workspaceId', builder: (_, __) => const Scaffold()),
    ]);
    addTearDown(router.dispose);
    await tester.pumpWidget(ProviderScope(overrides: [
      currentUserProvider.overrideWith((ref) => const UserEntity(uid: 'u1', email: 'amina@example.com')),
      workspaceRepositoryProvider.overrideWithValue(repository),
    ], child: MaterialApp.router(routerConfig: router)));
    await tester.pumpAndSettle();
    expect(find.text('My space'), findsOneWidget);
    await tester.tap(find.text('Select workspace'));
    await tester.pumpAndSettle();
    expect(find.text('Selected'), findsOneWidget);
  });
}
