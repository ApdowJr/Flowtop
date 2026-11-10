import 'package:equatable/equatable.dart';

enum WorkspaceRole { owner, admin, manager, member, viewer }

extension WorkspaceRoleExtension on WorkspaceRole {
  String get label {
    switch (this) {
      case WorkspaceRole.owner: return 'Owner';
      case WorkspaceRole.admin: return 'Admin';
      case WorkspaceRole.manager: return 'Manager';
      case WorkspaceRole.member: return 'Member';
      case WorkspaceRole.viewer: return 'Viewer';
    }
  }

  bool get canInvite => this == WorkspaceRole.owner || this == WorkspaceRole.admin || this == WorkspaceRole.manager;
  bool get canChangeRoles => this == WorkspaceRole.owner || this == WorkspaceRole.admin;
  bool get canEdit => this != WorkspaceRole.viewer;
}

class WorkspaceEntity extends Equatable {
  const WorkspaceEntity({
    required this.id,
    required this.name,
    this.description = '',
    required this.ownerId,
    required this.role,
    this.memberCount = 0,
    this.color = 0xFF7C3AED,
    this.createdAt,
    this.isPersonal = false,
  });

  final String id;
  final String name;
  final String description;
  final String ownerId;
  final WorkspaceRole role;
  final int memberCount;
  final int color;
  final DateTime? createdAt;
  final bool isPersonal;

  @override
  List<Object?> get props => [id, name, description, ownerId, role, memberCount, color, createdAt, isPersonal];

  WorkspaceEntity copyWith({
    String? id, String? name, String? description, String? ownerId, WorkspaceRole? role,
    int? memberCount, int? color, DateTime? createdAt, bool? isPersonal,
  }) {
    return WorkspaceEntity(
      id: id ?? this.id, name: name ?? this.name, description: description ?? this.description,
      ownerId: ownerId ?? this.ownerId, role: role ?? this.role,
      memberCount: memberCount ?? this.memberCount, color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt, isPersonal: isPersonal ?? this.isPersonal,
    );
  }
}

class WorkspaceMemberEntity extends Equatable {
  const WorkspaceMemberEntity({
    required this.workspaceId,
    required this.userId,
    required this.role,
    this.joinedAt,
  });

  final String workspaceId;
  final String userId;
  final WorkspaceRole role;
  final DateTime? joinedAt;

  @override
  List<Object?> get props => [workspaceId, userId, role, joinedAt];
}
