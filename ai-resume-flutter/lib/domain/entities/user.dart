/// 用户领域实体
///
/// 领域实体是Clean Architecture中的核心业务对象
/// 与数据模型的区别：
/// - 数据模型(data/models)用于数据传输和存储
/// - 领域实体(domain/entities)用于业务逻辑处理
library;

import 'package:ai_resume_flutter/data/models/user.dart';

/// 用户实体
///
/// 表示应用中的用户概念，包含核心业务属性
class UserEntity {
  final String id;
  final String email;
  final String? nickname;
  final String? avatar;
  final String role;
  final bool isVip;
  final DateTime? vipExpireAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserEntity({
    required this.id,
    required this.email,
    this.nickname,
    this.avatar,
    this.role = 'user',
    this.isVip = false,
    this.vipExpireAt,
    required this.createdAt,
    required this.updatedAt,
  });

  /// 从数据模型创建实体
  factory UserEntity.fromModel(User model) {
    return UserEntity(
      id: model.id,
      email: model.email,
      nickname: model.nickname,
      avatar: model.avatar,
      role: model.role,
      isVip: model.isVip,
      vipExpireAt: model.vipExpireAt,
      createdAt: model.createdAt,
      updatedAt: model.updatedAt,
    );
  }

  /// 转换为数据模型
  User toModel() {
    return User(
      id: id,
      email: email,
      nickname: nickname,
      avatar: avatar,
      role: role,
      isVip: isVip,
      vipExpireAt: vipExpireAt,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  /// 复制并修改部分属性
  UserEntity copyWith({
    String? id,
    String? email,
    String? nickname,
    String? avatar,
    String? role,
    bool? isVip,
    DateTime? vipExpireAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserEntity(
      id: id ?? this.id,
      email: email ?? this.email,
      nickname: nickname ?? this.nickname,
      avatar: avatar ?? this.avatar,
      role: role ?? this.role,
      isVip: isVip ?? this.isVip,
      vipExpireAt: vipExpireAt ?? this.vipExpireAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// 检查VIP是否有效
  bool get isVipActive {
    if (!isVip) return false;
    if (vipExpireAt == null) return true;
    return DateTime.now().isBefore(vipExpireAt!);
  }

  /// 获取显示名称
  String get displayName {
    return nickname?.isNotEmpty == true ? nickname! : email.split('@')[0];
  }

  /// 是否为管理员
  bool get isAdmin => role == 'admin';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserEntity && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'UserEntity(id: $id, email: $email, nickname: $nickname, role: $role, isVip: $isVip)';
  }
}

/// 用户实体扩展
extension UserEntityExtension on UserEntity {
  /// 获取VIP剩余天数
  int? get vipRemainingDays {
    if (vipExpireAt == null) return null;
    final diff = vipExpireAt!.difference(DateTime.now());
    return diff.isNegative ? 0 : diff.inDays;
  }

  /// VIP是否即将过期（7天内）
  bool get isVipExpiringSoon {
    final days = vipRemainingDays;
    return days != null && days <= 7 && days >= 0;
  }

  /// VIP是否已过期
  bool get isVipExpired {
    if (!isVip) return false;
    if (vipExpireAt == null) return false;
    return DateTime.now().isAfter(vipExpireAt!);
  }
}
