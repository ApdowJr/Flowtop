import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

enum TaskStatus { todo, inProgress, done }
enum TaskPriority { low, medium, high }
enum TaskCategory { personal, work, health, finance, other }

extension TaskStatusExtension on TaskStatus {
  String get label {
    switch (this) {
      case TaskStatus.todo: return 'Todo';
      case TaskStatus.inProgress: return 'In progress';
      case TaskStatus.done: return 'Done';
    }
  }

  Color get color {
    switch (this) {
      case TaskStatus.todo: return const Color(0xFF9CA3AF);
      case TaskStatus.inProgress: return const Color(0xFF3B82F6);
      case TaskStatus.done: return const Color(0xFF22C55E);
    }
  }
}

extension TaskPriorityExtension on TaskPriority {
  String get label {
    switch (this) {
      case TaskPriority.low: return 'Low';
      case TaskPriority.medium: return 'Medium';
      case TaskPriority.high: return 'High';
    }
  }

  Color get color {
    switch (this) {
      case TaskPriority.low: return const Color(0xFF22C55E);
      case TaskPriority.medium: return const Color(0xFFF59E0B);
      case TaskPriority.high: return const Color(0xFFEF4444);
    }
  }
}

extension TaskCategoryExtension on TaskCategory {
  String get label {
    switch (this) {
      case TaskCategory.personal: return 'Personal';
      case TaskCategory.work: return 'Work';
      case TaskCategory.health: return 'Health';
      case TaskCategory.finance: return 'Finance';
      case TaskCategory.other: return 'Other';
    }
  }

  IconData get icon {
    switch (this) {
      case TaskCategory.personal: return Icons.person;
      case TaskCategory.work: return Icons.work;
      case TaskCategory.health: return Icons.favorite;
      case TaskCategory.finance: return Icons.account_balance_wallet;
      case TaskCategory.other: return Icons.label;
    }
  }
}

/// A task in flowTop. Belongs to a personal workspace or a team workspace.
class TaskEntity extends Equatable {
  const TaskEntity({
    required this.id,
    required this.title,
    this.description = '',
    required this.status,
    required this.priority,
    required this.category,
    required this.ownerId,
    this.assigneeId,
    this.projectId,
    this.workspaceId,
    this.dueDate,
    this.reminderAt,
    this.createdAt,
    this.updatedAt,
    this.completedAt,
    this.attachmentIds = const [],
    this.subtaskIds = const [],
  });

  final String id;
  final String title;
  final String description;
  final TaskStatus status;
  final TaskPriority priority;
  final TaskCategory category;
  final String ownerId;
  final String? assigneeId;
  final String? projectId;
  final String? workspaceId;
  final DateTime? dueDate;
  final DateTime? reminderAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? completedAt;
  final List<String> attachmentIds;
  final List<String> subtaskIds;

  bool get isOverdue =>
      status != TaskStatus.done && dueDate != null && dueDate!.isBefore(DateTime.now());

  @override
  List<Object?> get props => [
        id, title, description, status, priority, category, ownerId,
        assigneeId, projectId, workspaceId, dueDate, reminderAt, createdAt,
        updatedAt, completedAt, attachmentIds, subtaskIds,
      ];

  TaskEntity copyWith({
    String? id,
    String? title,
    String? description,
    TaskStatus? status,
    TaskPriority? priority,
    TaskCategory? category,
    String? ownerId,
    String? assigneeId,
    String? projectId,
    String? workspaceId,
    DateTime? dueDate,
    DateTime? reminderAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? completedAt,
    List<String>? attachmentIds,
    List<String>? subtaskIds,
  }) {
    return TaskEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      category: category ?? this.category,
      ownerId: ownerId ?? this.ownerId,
      assigneeId: assigneeId ?? this.assigneeId,
      projectId: projectId ?? this.projectId,
      workspaceId: workspaceId ?? this.workspaceId,
      dueDate: dueDate ?? this.dueDate,
      reminderAt: reminderAt ?? this.reminderAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: completedAt ?? this.completedAt,
      attachmentIds: attachmentIds ?? this.attachmentIds,
      subtaskIds: subtaskIds ?? this.subtaskIds,
    );
  }
}


