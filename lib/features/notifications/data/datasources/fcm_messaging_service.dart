import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flowtop/features/notifications/data/repositories/fcm_token_repository_impl.dart';
import 'package:flowtop/features/notifications/domain/entities/fcm_token_entity.dart';
import 'package:flowtop/features/notifications/domain/repositories/fcm_token_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Service that manages Firebase Cloud Messaging device tokens.
///
/// Handles:
///   - Token registration on app start
///   - Token refresh when FCM generates a new token
///   - Token removal on sign out
///   - Foreground and background notification handling
class FcmMessagingService {
  FcmMessagingService({
    required FirebaseMessaging fcm,
    required FirebaseAuth auth,
    required FcmTokenRepository tokenRepository,
  }) : _fcm = fcm,
       _auth = auth,
       _tokenRepository = tokenRepository;

  final FirebaseMessaging _fcm;
  final FirebaseAuth _auth;
  final FcmTokenRepository _tokenRepository;

  StreamSubscription<String>? _tokenSubscription;
  StreamSubscription<RemoteMessage>? _foregroundSubscription;
  StreamSubscription<RemoteMessage>? _tapSubscription;
  StreamSubscription<User?>? _authSubscription;

  bool _initialized = false;
  Future<void> _tokenOperations = Future.value();

  Future<void> _enqueueTokenOperation(Future<void> Function() action) {
    final operation = _tokenOperations.then((_) => action());
    _tokenOperations = operation.catchError((Object _) {});
    return operation;
  }

  /// Initialize FCM: request permissions, register token, listen for refresh.
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    // Android 13+ and Apple platforms require notification permission.
    await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Register the current token.
    await _enqueueTokenOperation(() => _registerCurrentToken(null));

    // Listen for token refresh.
    _tokenSubscription = _fcm.onTokenRefresh.listen((token) {
      unawaited(_enqueueTokenOperation(() => _registerCurrentToken(token)).catchError((Object error) {
        debugPrint('FCM token refresh failed: $error');
      }));
    });

    // Listen to auth state changes to clean up tokens on sign out.
    _authSubscription = _auth.authStateChanges().listen((user) {
      if (user != null) {
        unawaited(_enqueueTokenOperation(() => _registerCurrentToken(null)).catchError((Object error) {
          debugPrint('FCM token registration failed: $error');
        }));
      }
    });

    // Foreground message handler.
    _foregroundSubscription = FirebaseMessaging.onMessage.listen((message) {
      _handleForegroundMessage(message);
    });

    // Background message handler (terminated/background state).
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Notification tap handler (app opened from notification).
    _tapSubscription = FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _handleNotificationTap(message);
    });
  }

  /// Dispose all subscriptions.
  Future<void> dispose() async {
    await _tokenSubscription?.cancel();
    await _foregroundSubscription?.cancel();
    await _tapSubscription?.cancel();
    await _authSubscription?.cancel();
    _initialized = false;
  }

  Future<void> _registerCurrentToken(String? newToken) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final token = newToken ?? await _fcm.getToken();
    if (token == null || _auth.currentUser?.uid != user.uid) return;

    final platform = defaultTargetPlatform.name;
    await _tokenRepository.saveToken(
      user.uid,
      FcmTokenEntity(
        token: token,
        userId: user.uid,
        email: user.email,
        deviceId: _fcm.app.name,
        platform: platform,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isActive: true,
      ),
    );
  }

  /// Remove this device's token while the current user is still authenticated.
  Future<void> unregisterCurrentDevice() => _enqueueTokenOperation(() async {
    final user = _auth.currentUser;
    if (user == null) return;
    final token = await _fcm.getToken();
    if (token != null) await _tokenRepository.removeToken(user.uid, token);
  });

  void _handleForegroundMessage(RemoteMessage message) {
    // Foreground notification received — the UI layer can react via the
    // notifications stream provider. No UI manipulation here to keep
    // the service layer clean.
    debugPrint('FCM foreground message: ${message.messageId}');
  }

  void _handleNotificationTap(RemoteMessage message) {
    // Notification tapped — navigation is handled by the UI layer
    // based on message.data['route'] or similar.
    debugPrint('FCM notification tap: ${message.messageId}');
  }
}

/// Top-level background handler for FCM messages when the app is terminated.
/// Must be a top-level function (not a method) for Flutter isolates.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Background message handling — no UI access available.
  // Store the message for later processing when the app opens.
  debugPrint('FCM background message: ${message.messageId}');
}

/// Factory to create the FCM messaging service with Firebase instances.
FcmMessagingService createFcmMessagingService({
  FirebaseMessaging? fcm,
  FirebaseAuth? auth,
  FirebaseFirestore? firestore,
  FcmTokenRepository? tokenRepository,
}) {
  return FcmMessagingService(
    fcm: fcm ?? FirebaseMessaging.instance,
    auth: auth ?? FirebaseAuth.instance,
    
    tokenRepository: tokenRepository ?? FcmTokenRepositoryImpl(firestore ?? FirebaseFirestore.instance),
  );
}
