/// 应用常量
///
/// 定义应用中使用的各种常量
class AppConstants {
  AppConstants._();

  // ============ 应用信息 ============

  /// 应用名称
  static const String appName = 'AI Resume';

  /// 应用包名（Android）
  static const String packageName = 'com.airesume.app';

  /// 应用ID（iOS）
  static const String appId = 'com.airesume.app';

  // ============ 业务常量 ============

  /// 简历状态 - 草稿
  static const int resumeStatusDraft = 0;

  /// 简历状态 - 已发布
  static const int resumeStatusPublished = 1;

  /// 简历状态 - 已归档
  static const int resumeStatusArchived = 2;

  /// 用户角色 - 普通用户
  static const String roleUser = 'user';

  /// 用户角色 - VIP用户
  static const String roleVip = 'vip';

  /// 用户角色 - 管理员
  static const String roleAdmin = 'admin';

  // ============ UI常量 ============

  /// 默认页面边距
  static const double paddingDefault = 16.0;

  /// 小边距
  static const double paddingSmall = 8.0;

  /// 大边距
  static const double paddingLarge = 24.0;

  /// 默认圆角
  static const double radiusDefault = 12.0;

  /// 小圆角
  static const double radiusSmall = 8.0;

  /// 大圆角
  static const double radiusLarge = 16.0;

  /// 默认动画时长
  static const int animationDurationDefault = 300;

  /// 快速动画时长
  static const int animationDurationFast = 150;

  /// 慢速动画时长
  static const int animationDurationSlow = 500;

  // ============ 分页常量 ============

  /// 默认每页数量
  static const int pageSize = 20;

  /// 最大每页数量
  static const int maxPageSize = 100;

  // ============ 文件相关 ============

  /// 支持的图片格式
  static const List<String> supportedImageFormats = [
    'jpg',
    'jpeg',
    'png',
    'gif',
    'webp',
  ];

  /// 最大图片大小（字节）5MB
  static const int maxImageSize = 5 * 1024 * 1024;

  /// 最大简历导出数量
  static const int maxExportCount = 10;
}

/// 正则表达式常量
class RegexConstants {
  RegexConstants._();

  /// 邮箱正则
  static const String email =
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';

  /// 手机号正则（中国大陆）
  static const String phone = r'^1[3-9]\d{9}$';

  /// 密码正则（至少8位，包含大小写字母和数字）
  static const String passwordStrong = r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)[a-zA-Z\d@$!%*?&]{8,}$';

  /// 密码正则（至少8位，包含字母和数字）- 基础版
  static const String passwordBasic = r'^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d@$!%*#?&]{8,}$';

  /// 用户名正则（4-20位字母数字下划线）
  static const String username = r'^[a-zA-Z0-9_]{4,20}$';

  /// 昵称正则（2-20位，支持中文）
  static const String nickname = r'^[\u4e00-\u9fa5a-zA-Z0-9_]{2,20}$';

  /// 验证码正则（6位数字）
  static const String verifyCode = r'^\d{6}$';

  /// URL正则
  static const String url = r'^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)$';

  /// 身份证号正则（中国大陆）
  static const String idCard = r'^[1-9]\d{5}(18|19|20)\d{2}((0[1-9])|(1[0-2]))(([0-2][1-9])|10|20|30|31)\d{3}[0-9Xx]$';
}

/// 验证常量
class ValidationConstants {
  ValidationConstants._();

  // 密码相关
  static const int minPasswordLength = 8;
  static const int maxPasswordLength = 128;

  // 昵称相关
  static const int minNicknameLength = 2;
  static const int maxNicknameLength = 20;

  // 验证码相关
  static const int verificationCodeLength = 6;
  static const int verificationCodeExpireSeconds = 60;
  static const int countdownSeconds = 60;

  // 简历相关
  static const int maxResumeTitleLength = 50;
  static const int maxSummaryLength = 500;
}

/// 年龄相关常量
class AgeConstants {
  AgeConstants._();

  /// 最低注册年龄
  static const int minimumAge = 18;

  /// 推荐年龄
  static const int recommendedAge = 16;
}

/// 网络常量
class NetworkConstants {
  NetworkConstants._();

  /// 连接超时（毫秒）
  static const int connectTimeoutMs = 30000;

  /// 接收超时（毫秒）
  static const int receiveTimeoutMs = 30000;

  /// 发送超时（毫秒）
  static const int sendTimeoutMs = 30000;

  /// 最大重试次数
  static const int maxRetryCount = 3;
}

/// 响应式断点
class Breakpoints {
  Breakpoints._();

  /// 移动端最大宽度
  static const double mobile = 768;

  /// 平板端最大宽度
  static const double tablet = 1024;

  /// 桌面端最小宽度
  static const double desktop = 1024;

  /// 大屏幕最小宽度
  static const double largeDesktop = 1440;
}

/// API错误代码
class ApiErrorCodes {
  ApiErrorCodes._();

  /// 成功
  static const int success = 0;
  static const int successHttp = 200;

  /// 客户端错误
  static const int badRequest = 400;
  static const int unauthorized = 401;
  static const int forbidden = 403;
  static const int notFound = 404;

  /// 服务器错误
  static const int internalServerError = 500;
  static const int serviceUnavailable = 503;

  /// 业务错误码
  static const int userNotFound = 10001;
  static const int userAlreadyExists = 10002;
  static const int invalidCredentials = 10003;
  static const int invalidVerificationCode = 10004;
  static const int tokenExpired = 10005;
}
