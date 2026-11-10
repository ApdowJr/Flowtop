import 'package:flowtop/features/notifications/domain/entities/fcm_token_entity.dart';

/// Contract for FCM device token management.
///
/// Tokens are stored in `/users/{uid}/fcm_tokens/{token}` and used by
/// Cloud Functions to send targeted push notifications.
abstract class FcmTokenRepository {
  /// Stream of active FCM tokens for the current user.
  Stream<List<FcmTokenEntity>> watchTokens(String userId);

  /// Save a new FCM token (registration).
  Future<void> saveToken(String userId, FcmTokenEntity token);

  /// Remove an FCM token (unregister / logout).
  Future<void> removeToken(String userId, String token);

  /// Mark all tokens for a user as inactive.
  Future<void> deactivateAllTokens(String userId);

  /// Get the currently active token for a user, if any.
  Future<FcmTokenEntity?> getActiveToken(String userId);
}
