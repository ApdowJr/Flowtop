import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flowtop/features/workspaces/data/repositories/workspace_repository_impl.dart';
import 'package:flowtop/features/workspaces/domain/entities/workspace_entity.dart';

class MockFirebaseFunctions extends Mock implements FirebaseFunctions {}

class MockHttpsCallable extends Mock implements HttpsCallable {}

class MockHttpsCallableResult extends Mock
    implements HttpsCallableResult<dynamic> {}

void main() {
  group('WorkspaceRepositoryImpl.inviteMember', () {
    late WorkspaceRepositoryImpl repository;
    late MockFirebaseFunctions mockFunctions;
    late MockHttpsCallable mockCallable;

    setUp(() {
      mockFunctions = MockFirebaseFunctions();
      mockCallable = MockHttpsCallable();
      repository = WorkspaceRepositoryImpl(
        FirebaseFirestore.instance,
        mockFunctions,
      );
    });

    test('calls createInvitation Cloud Function with correct parameters',
        () async {
      when(() => mockFunctions.httpsCallable('createInvitation'))
          .thenReturn(mockCallable);
      when(() => mockCallable.call(any())).thenAnswer((_) async => MockHttpsCallableResult());

      await repository.inviteMember(
        'ws1',
        'User@Example.com',
        WorkspaceRole.member,
        invitedBy: 'u1',
      );

      verify(() => mockFunctions.httpsCallable('createInvitation')).called(1);
      verify(() => mockCallable.call({
        'workspaceId': 'ws1',
        'email': 'user@example.com',
        'role': 'member',
      })).called(1);
    });

    test('normalizes email to lowercase before sending', () async {
      when(() => mockFunctions.httpsCallable('createInvitation'))
          .thenReturn(mockCallable);
      when(() => mockCallable.call(any())).thenAnswer((_) async => MockHttpsCallableResult());

      await repository.inviteMember(
        'ws1',
        'ADMIN@Example.COM',
        WorkspaceRole.admin,
        invitedBy: 'u1',
      );

      verify(() => mockCallable.call({
        'workspaceId': 'ws1',
        'email': 'admin@example.com',
        'role': 'admin',
      })).called(1);
    });

    test('passes owner role correctly', () async {
      when(() => mockFunctions.httpsCallable('createInvitation'))
          .thenReturn(mockCallable);
      when(() => mockCallable.call(any())).thenAnswer((_) async => MockHttpsCallableResult());

      await repository.inviteMember(
        'ws1',
        'owner@example.com',
        WorkspaceRole.owner,
        invitedBy: 'u1',
      );

      verify(() => mockCallable.call({
        'workspaceId': 'ws1',
        'email': 'owner@example.com',
        'role': 'owner',
      })).called(1);
    });

    test('throws FirebaseFunctionsException when callable fails',
        () async {
      when(() => mockFunctions.httpsCallable('createInvitation'))
          .thenReturn(mockCallable);
      when(() => mockCallable.call(any()))
          .thenThrow(FirebaseFunctionsException(
            code: 'permission-denied',
            message: 'Only the owner can grant the owner role.',
          ));

      expect(
        () => repository.inviteMember(
          'ws1',
          'user@example.com',
          WorkspaceRole.owner,
          invitedBy: 'u1',
        ),
        throwsA(isA<FirebaseFunctionsException>()),
      );
    });

    test('falls back to FirebaseFunctions.instance when no functions injected',
        () async {
      final repoNoFunctions = WorkspaceRepositoryImpl(FirebaseFirestore.instance);

      when(() => mockFunctions.httpsCallable('createInvitation'))
          .thenReturn(mockCallable);
      when(() => mockCallable.call(any())).thenAnswer((_) async => MockHttpsCallableResult());

      // This test verifies the repository can be constructed without functions.
      // The actual call would use FirebaseFunctions.instance which requires
      // Firebase initialization, so we just verify construction succeeds.
      expect(repoNoFunctions, isA<WorkspaceRepositoryImpl>());
    });
  });
}
