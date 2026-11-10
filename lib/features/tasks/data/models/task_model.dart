import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flowtop/features/tasks/domain/entities/task_entity.dart';

/// Firestore document model for the "tasks" collection.
class TaskModel {
  const TaskModel({
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
  final String status;
  final String priority;
  final String category;
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

  factory TaskModel.fromEntity(TaskEntity entity) {
    return TaskModel(
      id: entity.id,
      title: entity.title,
      description: entity.description,
      status: _enumName(entity.status),
      priority: _enumName(entity.priority),
      category: _enumName(entity.category),
      ownerId: entity.ownerId,
      assigneeId: entity.assigneeId,
      projectId: entity.projectId,
      workspaceId: entity.workspaceId,
      dueDate: entity.dueDate,
      reminderAt: entity.reminderAt,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      completedAt: entity.completedAt,
      attachmentIds: entity.attachmentIds,
      subtaskIds: entity.subtaskIds,
    );
  }

  factory TaskModel.fromMap(String id, Map<String, dynamic> map) {
    return TaskModel(
      id: id,
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      status: map['status'] as String? ?? 'todo',
      priority: map['priority'] as String? ?? 'medium',
      category: map['category'] as String? ?? 'personal',
      ownerId: map['ownerId'] as String? ?? '',
      assigneeId: map['assigneeId'] as String?,
      projectId: map['projectId'] as String?,
      workspaceId: map['workspaceId'] as String?,
      dueDate: _toDateTime(map['dueDate']),
      reminderAt: _toDateTime(map['reminderAt']),
      createdAt: _toDateTime(map['createdAt']),
      updatedAt: _toDateTime(map['updatedAt']),
      completedAt: _toDateTime(map['completedAt']),
      attachmentIds: List<String>.from(map['attachmentIds'] ?? const []),
      subtaskIds: List<String>.from(map['subtaskIds'] ?? const []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'status': status,
      'priority': priority,
      'category': category,
      'ownerId': ownerId,
      if (assigneeId != null) 'assigneeId': assigneeId,
      if (projectId != null) 'projectId': projectId,
      if (workspaceId != null) 'workspaceId': workspaceId,
      if (dueDate != null) 'dueDate': Timestamp.fromDate(dueDate!),
      if (reminderAt != null) 'reminderAt': Timestamp.fromDate(reminderAt!),
      if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
      if (completedAt != null) 'completedAt': Timestamp.fromDate(completedAt!),
      'attachmentIds': attachmentIds,
      'subtaskIds': subtaskIds,
    };
  }

  TaskEntity toEntity() {
    return TaskEntity(
      id: id,
      title: title,
      description: description,
      status: _parseStatus(status),
      priority: _parsePriority(priority),
      category: _parseCategory(category),
      ownerId: ownerId,
      assigneeId: assigneeId,
      projectId: projectId,
      workspaceId: workspaceId,
      dueDate: dueDate,
      reminderAt: reminderAt,
      createdAt: createdAt,
      updatedAt: updatedAt,
      completedAt: completedAt,
      attachmentIds: attachmentIds,
      subtaskIds: subtaskIds,
    );
  }

  TaskModel copyWith({
    String? id,
    String? title,
    String? description,
    String? status,
    String? priority,
    String? category,
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
    return TaskModel(
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

  static String _enumName(dynamic e) {
    return e.toString().split('.').last;
  }

  static TaskStatus _parseStatus(String v) {
    switch (v) {
      case 'inProgress': return TaskStatus.inProgress;
      case 'done': return TaskStatus.done;
      default: return TaskStatus.todo;
    }
  }

  static TaskPriority _parsePriority(String v) {
    switch (v) {
      case 'low': return TaskPriority.low;
      case 'high': return TaskPriority.high;
      default: return TaskPriority.medium;
    }
  }

  static TaskCategory _parseCategory(String v) {
    switch (v) {
      case 'work': return TaskCategory.work;
      case 'health': return TaskCategory.health;
      case 'finance': return TaskCategory.finance;
      case 'other': return TaskCategory.other;
      default: return TaskCategory.personal;
    }
  }

  static DateTime? _toDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}
