import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flowtop/features/tasks/domain/entities/task_entity.dart';
import 'package:flowtop/features/tasks/domain/repositories/task_repository.dart';
import 'package:flowtop/core/constants/app_constants.dart';
import 'package:flowtop/core/di/injection_container.dart';
import 'package:flowtop/core/theme/app_theme.dart';
import 'package:flowtop/features/auth/domain/entities/user_entity.dart';
import 'package:flowtop/features/auth/presentation/pages/auth_page.dart';
import 'package:flowtop/features/dashboard/presentation/pages/dashboard_page.dart';

class MockTaskRepository extends Mock implements TaskRepository {}

void main() {
  testWidgets('dashboard guides a user to choose a workspace', (tester) async {
    final router = GoRouter(initialLocation: '/', routes: [
      GoRoute(path: '/', builder: (_, __) => const DashboardPage()),
      GoRoute(path: AppRoutes.workspaces, builder: (_, __) => const Scaffold(body: Text('Workspace destination'))),
      GoRoute(path: AppRoutes.profile, builder: (_, __) => const Scaffold(body: Text('Profile destination'))),
    ]);
    addTearDown(router.dispose);
    await tester.pumpWidget(ProviderScope(
      overrides: [currentUserProvider.overrideWith((ref) => const UserEntity(uid: 'u1', displayName: 'Amina'))],
      child: MaterialApp.router(routerConfig: router, theme: AppTheme.lightTheme()),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Hello, Amina'), findsOneWidget);
    expect(find.text('Choose workspace'), findsOneWidget);
    await tester.tap(find.text('Choose workspace'));
    await tester.pumpAndSettle();
    expect(find.text('Workspace destination'), findsOneWidget);
  });

  testWidgets('welcome screen opens sign in', (tester) async {
    final router = GoRouter(initialLocation: '/', routes: [
      GoRoute(path: '/', builder: (_, __) => const AuthPage()),
      GoRoute(path: AppRoutes.signIn, builder: (_, __) => const Scaffold(body: Text('Sign in destination'))),
      GoRoute(path: AppRoutes.signUp, builder: (_, __) => const Scaffold(body: Text('Sign up destination'))),
    ]);
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router, darkTheme: AppTheme.darkTheme(), themeMode: ThemeMode.dark));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text(AppStrings.signIn));
    await tester.tap(find.text(AppStrings.signIn));
    await tester.pumpAndSettle();
    expect(find.text('Sign in destination'), findsOneWidget);
  });
  testWidgets('overview shows live task progress in dark mode', (tester) async {
    final repository = MockTaskRepository();
    when(() => repository.watchTasks(workspaceId: 'w1')).thenAnswer((_) => Stream.value([
      const TaskEntity(id: 't1', title: 'First', status: TaskStatus.done, priority: TaskPriority.medium, category: TaskCategory.work, ownerId: 'u1'),
      const TaskEntity(id: 't2', title: 'Second', status: TaskStatus.todo, priority: TaskPriority.medium, category: TaskCategory.work, ownerId: 'u1'),
    ]));
    final router = GoRouter(initialLocation: '/', routes: [
      GoRoute(path: '/', builder: (_, __) => const DashboardPage()),
      GoRoute(path: AppRoutes.workspaces, builder: (_, __) => const Scaffold()),
      GoRoute(path: AppRoutes.profile, builder: (_, __) => const Scaffold()),
      GoRoute(path: AppRoutes.taskCreate, builder: (_, __) => const Scaffold()),
      GoRoute(path: AppRoutes.taskList, builder: (_, __) => const Scaffold()),
      GoRoute(path: AppRoutes.calendar, builder: (_, __) => const Scaffold()),
    ]);
    addTearDown(router.dispose);
    await tester.pumpWidget(ProviderScope(overrides: [
      currentUserProvider.overrideWith((ref) => const UserEntity(uid: 'u1')),
      selectedWorkspaceProvider.overrideWith((ref) => 'w1'),
      taskRepositoryProvider.overrideWithValue(repository),
    ], child: MaterialApp.router(routerConfig: router, darkTheme: AppTheme.darkTheme(), themeMode: ThemeMode.dark)));
    await tester.pumpAndSettle();
    expect(find.text('50%'), findsOneWidget);
    expect(find.text('1 of 2 tasks completed'), findsOneWidget);
    expect(find.text('This week'), findsOneWidget);
  });

}
