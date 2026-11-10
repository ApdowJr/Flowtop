import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flowtop/features/auth/domain/entities/user_entity.dart';
import 'package:flowtop/features/auth/domain/repositories/auth_repository.dart';
import 'package:flowtop/features/auth/presentation/providers/auth_provider.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  group('AuthNotifier', () {
    late MockAuthRepository repository;

    setUp(() {
      repository = MockAuthRepository();
      // Stub authStateChanges so the notifier constructor's .listen() does not throw.
      when(() => repository.authStateChanges).thenAnswer((_) => const Stream.empty());
      when(() => repository.currentUser).thenReturn(null);
    });

    test('signInWithEmailPassword sets loading then data', () async {
      final user = const UserEntity(uid: 'u1', email: 'a@b.com');
      when(() => repository.signInWithEmailPassword(email: 'a@b.com', password: 'pass12345'))
          .thenAnswer((_) async => user);

      final notifier = AuthNotifier(repository);
      await notifier.signInWithEmailPassword(email: 'a@b.com', password: 'pass12345');

      expect(notifier.state.value, equals(user));
    });

    test('signOut sets state to null', () async {
      when(() => repository.signOut()).thenAnswer((_) async => {});
      final notifier = AuthNotifier(repository);
      await notifier.signOut();
      expect(notifier.state.value, isNull);
    });

    test('signInWithGoogle sets loading then data', () async {
      final user = const UserEntity(uid: 'u2', email: 'google@b.com');
      when(() => repository.signInWithGoogle(any())).thenAnswer((_) async => user);

      final notifier = AuthNotifier(repository);
      await notifier.signInWithGoogle(idToken: 'id-token', accessToken: 'access-token');

      expect(notifier.state.value, equals(user));
      verify(() => repository.signInWithGoogle(any())).called(1);
    });

    test('signInWithGoogle error propagates to state', () async {
      when(() => repository.signInWithGoogle(any()))
          .thenThrow(FirebaseAuthException(code: 'invalid-credential', message: 'Invalid Google token.'));

      final notifier = AuthNotifier(repository);
      await notifier.signInWithGoogle(idToken: 'bad', accessToken: 'bad');

      expect(notifier.state.toString(), contains('AsyncError'));
    });
  });
}
