import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flowtop/features/notifications/domain/entities/fcm_token_entity.dart';

/// Firestore document model for FCM tokens.
class FcmTokenModel {
  const FcmTokenModel({
    required this.token,
    required this.userId,
    this.email,
    this.deviceId,
    this.platform,
    this.createdAt,
    this.updatedAt,
    this.isActive = true,
  });

  final String token;
  final String userId;
  final String? email;
  final String? deviceId;
  final String? platform;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool isActive;

  factory FcmTokenModel.fromEntity(FcmTokenEntity entity) {
    return FcmTokenModel(
      token: entity.token,
      userId: entity.userId,
      email: entity.email,
      deviceId: entity.deviceId,
      platform: entity.platform,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      isActive: entity.isActive,
    );
  }

  factory FcmTokenModel.fromMap(String id, Map<String, dynamic> map) {
    return FcmTokenModel(
      token: id,
      userId: map['userId'] as String? ?? '',
      email: map['email'] as String?,
      deviceId: map['deviceId'] as String?,
      platform: map['platform'] as String?,
      createdAt: _toDateTime(map['createdAt']),
      updatedAt: _toDateTime(map['updatedAt']),
      isActive: (map['isActive'] as bool?) ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      if (email != null) 'email': email,
      if (deviceId != null) 'deviceId': deviceId,
      if (platform != null) 'platform': platform,
      if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
      'isActive': isActive,
    };
  }

  FcmTokenEntity toEntity() {
    return FcmTokenEntity(
      token: token,
      userId: userId,
      email: email,
      deviceId: deviceId,
      platform: platform,
      createdAt: createdAt,
      updatedAt: updatedAt,
      isActive: isActive,
    );
  }

  FcmTokenModel copyWith({
    String? token,
    String? userId,
    String? email,
    String? deviceId,
    String? platform,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return FcmTokenModel(
      token: token ?? this.token,
      userId: userId ?? this.userId,
      email: email ?? this.email,
      deviceId: deviceId ?? this.deviceId,
      platform: platform ?? this.platform,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
    );
  }

  static DateTime? _toDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}
