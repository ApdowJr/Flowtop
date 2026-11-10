import 'package:flutter_test/flutter_test.dart';
import 'package:flowtop/features/notifications/domain/entities/fcm_token_entity.dart';

void main() {
  group('FcmTokenEntity', () {
    final token = FcmTokenEntity(
      token: 'fcm-token-123',
      userId: 'u1',
      email: 'alice@example.com',
      deviceId: 'device-1',
      platform: 'android',
      isActive: true,
    );

    test('email field is stored and returned', () {
      expect(token.email, equals('alice@example.com'));
    });

    test('copyWith updates email field', () {
      final updated = token.copyWith(email: 'bob@example.com', isActive: false);
      expect(updated.email, equals('bob@example.com'));
      expect(updated.isActive, isFalse);
      expect(updated.token, equals('fcm-token-123'));
      expect(updated.userId, equals('u1'));
    });

    test('props includes email', () {
      expect(token.props, contains('alice@example.com'));
    });

    test('email can be null', () {
      final noEmail = FcmTokenEntity(
        token: 'token',
        userId: 'u1',
      );
      expect(noEmail.email, isNull);
    });
  });
}
