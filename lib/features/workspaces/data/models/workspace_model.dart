import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flowtop/features/workspaces/domain/entities/workspace_entity.dart';

/// Firestore document model for the "workspaces" collection.
class WorkspaceModel {
  const WorkspaceModel({
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
  final String role;
  final int memberCount;
  final int color;
  final DateTime? createdAt;
  final bool isPersonal;

  factory WorkspaceModel.fromEntity(WorkspaceEntity entity) {
    return WorkspaceModel(
      id: entity.id,
      name: entity.name,
      description: entity.description,
      ownerId: entity.ownerId,
      role: _roleName(entity.role),
      memberCount: entity.memberCount,
      color: entity.color,
      createdAt: entity.createdAt,
      isPersonal: entity.isPersonal,
    );
  }

  factory WorkspaceModel.fromMap(String id, Map<String, dynamic> map) {
    return WorkspaceModel(
      id: id,
      name: map['name'] as String? ?? '',
      description: map['description'] as String? ?? '',
      ownerId: map['ownerId'] as String? ?? '',
      role: map['role'] as String? ?? 'member',
      memberCount: (map['memberCount'] as num?)?.toInt() ?? 0,
      color: (map['color'] as num?)?.toInt() ?? 0xFF7C3AED,
      createdAt: _toDateTime(map['createdAt']),
      isPersonal: (map['isPersonal'] as bool?) ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'ownerId': ownerId,
      'role': role,
      'memberCount': memberCount,
      'color': color,
      if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
      'isPersonal': isPersonal,
    };
  }

  WorkspaceEntity toEntity() {
    return WorkspaceEntity(
      id: id,
      name: name,
      description: description,
      ownerId: ownerId,
      role: _parseRole(role),
      memberCount: memberCount,
      color: color,
      createdAt: createdAt,
      isPersonal: isPersonal,
    );
  }

  WorkspaceModel copyWith({
    String? id, String? name, String? description, String? ownerId, String? role,
    int? memberCount, int? color, DateTime? createdAt, bool? isPersonal,
  }) {
    return WorkspaceModel(
      id: id ?? this.id, name: name ?? this.name, description: description ?? this.description,
      ownerId: ownerId ?? this.ownerId, role: role ?? this.role,
      memberCount: memberCount ?? this.memberCount, color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt, isPersonal: isPersonal ?? this.isPersonal,
    );
  }

  static String _roleName(WorkspaceRole role) {
    switch (role) {
      case WorkspaceRole.owner: return 'owner';
      case WorkspaceRole.admin: return 'admin';
      case WorkspaceRole.manager: return 'manager';
      case WorkspaceRole.member: return 'member';
      case WorkspaceRole.viewer: return 'viewer';
    }
  }

  static WorkspaceRole _parseRole(String v) {
    switch (v) {
      case 'owner': return WorkspaceRole.owner;
      case 'admin': return WorkspaceRole.admin;
      case 'manager': return WorkspaceRole.manager;
      case 'viewer': return WorkspaceRole.viewer;
      default: return WorkspaceRole.member;
    }
  }

  static DateTime? _toDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}

/// Firestore document model for workspace members subcollection.
class WorkspaceMemberModel {
  const WorkspaceMemberModel({
    required this.id,
    required this.workspaceId,
    required this.userId,
    required this.role,
    this.joinedAt,
    this.email,
    this.displayName,
  });

  final String id;
  final String workspaceId;
  final String userId;
  final String role;
  final DateTime? joinedAt;
  final String? email;
  final String? displayName;

  factory WorkspaceMemberModel.fromEntity(WorkspaceMemberEntity entity) {
    return WorkspaceMemberModel(
      id: entity.userId,
      workspaceId: entity.workspaceId,
      userId: entity.userId,
      role: _roleName(entity.role),
      joinedAt: entity.joinedAt,
      email: entity.email,
      displayName: entity.displayName,
    );
  }

  factory WorkspaceMemberModel.fromMap(String id, Map<String, dynamic> map) {
    return WorkspaceMemberModel(
      id: id,
      workspaceId: map['workspaceId'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      role: map['role'] as String? ?? 'member',
      joinedAt: _toDateTime(map['joinedAt']),
      email: map['email'] as String?,
      displayName: map['displayName'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'workspaceId': workspaceId,
      'userId': userId,
      'role': role,
      if (joinedAt != null) 'joinedAt': Timestamp.fromDate(joinedAt!),
      if (email != null) 'email': email,
      if (displayName != null) 'displayName': displayName,
    };
  }

  WorkspaceMemberEntity toEntity() {
    return WorkspaceMemberEntity(
      workspaceId: workspaceId,
      userId: userId,
      role: _parseRole(role),
      joinedAt: joinedAt,
      email: email,
      displayName: displayName,
    );
  }

  static String _roleName(WorkspaceRole role) {
    switch (role) {
      case WorkspaceRole.owner: return 'owner';
      case WorkspaceRole.admin: return 'admin';
      case WorkspaceRole.manager: return 'manager';
      case WorkspaceRole.member: return 'member';
      case WorkspaceRole.viewer: return 'viewer';
    }
  }

  static WorkspaceRole _parseRole(String v) {
    switch (v) {
      case 'owner': return WorkspaceRole.owner;
      case 'admin': return WorkspaceRole.admin;
      case 'manager': return WorkspaceRole.manager;
      case 'viewer': return WorkspaceRole.viewer;
      default: return WorkspaceRole.member;
    }
  }

  static DateTime? _toDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}
