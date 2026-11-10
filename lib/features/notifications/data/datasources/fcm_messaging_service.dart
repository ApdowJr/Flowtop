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
    required this._fcm,
    required this._auth,
    required this._firestore,
    required this._tokenRepository,
  });

  final FirebaseMessaging _fcm;
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final FcmTokenRepository _tokenRepository;

  StreamSubscription<String>? _tokenSubscription;
  StreamSubscription<RemoteMessage>? _foregroundSubscription;
  StreamSubscription<RemoteMessage>? _backgroundSubscription;
  StreamSubscription<User?>? _authSubscription;

  bool _initialized = false;

  /// Initialize FCM: request permissions, register token, listen for refresh.
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    // Request notification permissions (iOS/macOS; Android auto-grants).
    await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Register the current token.
    await _registerCurrentToken();

    // Listen for token refresh.
    _tokenSubscription = _fcm.onTokenRefresh.listen(_registerCurrentToken);

    // Listen to auth state changes to clean up tokens on sign out.
    _authSubscription = _auth.authStateChanges().listen((user) {
      if (user == null) {
        // User signed out — deactivate all tokens.
        _deactivateAllTokens();
      } else {
        // User signed in — ensure token is registered.
        _registerCurrentToken();
      }
    });

    // Foreground message handler.
    _foregroundSubscription = FirebaseMessaging.onMessage.listen((message) {
      _handleForegroundMessage(message);
    });

    // Background message handler (terminated/background state).
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Notification tap handler (app opened from notification).
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _handleNotificationTap(message);
    });
  }

  /// Dispose all subscriptions.
  Future<void> dispose() async {
    await _tokenSubscription?.cancel();
    await _foregroundSubscription?.cancel();
    await _backgroundSubscription?.cancel();
    await _authSubscription?.cancel();
    _initialized = false;
  }

  Future<void> _registerCurrentToken(String? newToken) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final token = newToken ?? await _fcm.getToken();
    if (token == null) return;

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

  Future<void> _deactivateAllTokens() async {
    final user = _auth.currentUser;
    if (user == null) return;
    await _tokenRepository.deactivateAllTokens(user.uid);
  }

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
    _fcm: fcm ?? FirebaseMessaging.instance,
    _auth: auth ?? FirebaseAuth.instance,
    _firestore: firestore ?? FirebaseFirestore.instance,
    _tokenRepository: tokenRepository ?? FcmTokenRepositoryImpl(firestore ?? FirebaseFirestore.instance),
  );
}
