import 'app_config.dart';

/// API配置
///
/// 包含所有API相关的配置信息，根据环境自动调整
class ApiConfig {
  /// 基础API URL（从AppConfig获取）
  static String get baseUrl => AppConfig.apiBaseUrl;

  /// WebSocket URL（从AppConfig获取）
  static String get wsUrl => AppConfig.wsUrl;

  /// 连接超时时间（毫秒）
  static const Duration connectTimeout = Duration(milliseconds: 30000);

  /// 接收超时时间（毫秒）
  static const Duration receiveTimeout = Duration(milliseconds: 30000);

  /// 发送超时时间（毫秒）
  static const Duration sendTimeout = Duration(milliseconds: 30000);

  /// API端点
  static const Endpoints endpoints = Endpoints();

  /// 是否启用请求日志（仅开发环境）
  static bool get enableRequestLog => AppConfig.isDebug;

  /// 是否启用响应日志（仅开发环境）
  static bool get enableResponseLog => AppConfig.isDebug;

  /// 是否启用详细日志（包含敏感数据，仅开发环境）
  static bool get enableVerboseLog => AppConfig.isDebug;

  /// 是否启用错误日志
  static bool get enableErrorLog => true;
}

/// API端点
class Endpoints {
  const Endpoints();

  /// 认证相关
  String get auth => '/auth';
  String get login => '/auth/login';
  String get register => '/auth/register';
  String get logout => '/auth/logout';
  String get refreshToken => '/auth/refresh';
  String get sendCode => '/auth/send-verification-code';
  String get verifyCode => '/auth/verify-code';
  String get currentUser => '/auth/me';
  String get changePassword => '/auth/change-password';
  String get resetPassword => '/auth/reset-password';

  /// 账号注销相关
  String get accountDeletion => '/auth/account/deletion-request';
  String get cancelAccountDeletion => '/auth/account/cancel-deletion';
  String get accountDataExport => '/auth/account/export';

  /// 简历相关
  String get resumes => '/resumes';
  String resumeDetail(String id) => '/resumes/$id';
  String get aiGenerate => '/resumes/ai-generate';
  String get aiOptimize => '/resumes/ai-optimize';

  /// 模板相关
  String get templates => '/templates';
  String templateDetail(String id) => '/templates/$id';
  String get categories => '/templates/categories';

  /// 用户相关
  String get profile => '/profile';
  String get upload => '/upload';
}

/// API错误码
class ApiErrorCode {
  /// 成功
  static const int success = 200;

  /// 未授权
  static const int unauthorized = 401;

  /// 禁止访问
  static const int forbidden = 403;

  /// 资源不存在
  static const int notFound = 404;

  /// 请求错误
  static const int badRequest = 400;

  /// 服务器错误
  static const int serverError = 500;

  /// 网络错误
  static const int networkError = -1;

  /// 超时
  static const int timeout = -2;

  /// 未知错误
  static const int unknown = -999;
}
