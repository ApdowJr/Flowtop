import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flowtop/core/constants/app_constants.dart';
import 'package:flowtop/core/widgets/app_loading.dart';
import 'package:flowtop/core/widgets/app_empty_state.dart';
import 'package:flowtop/core/widgets/app_error_state.dart';
import 'package:flowtop/features/auth/presentation/providers/auth_provider.dart';
import 'package:flowtop/features/notifications/presentation/providers/notification_provider.dart';
import 'package:flowtop/features/notifications/domain/entities/notification_entity.dart';

/// Notifications page with real-time notification list.
class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    if (user == null) {
      return const AppEmptyState(
        title: 'Sign in to view notifications',
        subtitle: 'Please sign in to see your notifications.',
        icon: Icons.notifications_outlined,
      );
    }

    final notificationsAsync = ref.watch(notificationsProvider(user.uid));

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(AppStrings.notifications),
        actions: [
          // Mark all as read
          Consumer(
            builder: (context, ref, child) {
              final unreadAsync = ref.watch(unreadCountProvider(user.uid));
              final unread = unreadAsync.valueOrNull ?? 0;
              if (unread == 0) return const SizedBox.shrink();
              return TextButton(
                onPressed: () {
                  // Mark all as read — implemented via batch update
                  _markAllRead(context, ref, user.uid);
                },
                child: const Text('Mark all read'),
              );
            },
          ),
        ],
      ),
      body: notificationsAsync.when(
        data: (notifications) {
          if (notifications.isEmpty) {
            return AppEmptyState(
              title: 'No notifications',
              subtitle: 'You will receive task assignments, reminders, and invitations here.',
              icon: Icons.notifications_outlined,
            );
          }
          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return _NotificationTile(
                notification: notification,
                userId: user.uid,
              );
            },
          );
        },
        loading: () => const AppPageLoading(message: AppStrings.loading),
        error: (error, _) => AppErrorState(
          message: error.toString(),
          onRetry: () => ref.invalidate(notificationsProvider(user.uid)),
        ),
      ),
    );
  }

  Future<void> _markAllRead(
      BuildContext context, WidgetRef ref, String userId) async {
    final batch = FirebaseFirestore.instance.batch();
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .where('read', isEqualTo: false)
        .get();
    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {'read': true});
    }
    if (snapshot.docs.isNotEmpty) {
      await batch.commit();
    }
  }
}

/// Individual notification tile.
class _NotificationTile extends ConsumerWidget {
  const _NotificationTile({
    required this.notification,
    required this.userId,
  });

  final NotificationEntity notification;
  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isRead = notification.read;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: _iconForType(notification.type),
      ),
      title: Text(
        notification.title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 15,
          color: isRead ? AppColors.textSecondary : AppColors.textPrimary,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(
            notification.body,
            style: TextStyle(
              fontSize: 13,
              color: isRead ? AppColors.textSecondary : AppColors.textPrimary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            '${notification.createdAt.day}/${notification.createdAt.month}/${notification.createdAt.year}',
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
        ],
      ),
      trailing: !isRead
          ? Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
            )
          : null,
      tileColor: isRead ? null : AppColors.primary.withOpacity(0.03),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onTap: () async {
        if (!isRead) {
          await ref.read(markNotificationReadProvider(userId))(notification.id);
        }
        // Navigation based on notification data would go here.
      },
    );
  }

  Icon _iconForType(NotificationType type) {
    IconData icon;
    Color color;
    switch (type) {
      case NotificationType.taskAssigned:
        icon = Icons.task_alt;
        color = AppColors.primary;
        break;
      case NotificationType.taskReminder:
        icon = Icons.schedule;
        color = AppColors.secondary;
        break;
      case NotificationType.workspaceInvitation:
        icon = Icons.people;
        color = AppColors.success;
        break;
      case NotificationType.taskDueSoon:
        icon = Icons.warning;
        color = AppColors.warning;
        break;
    }
    return Icon(icon, color: color, size: 24);
  }
}
