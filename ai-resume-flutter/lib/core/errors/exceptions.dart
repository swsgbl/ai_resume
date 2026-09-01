/// 应用异常体系
///
/// 定义应用中所有自定义异常类型，实现统一的错误处理
library;

/// 应用异常基类
///
/// 所有应用异常都应该继承此类
class AppException implements Exception {
  /// 错误消息
  final String message;

  /// 错误代码
  final int? code;

  /// 原始错误
  final dynamic originalError;

  /// 堆栈跟踪
  final StackTrace? stackTrace;

  const AppException(
    this.message, {
    this.code,
    this.originalError,
    this.stackTrace,
  });

  @override
  String toString() => 'AppException: $message${code != null ? ' (code: $code)' : ''}';
}

/// 网络异常
///
/// 当网络请求失败时抛出
class NetworkException extends AppException {
  const NetworkException(
    super.message, {
    super.code,
    super.originalError,
    super.stackTrace,
  });

  factory NetworkException.connectionFailed({dynamic originalError}) {
    return NetworkException(
      '网络连接失败，请检查网络设置',
      code: -1001,
      originalError: originalError,
    );
  }

  factory NetworkException.timeout({dynamic originalError}) {
    return NetworkException(
      '网络请求超时，请稍后重试',
      code: -1002,
      originalError: originalError,
    );
  }

  factory NetworkException.serverUnreachable({dynamic originalError}) {
    return NetworkException(
      '无法连接到服务器，请稍后重试',
      code: -1003,
      originalError: originalError,
    );
  }
}

/// 认证异常
///
/// 当用户认证失败时抛出
class AuthException extends AppException {
  const AuthException(
    super.message, {
    super.code,
    super.originalError,
    super.stackTrace,
  });

  factory AuthException.invalidCredentials() {
    return const AuthException(
      '用户名或密码错误',
      code: 2001,
    );
  }

  factory AuthException.userNotFound() {
    return const AuthException(
      '用户不存在',
      code: 2002,
    );
  }

  factory AuthException.userAlreadyExists() {
    return const AuthException(
      '该邮箱已被注册',
      code: 2003,
    );
  }

  factory AuthException.invalidVerificationCode() {
    return const AuthException(
      '验证码错误或已过期',
      code: 2004,
    );

  }

  factory AuthException.tokenExpired() {
    return const AuthException(
      '登录已过期，请重新登录',
      code: 2005,
    );
  }

  factory AuthException.unauthorized() {
    return const AuthException(
      '您没有权限执行此操作',
      code: 2006,
    );
  }

  factory AuthException.notLoggedIn() {
    return const AuthException(
      '请先登录',
      code: 2007,
    );
  }
}

/// 服务器异常
///
/// 当服务器返回错误时抛出
class ServerException extends AppException {
  const ServerException(
    super.message, {
    super.code,
    super.originalError,
    super.stackTrace,
  });

  factory ServerException.internalError({int? code}) {
    return ServerException(
      '服务器内部错误，请稍后重试',
      code: code ?? 5000,
    );
  }

  factory ServerException.badRequest(String message) {
    return ServerException(
      message,
      code: 4000,
    );
  }

  factory ServerException.notFound(String resource) {
    return ServerException(
      '请求的资源不存在: $resource',
      code: 4004,
    );
  }

  factory ServerException.serviceUnavailable() {
    return const ServerException(
      '服务暂时不可用，请稍后重试',
      code: 5003,
    );
  }
}

/// 验证异常
///
/// 当输入验证失败时抛出
class ValidationException extends AppException {
  const ValidationException(
    super.message, {
    super.code,
    super.originalError,
    super.stackTrace,
  });

  factory ValidationException.invalidEmail() {
    return const ValidationException(
      '请输入有效的邮箱地址',
      code: 3001,
    );
  }

  factory ValidationException.invalidPassword() {
    return const ValidationException(
      '密码必须至少8位，包含大小写字母和数字',
      code: 3002,
    );
  }

