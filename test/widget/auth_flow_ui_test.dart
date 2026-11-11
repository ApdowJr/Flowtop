import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flowtop/core/constants/app_constants.dart';
import 'package:flowtop/features/auth/domain/entities/user_entity.dart';
import 'package:flowtop/features/auth/domain/repositories/auth_repository.dart';
import 'package:flowtop/features/auth/presentation/pages/reset_password_page.dart';
import 'package:flowtop/features/auth/presentation/pages/sign_in_page.dart';
import 'package:flowtop/features/auth/presentation/providers/auth_provider.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository repository;
  setUp(() {
    repository = MockAuthRepository();
    when(() => repository.authStateChanges).thenAnswer((_) => const Stream.empty());
    when(() => repository.currentUser).thenReturn(null);
  });

  testWidgets('reset failure is not shown as success', (tester) async {
    when(() => repository.sendPasswordResetEmail('person@example.com'))
        .thenThrow(FirebaseAuthException(code: 'network-request-failed'));
    await tester.pumpWidget(ProviderScope(
      overrides: [authRepositoryProvider.overrideWithValue(repository)],
      child: const MaterialApp(home: ResetPasswordPage()),
    ));
    await tester.enterText(find.byType(TextFormField), 'person@example.com');
    await tester.tap(find.text(AppStrings.sendResetLink));
    await tester.pumpAndSettle();
    expect(find.text('Reset link sent'), findsNothing);
    expect(find.textContaining('Could not send the reset link'), findsOneWidget);
  });

  testWidgets('reset success is shown only after the request succeeds', (tester) async {
    when(() => repository.sendPasswordResetEmail('person@example.com'))
        .thenAnswer((_) async {});
    await tester.pumpWidget(ProviderScope(
      overrides: [authRepositoryProvider.overrideWithValue(repository)],
      child: const MaterialApp(home: ResetPasswordPage()),
    ));
    await tester.enterText(find.byType(TextFormField), 'person@example.com');
    await tester.tap(find.text(AppStrings.sendResetLink));
    await tester.pumpAndSettle();
    expect(find.text('Reset link sent'), findsOneWidget);
  });

  testWidgets('email sign in routes to dashboard on success', (tester) async {
    const user = UserEntity(uid: 'u1', email: 'person@example.com');
    when(() => repository.signInWithEmailPassword(email: 'person@example.com', password: 'password123'))
        .thenAnswer((_) async => user);
    final router = GoRouter(initialLocation: AppRoutes.signIn, routes: [
      GoRoute(path: AppRoutes.signIn, builder: (_, __) => const SignInPage()),
      GoRoute(path: AppRoutes.dashboard, builder: (_, __) => const Scaffold(body: Text('Dashboard destination'))),
      GoRoute(path: AppRoutes.auth, builder: (_, __) => const Scaffold()),
      GoRoute(path: AppRoutes.signUp, builder: (_, __) => const Scaffold()),
      GoRoute(path: AppRoutes.resetPassword, builder: (_, __) => const Scaffold()),
    ]);
    addTearDown(router.dispose);
    await tester.pumpWidget(ProviderScope(
      overrides: [authRepositoryProvider.overrideWithValue(repository)],
      child: MaterialApp.router(routerConfig: router),
    ));
    await tester.enterText(find.byType(TextFormField).at(0), 'person@example.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'password123');
    await tester.ensureVisible(find.text(AppStrings.signIn));
    await tester.tap(find.text(AppStrings.signIn));
    await tester.pumpAndSettle();
    expect(find.text('Dashboard destination'), findsOneWidget);
  });
}
