import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flowtop/features/notifications/data/repositories/fcm_token_repository_impl.dart';
import 'package:flowtop/features/notifications/data/datasources/fcm_messaging_service.dart';
import 'package:flowtop/features/notifications/domain/entities/fcm_token_entity.dart';
import 'package:flowtop/features/notifications/domain/entities/notification_entity.dart';
import 'package:flowtop/features/notifications/domain/repositories/fcm_token_repository.dart';

/// FCM token repository provider.
final fcmTokenRepositoryProvider = Provider<FcmTokenRepository>((ref) {
  final firestore = FirebaseFirestore.instance;
  return FcmTokenRepositoryImpl(firestore);
});

/// FCM messaging service provider — initialized with Firebase instances.
final fcmMessagingServiceProvider = Provider<FcmMessagingService>((ref) {
  final tokenRepository = ref.watch(fcmTokenRepositoryProvider);
  return createFcmMessagingService(
    tokenRepository: tokenRepository,
  );
});

/// FCM token entity provider — family over user ID.
final fcmTokensProvider = StreamProvider.family<List<FcmTokenEntity>, String>(
  (ref, userId) {
    final repository = ref.watch(fcmTokenRepositoryProvider);
    return repository.watchTokens(userId);
  },
);

/// Notifier that initializes FCM when the user signs in.
class FcmInitializerNotifier extends StateNotifier<bool> {
  FcmInitializerNotifier(this._ref, String userId) : super(false) {
    _initialize();
  }

  final Ref _ref;
  StreamSubscription? _authSubscription;

  Future<void> _initialize() async {
    try {
      final service = _ref.read(fcmMessagingServiceProvider);
      await service.initialize();
      state = true;
    } catch (e) {
      state = false;
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}

/// FCM initializer provider — family over user ID.
final fcmInitializerProvider = StateNotifierProvider.family<
    FcmInitializerNotifier, bool, String>(
  (ref, userId) => FcmInitializerNotifier(ref, userId),
);

/// Notification repository — reads from Firestore.
final notificationRepositoryProvider = Provider((ref) {
  return _NotificationRepositoryImpl(FirebaseFirestore.instance);
});

/// Stream of notifications for the current user.
final notificationsProvider = StreamProvider.family<List<NotificationEntity>, String>(
  (ref, userId) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            return NotificationEntity(
              id: doc.id,
              type: _parseType(data['type'] as String?),
              title: data['title'] as String? ?? '',
              body: data['body'] as String? ?? '',
              data: Map<String, dynamic>.from(data['data'] ?? const {}),
              createdAt: _toDateTime(data['createdAt']) ?? DateTime.now(),
              read: (data['read'] as bool?) ?? false,
            );
          }).toList();
        });
  },
);

/// Unread notification count provider — family over user ID.
final unreadCountProvider = StreamProvider.family<int, String>(
  (ref, userId) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .where('read', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  },
);

/// Mark a notification as read.
final markNotificationReadProvider =
    Provider.family<Future<void> Function(String notificationId), String>((ref, userId) {
  return (notificationId) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .doc(notificationId)
        .update({'read': true});
  };
});

/// Internal notification repository implementation.
class _NotificationRepositoryImpl {
  _NotificationRepositoryImpl(this._firestore);
  final FirebaseFirestore _firestore;

  Future<void> createNotification({
    required String userId,
    required String title,
    required String body,
    required String type,
    Map<String, dynamic> data = const {},
  }) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .add({
      'title': title,
      'body': body,
      'type': type,
      'data': data,
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}

NotificationType _parseType(String? v) {
  switch (v) {
    case 'task_assigned': return NotificationType.taskAssigned;
    case 'task_reminder': return NotificationType.taskReminder;
    case 'workspace_invitation': return NotificationType.workspaceInvitation;
    case 'task_due_soon': return NotificationType.taskDueSoon;
    default: return NotificationType.taskReminder;
  }
}

DateTime? _toDateTime(dynamic value) {
  if (value == null) return null;
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  return null;
}