  factory ValidationException.passwordMismatch() {
    return const ValidationException(
      '两次输入的密码不一致',
      code: 3003,
    );
  }

  factory ValidationException.invalidPhone() {
    return const ValidationException(
      '请输入有效的手机号码',
      code: 3004,
    );
  }

  factory ValidationException.requiredField(String fieldName) {
    return ValidationException(
      '$fieldName不能为空',
      code: 3000,
    );
  }

  factory ValidationException.tooLong(String fieldName, int maxLength) {
    return ValidationException(
      '$fieldName不能超过$maxLength个字符',
      code: 3005,
    );
  }
}

/// 配置异常
///
/// 当配置错误时抛出
class ConfigurationException extends AppException {
  const ConfigurationException(
    super.message, {
    super.code,
    super.originalError,
    super.stackTrace,
  });

  @override
  String toString() => 'ConfigurationError: $message';
}

/// 存储异常
///
/// 当本地存储操作失败时抛出
class StorageException extends AppException {
  const StorageException(
    super.message, {
    super.code,
    super.originalError,
    super.stackTrace,
  });

  factory StorageException.readFailed(String key) {
    return StorageException(
      '读取数据失败: $key',
      code: 5001,
    );
  }

  factory StorageException.writeFailed(String key) {
    return StorageException(
      '保存数据失败: $key',
      code: 5002,
    );

  }

  factory StorageException.deleteFailed(String key) {
    return StorageException(
      '删除数据失败: $key',
      code: 5003,
    );
  }
}

/// 权限异常
///
/// 当缺少必要权限时抛出
class PermissionException extends AppException {
  const PermissionException(
    super.message, {
    super.code,
    super.originalError,
    super.stackTrace,
  });

  factory PermissionException.denied(String permission) {
    return PermissionException(
      '需要$permission权限才能使用此功能',
      code: 6001,
    );
  }

  factory PermissionException.permanentlyDenied(String permission) {
    return PermissionException(
      '您已永久拒绝$permission权限，请在设置中开启',
      code: 6002,
    );
  }
}

/// 业务逻辑异常
///
/// 当业务逻辑执行失败时抛出
class BusinessException extends AppException {
  const BusinessException(
    super.message, {
    super.code,
    super.originalError,
    super.stackTrace,
  });

  factory BusinessException.resourceAlreadyExists(String resource) {
    return BusinessException(
      '$resource已存在',
      code: 7001,
    );
  }

  factory BusinessException.resourceNotFound(String resource) {
    return BusinessException(
      '$resource不存在',
      code: 7002,
    );
  }

  factory BusinessException.operationFailed(String operation) {
    return BusinessException(
      '$operation失败，请稍后重试',
      code: 7003,
    );
  }

  factory BusinessException.quotaExceeded(String resource) {
    return BusinessException(
      '超出$resource使用限额',
      code: 7004,
    );
  }
}

/// 异常工具类
///
/// 提供异常处理工具方法
class ExceptionHelper {
  /// 将通用异常转换为AppException
  static AppException from(dynamic error) {
    if (error is AppException) {
      return error;
    }

    if (error.toString().contains('SocketException') ||
        error.toString().contains('Connection failed')) {
      return NetworkException.connectionFailed(originalError: error);
    }

    if (error.toString().contains('TimeoutException')) {
      return NetworkException.timeout(originalError: error);
    }

    // 默认返回服务器异常
    return ServerException(
      '发生未知错误',
      code: 9999,
      originalError: error,
    );
  }

  /// 获取用户友好的错误消息
  static String getUserMessage(dynamic error) {
    if (error is AppException) {
      return error.message;
    }

    final appException = from(error);
    return appException.message;
  }

  /// 是否为网络错误
  static bool isNetworkError(dynamic error) {
    return error is NetworkException || from(error) is NetworkException;
  }

  /// 是否为认证错误
  static bool isAuthError(dynamic error) {
    return error is AuthException || from(error) is AuthException;
  }

  /// 是否为验证错误
  static bool isValidationError(dynamic error) {
    return error is ValidationException || from(error) is ValidationException;
  }
}
