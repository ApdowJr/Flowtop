import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flowtop/features/notifications/data/models/fcm_token_model.dart';
import 'package:flowtop/features/notifications/domain/entities/fcm_token_entity.dart';

void main() {
  group('FcmTokenModel', () {
    test('toMap includes email when set', () {
      final model = FcmTokenModel(
        token: 'fcm-token-123',
        userId: 'u1',
        email: 'alice@example.com',
        platform: 'android',
        isActive: true,
      );
      final map = model.toMap();
      expect(map['email'], equals('alice@example.com'));
      expect(map['userId'], equals('u1'));
      expect(map['isActive'], isTrue);
    });

    test('toMap omits email when null', () {
      final model = FcmTokenModel(
        token: 'fcm-token-123',
        userId: 'u1',
        email: null,
        platform: 'android',
        isActive: true,
      );
      final map = model.toMap();
      expect(map.containsKey('email'), isFalse);
      expect(map['userId'], equals('u1'));
    });

    test('fromMap reads email field', () {
      final map = {
        'userId': 'u1',
        'email': 'bob@example.com',
        'platform': 'ios',
        'isActive': true,
      };
      final model = FcmTokenModel.fromMap('fcm-token-456', map);
      expect(model.token, equals('fcm-token-456'));
      expect(model.email, equals('bob@example.com'));
      expect(model.userId, equals('u1'));
      expect(model.platform, equals('ios'));
    });

    test('fromMap handles missing email gracefully', () {
      final map = {
        'userId': 'u1',
        'platform': 'android',
        'isActive': true,
      };
      final model = FcmTokenModel.fromMap('fcm-token-789', map);
      expect(model.email, isNull);
    });

    test('fromEntity preserves email', () {
      final entity = FcmTokenEntity(
        token: 'tok',
        userId: 'u1',
        email: 'carol@example.com',
        isActive: true,
      );
      final model = FcmTokenModel.fromEntity(entity);
      expect(model.email, equals('carol@example.com'));
    });

    test('toEntity preserves email', () {
      final model = FcmTokenModel(
        token: 'tok',
        userId: 'u1',
        email: 'dave@example.com',
        isActive: true,
      );
      final entity = model.toEntity();
      expect(entity.email, equals('dave@example.com'));
    });

    test('copyWith preserves email', () {
      final model = FcmTokenModel(
        token: 'tok',
        userId: 'u1',
        email: 'eve@example.com',
        isActive: true,
      );
      final updated = model.copyWith(email: 'frank@example.com');
      expect(updated.email, equals('frank@example.com'));
      expect(updated.token, equals('tok'));
    });
  });
}
