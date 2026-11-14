import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flowtop/core/constants/app_constants.dart';
import 'package:flowtop/core/di/injection_container.dart';
import 'package:flowtop/core/router/app_router.dart';
import 'package:flowtop/core/theme/app_theme.dart';
import 'package:flowtop/features/auth/domain/entities/user_entity.dart';
import 'package:flowtop/features/auth/domain/repositories/auth_repository.dart';
import 'package:flowtop/features/tasks/domain/repositories/task_repository.dart';
import 'package:flowtop/features/workspaces/domain/repositories/workspace_repository.dart';

class MockWorkspaceRepository extends Mock implements WorkspaceRepository {}

class MockTaskRepository extends Mock implements TaskRepository {}

class MockAuthRepository extends Mock implements AuthRepository {}

/// Exercises the real route tree and bottom navigation shell. Only the data
/// sources behind the pages are replaced, so no Firebase app is needed.
void main() {
  Future<GoRouter> pumpApp(
    WidgetTester tester, {
    required bool Function() isSignedIn,
    Listenable? refreshListenable,
    String location = AppRoutes.dashboard,
  }) async {
    final workspaces = MockWorkspaceRepository();
    when(() => workspaces.watchWorkspacesForUser('u1'))
        .thenAnswer((_) => Stream.value([]));
    final auth = MockAuthRepository();
    when(() => auth.authStateChanges).thenAnswer((_) => const Stream.empty());
    when(() => auth.currentUser).thenReturn(null);

    final router = createAppRouter(
      isSignedIn: isSignedIn,
      refreshListenable: refreshListenable,
      initialLocation: location,
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(ProviderScope(
      overrides: [
        currentUserProvider.overrideWith((ref) => const UserEntity(
              uid: 'u1',
              email: 'amina@example.com',
              displayName: 'Amina',
            )),
        workspaceRepositoryProvider.overrideWithValue(workspaces),
        taskRepositoryProvider.overrideWithValue(MockTaskRepository()),
        authRepositoryProvider.overrideWithValue(auth),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        theme: AppTheme.lightTheme(),
      ),
    ));
    await tester.pumpAndSettle();
    return router;
  }

  Finder navLabel(String label) => find.descendant(
        of: find.byType(BottomNavigationBar),
        matching: find.text(label),
      );

  int selectedTab(WidgetTester tester) => tester
      .widget<BottomNavigationBar>(find.byType(BottomNavigationBar))
      .currentIndex;

  String location(GoRouter router) =>
      router.routerDelegate.currentConfiguration.uri.path;

  testWidgets('has one bottom navigation destination per shell branch',
      (tester) async {
    await pumpApp(tester, isSignedIn: () => true);
    final bar = tester
        .widget<BottomNavigationBar>(find.byType(BottomNavigationBar));
    expect(bar.items, hasLength(ScaffoldWithNavBar.destinations.length));
    expect(selectedTab(tester), 0);
    expect(find.text('Hello, Amina'), findsOneWidget);
  });

  testWidgets('every tab opens its own page', (tester) async {
    await pumpApp(tester, isSignedIn: () => true);

    await tester.tap(navLabel('Tasks'));
    await tester.pumpAndSettle();
    expect(selectedTab(tester), 1);
    expect(find.text('Select or create a workspace to see your tasks.'),
        findsOneWidget);

    await tester.tap(navLabel('Projects'));
    await tester.pumpAndSettle();
    expect(selectedTab(tester), 2);
    expect(find.text('No workspaces'), findsOneWidget);

    await tester.tap(navLabel('Calendar'));
    await tester.pumpAndSettle();
    expect(selectedTab(tester), 3);
    expect(find.text('Select a workspace to see your calendar.'),
        findsOneWidget);

    await tester.tap(navLabel('Spaces'));
    await tester.pumpAndSettle();
    expect(selectedTab(tester), 4);
    expect(find.text('A space to call yours'), findsOneWidget);

    await tester.tap(navLabel('You'));
    await tester.pumpAndSettle();
    expect(selectedTab(tester), 5);
    expect(find.text('Sign out'), findsOneWidget);

    await tester.tap(navLabel('Home'));
    await tester.pumpAndSettle();
    expect(selectedTab(tester), 0);
    expect(find.text('Hello, Amina'), findsOneWidget);
  });

  testWidgets('the dashboard profile shortcut opens the profile tab',
      (tester) async {
    await pumpApp(tester, isSignedIn: () => true);

    await tester.tap(find.byTooltip('Profile'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(selectedTab(tester), 5);
    expect(find.text('Sign out'), findsOneWidget);
  });

  testWidgets('statistics and notifications open above the home tab',
      (tester) async {
    final router = await pumpApp(tester, isSignedIn: () => true);

    router.go(AppRoutes.statistics);
    await tester.pumpAndSettle();
    expect(selectedTab(tester), 0);
    expect(find.text(AppStrings.statistics), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Hello, Amina'), findsOneWidget);
  });

  testWidgets('task pages stack above the tasks tab and go back to it',
      (tester) async {
    final router = await pumpApp(tester, isSignedIn: () => true);

    router.go('${AppRoutes.taskDetail}/t1');
    await tester.pumpAndSettle();
    expect(selectedTab(tester), 1);
    expect(find.text('Task not found'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Task not found'), findsNothing);
    expect(find.text('Select or create a workspace to see your tasks.'),
        findsOneWidget);
  });

  testWidgets('tapping the open tab returns to the root of that tab',
      (tester) async {
    final router = await pumpApp(tester, isSignedIn: () => true);

    router.go('${AppRoutes.taskDetail}/t1');
    await tester.pumpAndSettle();
    expect(find.text('Task not found'), findsOneWidget);

    await tester.tap(navLabel('Tasks'));
    await tester.pumpAndSettle();
    expect(location(router), AppRoutes.taskList);
    expect(find.text('Task not found'), findsNothing);
  });

  testWidgets('signed out visitors are sent to sign in', (tester) async {
    final router = await pumpApp(tester, isSignedIn: () => false);
    expect(location(router), AppRoutes.signIn);
  });

  testWidgets('signed in users skip the auth pages', (tester) async {
    final router = await pumpApp(
      tester,
      isSignedIn: () => true,
      location: AppRoutes.signIn,
    );
    expect(location(router), AppRoutes.dashboard);
    expect(find.text('Hello, Amina'), findsOneWidget);
  });

  testWidgets('the router reacts when the session ends', (tester) async {
    final signedIn = ValueNotifier<bool>(true);
    addTearDown(signedIn.dispose);
    final router = await pumpApp(
      tester,
      isSignedIn: () => signedIn.value,
      refreshListenable: signedIn,
    );
    expect(location(router), AppRoutes.dashboard);

    signedIn.value = false;
    await tester.pumpAndSettle();

    expect(location(router), AppRoutes.signIn);
  });
}
