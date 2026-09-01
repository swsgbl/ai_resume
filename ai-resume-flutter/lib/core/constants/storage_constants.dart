/// 存储常量
///
/// 定义所有本地存储相关的key常量
class StorageConstants {
  StorageConstants._();

  // ============ SharedPreferences Keys ============

  /// 是否已登录
  static const String keyIsLoggedIn = 'is_logged_in';

  /// 用户访问Token
  static const String keyAccessToken = 'access_token';

  /// 用户刷新Token
  static const String keyRefreshToken = 'refresh_token';

  /// 用户ID
  static const String keyUserId = 'user_id';

  /// 用户邮箱
  static const String keyUserEmail = 'user_email';

  /// 用户昵称
  static const String keyUserNickname = 'user_nickname';

  /// API配置
  static const String keyApiConfig = 'api_config';

  /// 主题模式 (light/dark)
  static const String keyThemeMode = 'theme_mode';

  /// 语言设置
  static const String keyLanguage = 'language';

  // ============ Hive Box Names ============

  /// 用户数据Box
  static const String boxUser = 'user_box';

  /// 简历数据Box
  static const String boxResumes = 'resumes_box';

  /// 模板数据Box
  static const String boxTemplates = 'templates_box';

  /// 缓存数据Box
  static const String boxCache = 'cache_box';

  // ============ Hive Keys (within boxes) ============

  /// 当前用户信息
  static const String keyCurrentUser = 'current_user';

  /// 简历列表
  static const String keyResumeList = 'resume_list';

  /// 草稿数据
  static const String keyDraftData = 'draft_data';

  /// 最近使用的模板
  static const String keyRecentTemplates = 'recent_templates';

  // ============ 记住密码相关 ============

  /// 是否记住密码
  static const String keyRememberPassword = 'remember_password';

  /// 记住的邮箱
  static const String keySavedEmail = 'saved_email';

  /// 记住的密码（安全存储）
  static const String keySavedPassword = 'saved_password';
}

/// 存储过期时间常量
class StorageExpiration {
  StorageExpiration._();

  /// Token过期时间（秒）
  static const int tokenExpireSeconds = 7200; // 2小时

  /// 缓存过期时间（秒）
  static const int cacheExpireSeconds = 3600; // 1小时

  /// 验证码过期时间（秒）
  static const int codeExpireSeconds = 300; // 5分钟
}
