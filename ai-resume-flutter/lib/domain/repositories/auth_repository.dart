/// 认证仓库接口
///
/// 定义认证相关的数据操作契约
/// Data层需要实现此接口
library;

import 'package:dartz/dartz.dart';
import 'package:ai_resume_flutter/core/errors/failures.dart';
import '../entities/auth_result.dart';

/// 认证仓库接口
abstract class AuthRepository {
  /// 初始化认证状态
  ///
  /// 返回 [Right] 包含当前用户信息，如果未登录返回 [Left]
  Future<Either<Failure, UserEntity?>> initialize();

  /// 用户登录
  ///
  /// [email] 用户邮箱
  /// [password] 用户密码
  ///
  /// 返回 [Right] 包含认证结果，失败返回 [Left]
  Future<Either<Failure, AuthResult>> login({
    required String email,
    required String password,
  });

  /// 用户注册
  ///
  /// [email] 用户邮箱
  /// [password] 用户密码
  /// [nickname] 用户昵称
  /// [code] 验证码（可选）
  ///
  /// 返回 [Right] 包含认证结果，失败返回 [Left]
  Future<Either<Failure, AuthResult>> register({
    required String email,
    required String password,
    required String nickname,
    String? code,
  });

  /// 发送验证码
  ///
  /// [email] 目标邮箱
  ///
  /// 返回 [Right] 发送成功，失败返回 [Left]
  Future<Either<Failure, void>> sendVerificationCode(String email);

  /// 刷新Token
  ///
  /// [refreshToken] 刷新令牌
  ///
  /// 返回 [Right] 包含新的认证结果，失败返回 [Left]
  Future<Either<Failure, AuthResult>> refreshToken(String refreshToken);

  /// 退出登录
  ///
  /// 返回 [Right] 退出成功，失败返回 [Left]
  Future<Either<Failure, void>> logout();

  /// 获取当前用户
  ///
  /// 返回 [Right] 包含用户信息，未登录返回 [Left]
  Future<Either<Failure, UserEntity>> getCurrentUser();

  /// 检查是否已登录
  ///
  /// 返回 [Right] 包含登录状态，失败返回 [Left]
  Future<Either<Failure, bool>> isLoggedIn();

  /// 修改密码
  ///
  /// [oldPassword] 旧密码
  /// [newPassword] 新密码
  ///
  /// 返回 [Right] 修改成功，失败返回 [Left]
  Future<Either<Failure, void>> changePassword({
    required String oldPassword,
    required String newPassword,
  });

  /// 重置密码
  ///
  /// [email] 用户邮箱
  /// [code] 验证码
  /// [newPassword] 新密码
  ///
  /// 返回 [Right] 重置成功，失败返回 [Left]
  Future<Either<Failure, void>> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  });

  /// 请求注销账号
  ///
  /// [reason] 注销原因
  /// [exportData] 是否导出数据
  ///
  /// 返回 [Right] 请求成功，失败返回 [Left]
  Future<Either<Failure, void>> requestAccountDeletion({
    String? reason,
    bool exportData = false,
  });

  /// 取消注销账号
  ///
  /// 返回 [Right] 取消成功，失败返回 [Left]
  Future<Either<Failure, void>> cancelAccountDeletion();
}
