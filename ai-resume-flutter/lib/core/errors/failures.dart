/// Failure类定义
///
/// 在Clean Architecture中，使用Either<Failure, T>来处理错误
/// Left(Failure) 表示失败，Right(T) 表示成功
library;

import 'package:equatable/equatable.dart';

/// Failure基类
abstract class Failure extends Equatable {
  final String message;
  final int? code;

  const Failure(this.message, {this.code});

  @override
  List<Object?> get props => [message, code];
}

// ============ 服务器相关失败 ============

/// 服务器失败
class ServerFailure extends Failure {
  const ServerFailure(super.message, {super.code});

  @override
  String toString() => 'ServerFailure(message: $message, code: $code)';
}

/// 网络失败
class NetworkFailure extends Failure {
  const NetworkFailure(super.message);

  factory NetworkFailure.connectionFailed() {
    return const NetworkFailure('网络连接失败，请检查网络设置');
  }

  factory NetworkFailure.timeout() {
    return const NetworkFailure('请求超时，请稍后重试');
  }

  @override
  String toString() => 'NetworkFailure(message: $message)';
}

// ============ 认证相关失败 ============

/// 认证失败
class AuthFailure extends Failure {
  const AuthFailure(super.message, {super.code});

  factory AuthFailure.invalidCredentials() {
    return const AuthFailure('邮箱或密码错误', code: 10003);
  }

  factory AuthFailure.tokenExpired() {
    return const AuthFailure('登录已过期，请重新登录', code: 10005);
  }

  factory AuthFailure.unauthorized() {
    return const AuthFailure('未授权访问', code: 401);
  }

  factory AuthFailure.userNotFound() {
    return const AuthFailure('用户不存在', code: 10001);
  }

  factory AuthFailure.userAlreadyExists() {
    return const AuthFailure('该邮箱已被注册', code: 10002);
  }

  factory AuthFailure.invalidVerificationCode() {
    return const AuthFailure('验证码错误或已过期', code: 10004);
  }

  @override
  String toString() => 'AuthFailure(message: $message, code: $code)';
}

// ============ 验证相关失败 ============

/// 验证失败
class ValidationFailure extends Failure {
  const ValidationFailure(super.message);

  factory ValidationFailure.invalidEmail() {
    return const ValidationFailure('请输入有效的邮箱地址');
  }

  factory ValidationFailure.invalidPassword() {
    return const ValidationFailure('密码格式不正确');
  }

  factory ValidationFailure.passwordMismatch() {
    return const ValidationFailure('两次输入的密码不一致');
  }

  factory ValidationFailure.invalidNickname() {
    return const ValidationFailure('昵称格式不正确');
  }

  factory ValidationFailure.emptyField(String fieldName) {
    return ValidationFailure('请输入$fieldName');
  }

  @override
  String toString() => 'ValidationFailure(message: $message)';
}

// ============ 业务相关失败 ============

/// 业务失败
class BusinessFailure extends Failure {
  const BusinessFailure(super.message, {super.code});

  factory BusinessFailure.quotaExceeded(String resource) {
    return BusinessFailure('超出$resource使用限额', code: 7004);
  }

  factory BusinessFailure.operationFailed(String operation) {
    return BusinessFailure('$operation失败，请稍后重试', code: 7003);
  }

  factory BusinessFailure.resourceNotFound(String resource) {
    return BusinessFailure('$resource不存在', code: 7001);
  }

  factory BusinessFailure.permissionDenied() {
    return const BusinessFailure('权限不足', code: 7002);
  }

  @override
  String toString() => 'BusinessFailure(message: $message, code: $code)';
}

// ============ 缓存相关失败 ============

/// 缓存失败
class CacheFailure extends Failure {
  const CacheFailure(super.message);

  factory CacheFailure.notFound() {
    return const CacheFailure('缓存数据不存在');
  }

  factory CacheFailure.readError() {
    return const CacheFailure('读取缓存失败');
  }

  factory CacheFailure.writeError() {
    return const CacheFailure('写入缓存失败');
  }

  @override
  String toString() => 'CacheFailure(message: $message)';
}

// ============ 配置相关失败 ============

/// 配置失败
class ConfigurationFailure extends Failure {
  const ConfigurationFailure(super.message);

  factory ConfigurationFailure.missingConfig(String configKey) {
    return ConfigurationFailure('缺少配置: $configKey');
  }

  factory ConfigurationFailure.invalidConfig(String configKey) {
    return ConfigurationFailure('配置无效: $configKey');
  }

  @override
  String toString() => 'ConfigurationFailure(message: $message)';
}

/// 未知失败
class UnknownFailure extends Failure {
  final dynamic originalError;

  const UnknownFailure(super.message, {this.originalError});

  @override
  List<Object?> get props => [message, originalError];

  @override
  String toString() => 'UnknownFailure(message: $message, error: $originalError)';
}
