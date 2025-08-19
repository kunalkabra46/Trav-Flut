import 'package:json_annotation/json_annotation.dart';

part 'user.g.dart';

@JsonSerializable()
class User {
  final String id;
  final String email;
  final String? username;
  final String? name;
  final String? avatarUrl;
  final String? bio;
  final bool isPrivate;
  final DateTime createdAt;
  final DateTime updatedAt;

  const User({
    required this.id,
    required this.email,
    this.username,
    this.name,
    this.avatarUrl,
    this.bio,
    required this.isPrivate,
    required this.createdAt,
    required this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
  Map<String, dynamic> toJson() => _$UserToJson(this);

  User copyWith({
    String? id,
    String? email,
    String? username,
    String? name,
    String? avatarUrl,
    String? bio,
    bool? isPrivate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      username: username ?? this.username,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      isPrivate: isPrivate ?? this.isPrivate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

@JsonSerializable()
class UserStats {
  final int tripCount;
  final int followerCount;
  final int followingCount;

  const UserStats({
    required this.tripCount,
    required this.followerCount,
    required this.followingCount,
  });

  factory UserStats.fromJson(Map<String, dynamic> json) =>
      _$UserStatsFromJson(json);
  Map<String, dynamic> toJson() => _$UserStatsToJson(this);
}

@JsonSerializable()
class AuthResponse {
  final User user;
  final String accessToken;
  final String refreshToken;

  const AuthResponse({
    required this.user,
    required this.accessToken,
    required this.refreshToken,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) =>
      _$AuthResponseFromJson(json);
  Map<String, dynamic> toJson() => _$AuthResponseToJson(this);
}

@JsonSerializable()
class FollowStatusResponse {
  final bool isFollowing;
  final bool isRequestPending;
  final String? requestId;

  const FollowStatusResponse({
    required this.isFollowing,
    required this.isRequestPending,
    this.requestId,
  });

  factory FollowStatusResponse.fromJson(Map<String, dynamic> json) {
    return FollowStatusResponse(
      isFollowing: json['isFollowing'] as bool? ?? false,
      isRequestPending: json['isRequestPending'] as bool? ?? false,
      requestId: json['requestId'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'isFollowing': isFollowing,
        'isRequestPending': isRequestPending,
        'requestId': requestId,
      };
}
class FollowRequestDto {
  final String id;
  final String followerId;
  final String followingId;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final User follower;

  const FollowRequestDto({
    required this.id,
    required this.followerId,
    required this.followingId,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.follower,
  });

  factory FollowRequestDto.fromJson(Map<String, dynamic> json) {
    return FollowRequestDto(
      id: json['id'] as String,
      followerId: json['followerId'] as String,
      followingId: json['followingId'] as String,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      follower: User.fromJson(json['follower'] as Map<String, dynamic>),
    );
  }
}
