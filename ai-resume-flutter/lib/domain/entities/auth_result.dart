/// 认证结果领域实体
library;

import 'user.dart';

/// 认证结果
///
/// 封装认证操作的结果
class AuthResult {
  final UserEntity user;
  final String token;
  final String refreshToken;
  final int expiresIn;

  const AuthResult({
    required this.user,
    required this.token,
    required this.refreshToken,
    required this.expiresIn,
  });

  /// 是否已过期
  bool get isExpired {
    return DateTime.now()
        .isAfter(DateTime.now().add(Duration(seconds: expiresIn)));
  }

  /// 复制并修改
  AuthResult copyWith({
    UserEntity? user,
    String? token,
    String? refreshToken,
    int? expiresIn,
  }) {
    return AuthResult(
      user: user ?? this.user,
      token: token ?? this.token,
      refreshToken: refreshToken ?? this.refreshToken,
      expiresIn: expiresIn ?? this.expiresIn,
    );
  }

  @override
  String toString() {
    return 'AuthResult(user: $user, token: *****, expiresIn: $expiresIn)';
  }
}
