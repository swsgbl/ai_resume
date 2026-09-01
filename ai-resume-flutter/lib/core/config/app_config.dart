/// 应用配置
///
/// 包含应用的全局配置信息，支持多环境配置
class AppConfig {
  /// 应用名称
  static const String appName = 'AI Resume';

  /// 应用版本
  static const String appVersion = '1.0.0';

  /// 构建号
  static const int buildNumber = 1;

  /// 环境配置（通过编译标志设置）
  static AppEnvironment get environment {
    const env = String.fromEnvironment(
      'APP_ENV',
      defaultValue: 'development',
    );
    return AppEnvironment.values.firstWhere(
      (e) => e.name == env,
      orElse: () => AppEnvironment.development,
    );
  }

  /// 是否为生产环境
  static bool get isProduction => environment == AppEnvironment.production;

  /// 是否启用调试模式（根据环境自动判断）
  static bool get isDebug => !isProduction;

  /// 是否启用日志（根据环境自动判断）
  static bool get enableLogging => isDebug;

  /// 是否启用请求日志（根据环境自动判断）
  static bool get enableRequestLog => isDebug;

  /// API基础URL（根据环境自动选择）
  static String get apiBaseUrl {
    const customUrl = String.fromEnvironment('API_BASE_URL');
    if (customUrl.isNotEmpty) {
      return customUrl;
    }

    switch (environment) {
      case AppEnvironment.development:
        // 开发环境：通过 adb reverse 端口转发访问
        // 使用 127.0.0.1 而不是 localhost 避免某些设备的 DNS 解析问题
        return 'http://127.0.0.1:8000/api';
      case AppEnvironment.staging:
        return 'https://staging-api.airesume.com/api';
      case AppEnvironment.production:
        // 生产环境必须使用HTTPS
        return 'https://api.airesume.com/api';
    }
  }

  /// WebSocket URL（根据环境自动选择）
  static String get wsUrl {
    const customUrl = String.fromEnvironment('WS_BASE_URL');
    if (customUrl.isNotEmpty) {
      return customUrl;
    }

    switch (environment) {
      case AppEnvironment.development:
        return 'ws://localhost:8080/ws';
      case AppEnvironment.staging:
        return 'wss://staging-api.airesume.com/ws';
      case AppEnvironment.production:
        return 'wss://api.airesume.com/ws';
    }
  }

  /// API超时时间（毫秒）
  static const int apiTimeout = 30000;

  /// 图片上传最大大小（字节）
  static const int maxImageSize = 5 * 1024 * 1024; // 5MB

  /// PDF导出质量
  static const int pdfQuality = 100;

  /// 验证码过期时间（秒）
  static const int codeExpireTime = 60;

  /// 验证配置有效性
  static void validate() {
    if (isProduction && apiBaseUrl.contains('localhost')) {
      throw ConfigurationError(
        '生产环境不能使用localhost作为API地址',
      );
    }
    if (isProduction && !apiBaseUrl.startsWith('https://')) {
      throw ConfigurationError(
        '生产环境必须使用HTTPS协议',
      );
    }
  }
}

/// 环境枚举
enum AppEnvironment {
  /// 开发环境
  development,

  /// 测试环境
  staging,

  /// 生产环境
  production,
}

/// 环境扩展方法
extension AppEnvironmentExtension on AppEnvironment {
  String get name {
    switch (this) {
      case AppEnvironment.development:
        return 'Development';
      case AppEnvironment.staging:
        return 'Staging';
      case AppEnvironment.production:
        return 'Production';
    }
  }

  bool get isProduction => this == AppEnvironment.production;
}

/// 配置错误
class ConfigurationError implements Exception {
  final String message;

  ConfigurationError(this.message);

  @override
  String toString() => 'ConfigurationError: $message';
}
