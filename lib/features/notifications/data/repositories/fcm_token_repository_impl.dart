import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flowtop/features/notifications/data/models/fcm_token_model.dart';
import 'package:flowtop/features/notifications/domain/entities/fcm_token_entity.dart';
import 'package:flowtop/features/notifications/domain/repositories/fcm_token_repository.dart';

class FcmTokenRepositoryImpl implements FcmTokenRepository {
  FcmTokenRepositoryImpl(this._firestore);

  final FirebaseFirestore _firestore;

  static const String _collection = 'fcm_tokens';

  DocumentReference<Map<String, dynamic>> _tokenDoc(String userId, String token) =>
      _firestore.collection('users').doc(userId).collection(_collection).doc(token);

  CollectionReference<Map<String, dynamic>> _tokensRef(String userId) =>
      _firestore.collection('users').doc(userId).collection(_collection);

  @override
  Stream<List<FcmTokenEntity>> watchTokens(String userId) {
    return _tokensRef(userId)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => FcmTokenModel.fromMap(doc.id, doc.data()).toEntity())
              .toList();
        });
  }

  @override
  Future<void> saveToken(String userId, FcmTokenEntity token) async {
    final now = DateTime.now();
    final model = FcmTokenModel.fromEntity(token.copyWith(
      userId: userId,
      createdAt: token.createdAt ?? now,
      updatedAt: now,
      isActive: true,
    ));
    await _tokenDoc(userId, token.token).set(model.toMap(), SetOptions(merge: true));
  }

  @override
  Future<void> removeToken(String userId, String token) async {
    await _tokenDoc(userId, token).delete();
  }

  @override
  Future<void> deactivateAllTokens(String userId) async {
    final snapshot = await _tokensRef(userId).where('isActive', isEqualTo: true).get();
    final batch = _firestore.batch();
    final now = Timestamp.fromDate(DateTime.now());
    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {'isActive': false, 'updatedAt': now});
    }
    if (snapshot.docs.isNotEmpty) {
      await batch.commit();
    }
  }

  @override
  Future<FcmTokenEntity?> getActiveToken(String userId) async {
    final snapshot = await _tokensRef(userId)
        .where('isActive', isEqualTo: true)
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) return null;
    return FcmTokenModel.fromMap(snapshot.docs.first.id, snapshot.docs.first.data()).toEntity();
  }
}
