import 'package:equatable/equatable.dart';

class ProjectEntity extends Equatable {
  const ProjectEntity({
    required this.id,
    required this.name,
    this.description = '',
    required this.ownerId,
    required this.workspaceId,
    this.color = 0xFF7C3AED,
    this.taskIds = const [],
    this.progress = 0.0,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  final String description;
  final String ownerId;
  final String workspaceId;
  final int color;
  final List<String> taskIds;
  final double progress;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// Recalculate progress from a list of tasks.
  /// Each task's status contributes: todo=0, inProgress=0.5, done=1.
  double recalculateProgress(List<Map<String, dynamic>> tasks) {
    if (tasks.isEmpty) return 0.0;
    double total = 0.0;
    for (final task in tasks) {
      final status = task['status'] as String?;
      switch (status) {
        case 'todo':
          total += 0.0;
          break;
        case 'inProgress':
          total += 0.5;
          break;
        case 'done':
          total += 1.0;
          break;
        default:
          total += 0.0;
          break;
      }
    }
    return total / tasks.length;
  }

  @override
  List<Object?> get props => [
        id, name, description, ownerId, workspaceId, color, taskIds,
        progress, createdAt, updatedAt,
      ];

  ProjectEntity copyWith({
    String? id, String? name, String? description, String? ownerId, String? workspaceId,
    int? color, List<String>? taskIds, double? progress, DateTime? createdAt, DateTime? updatedAt,
  }) {
    return ProjectEntity(
      id: id ?? this.id, name: name ?? this.name, description: description ?? this.description,
      ownerId: ownerId ?? this.ownerId, workspaceId: workspaceId ?? this.workspaceId,
      color: color ?? this.color, taskIds: taskIds ?? this.taskIds,
      progress: progress ?? this.progress, createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
