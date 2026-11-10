import 'package:equatable/equatable.dart';

class SubtaskEntity extends Equatable {
  const SubtaskEntity({
    required this.id,
    required this.taskId,
    required this.workspaceId,
    required this.title,
    this.isCompleted = false,
    this.createdAt,
  });

  final String id;
  final String taskId;
  final String workspaceId;
  final String title;
  final bool isCompleted;
  final DateTime? createdAt;

  @override
  List<Object?> get props => [id, taskId, workspaceId, title, isCompleted, createdAt];

  SubtaskEntity copyWith({
    String? id,
    String? taskId,
    String? workspaceId,
    String? title,
    bool? isCompleted,
    DateTime? createdAt,
  }) {
    return SubtaskEntity(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      workspaceId: workspaceId ?? this.workspaceId,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
