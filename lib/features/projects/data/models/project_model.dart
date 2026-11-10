import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flowtop/features/projects/domain/entities/project_entity.dart';

class ProjectModel {
  const ProjectModel({
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

  factory ProjectModel.fromEntity(ProjectEntity e) => ProjectModel(
    id: e.id, name: e.name, description: e.description, ownerId: e.ownerId,
    workspaceId: e.workspaceId, color: e.color, taskIds: e.taskIds,
    progress: e.progress, createdAt: e.createdAt, updatedAt: e.updatedAt,
  );

  factory ProjectModel.fromMap(String id, Map<String, dynamic> m) => ProjectModel(
    id: id,
    name: m['name'] as String? ?? '',
    description: m['description'] as String? ?? '',
    ownerId: m['ownerId'] as String? ?? '',
    workspaceId: m['workspaceId'] as String? ?? '',
    color: (m['color'] as num?)?.toInt() ?? 0xFF7C3AED,
    taskIds: List<String>.from(m['taskIds'] ?? const []),
    progress: (m['progress'] as num?)?.toDouble() ?? 0.0,
    createdAt: _dt(m['createdAt']),
    updatedAt: _dt(m['updatedAt']),
  );

  Map<String, dynamic> toMap() => {
    'name': name, 'description': description, 'ownerId': ownerId,
    'workspaceId': workspaceId, 'color': color,
    'taskIds': taskIds,
    'progress': progress,
    if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
    if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
  };

  ProjectEntity toEntity() => ProjectEntity(
    id: id, name: name, description: description, ownerId: ownerId,
    workspaceId: workspaceId, color: color, taskIds: taskIds,
    progress: progress, createdAt: createdAt, updatedAt: updatedAt,
  );

  static DateTime? _dt(dynamic v) {
    if (v == null) return null;
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    return null;
  }
}
