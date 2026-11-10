import 'package:equatable/equatable.dart';

/// Represents a Firebase Cloud Messaging device token.
class FcmTokenEntity extends Equatable {
  const FcmTokenEntity({
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

  @override
  List<Object?> get props =>
      [token, userId, email, deviceId, platform, createdAt, updatedAt, isActive];

  FcmTokenEntity copyWith({
    String? token,
    String? userId,
    String? email,
    String? deviceId,
    String? platform,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return FcmTokenEntity(
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
}
