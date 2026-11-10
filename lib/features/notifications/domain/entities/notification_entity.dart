import 'package:equatable/equatable.dart';

enum NotificationType {
  taskAssigned,
  taskReminder,
  workspaceInvitation,
  taskDueSoon,
}

class NotificationEntity extends Equatable {
  const NotificationEntity({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    this.data = const <String, dynamic>{},
    required this.createdAt,
    this.read = false,
  });

  final String id;
  final NotificationType type;
  final String title;
  final String body;
  final Map<String, dynamic> data;
  final DateTime createdAt;
  final bool read;

  @override
  List<Object?> get props => [id, type, title, body, data, createdAt, read];
}
