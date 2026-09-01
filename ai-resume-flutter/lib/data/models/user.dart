import 'package:json_annotation/json_annotation.dart';

part 'user.g.dart';

/// 用户实体
@JsonSerializable()
class User {
  final String id;
  final String email;
  final String? nickname;
  final String? avatar;
  final String role;
  final bool isVip;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  User({
    required this.id,
    required this.email,
    this.nickname,
    this.avatar,
    this.role = 'user',
    this.isVip = false,
    this.createdAt,
    this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);

  Map<String, dynamic> toJson() => _$UserToJson(this);

  User copyWith({
    String? id,
    String? email,
    String? nickname,
    String? avatar,
    String? role,
    bool? isVip,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      nickname: nickname ?? this.nickname,
      avatar: avatar ?? this.avatar,
      role: role ?? this.role,
      isVip: isVip ?? this.isVip,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// 用户角色枚举
enum UserRole {
  @JsonValue('user')
  user,
  @JsonValue('vip')
  vip,
  @JsonValue('admin')
  admin,
}
