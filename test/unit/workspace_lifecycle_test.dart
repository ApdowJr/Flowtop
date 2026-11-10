import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flowtop/core/di/injection_container.dart';
import 'package:flowtop/features/auth/domain/entities/user_entity.dart';
import 'package:flowtop/features/auth/domain/repositories/auth_repository.dart';
import 'package:flowtop/features/auth/presentation/providers/auth_provider.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  group('Workspace lifecycle on auth change', () {
    late ProviderContainer container;
    late MockAuthRepository mockAuthRepository;
    late StreamController<UserEntity?> authStateController;

    setUp(() {
      mockAuthRepository = MockAuthRepository();
      authStateController = StreamController<UserEntity?>();

      container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockAuthRepository),
        ],
      );

      // Activate the auth listener so ref.listen is registered
      container.read(selectedWorkspaceAuthListener);

      // Default: no user signed in
      when(() => mockAuthRepository.currentUser).thenReturn(null);
      when(() => mockAuthRepository.authStateChanges)
          .thenAnswer((_) => authStateController.stream);
    });

    tearDown(() {
      authStateController.close();
      container.dispose();
    });

    test('selectedWorkspaceProvider is null initially', () {
      expect(container.read(selectedWorkspaceProvider), isNull);
    });

    test('selectedWorkspaceProvider resets when user signs out', () async {
      final userA = const UserEntity(uid: 'user-a', email: 'a@test.com');

      // Sign in as user A
      when(() => mockAuthRepository.signInWithEmailPassword(
            email: 'a@test.com',
            password: 'pass',
          )).thenAnswer((_) async => userA);
      when(() => mockAuthRepository.currentUser).thenReturn(userA);

      final notifier = container.read(authProvider.notifier);
      await notifier.signInWithEmailPassword(
        email: 'a@test.com',
        password: 'pass',
      );

      // User A has a workspace selected
      container.read(selectedWorkspaceProvider.notifier).state = 'ws-a';
      expect(container.read(selectedWorkspaceProvider), equals('ws-a'));

      // User A signs out → auth state changes to null → workspace resets
      await notifier.signOut();

      // The listener should have fired and reset the workspace
      expect(container.read(selectedWorkspaceProvider), isNull);
    });

    test('selectedWorkspaceProvider resets when switching from user A to user B',
        () async {
      final userA = const UserEntity(uid: 'user-a', email: 'a@test.com');
      final userB = const UserEntity(uid: 'user-b', email: 'b@test.com');

      // Sign in as user A
      when(() => mockAuthRepository.signInWithEmailPassword(
            email: 'a@test.com',
            password: 'pass',
          )).thenAnswer((_) async => userA);
      when(() => mockAuthRepository.currentUser).thenReturn(userA);

      final notifier = container.read(authProvider.notifier);
      await notifier.signInWithEmailPassword(
        email: 'a@test.com',
        password: 'pass',
      );

      // User A selects a workspace
      container.read(selectedWorkspaceProvider.notifier).state = 'ws-a';
      expect(container.read(selectedWorkspaceProvider), equals('ws-a'));

      // User B signs in → auth state changes from user-a to user-b → workspace resets
      when(() => mockAuthRepository.signInWithEmailPassword(
            email: 'b@test.com',
            password: 'pass',
          )).thenAnswer((_) async => userB);
      when(() => mockAuthRepository.currentUser).thenReturn(userB);
      await notifier.signInWithEmailPassword(
        email: 'b@test.com',
        password: 'pass',
      );

      expect(container.read(selectedWorkspaceProvider), isNull);
    });

    test('selectedWorkspaceProvider does not reset when same user re-signs in',
        () async {
      final userA = const UserEntity(uid: 'user-a', email: 'a@test.com');

      // Sign in as user A
      when(() => mockAuthRepository.signInWithEmailPassword(
            email: 'a@test.com',
            password: 'pass',
          )).thenAnswer((_) async => userA);
      when(() => mockAuthRepository.currentUser).thenReturn(userA);

      final notifier = container.read(authProvider.notifier);
      await notifier.signInWithEmailPassword(
        email: 'a@test.com',
        password: 'pass',
      );

      container.read(selectedWorkspaceProvider.notifier).state = 'ws-a';
      expect(container.read(selectedWorkspaceProvider), equals('ws-a'));

      // Same user triggers an auth state refresh (same UID) → workspace preserved
      authStateController.add(userA);

      expect(container.read(selectedWorkspaceProvider), equals('ws-a'));
    });
  });
}
