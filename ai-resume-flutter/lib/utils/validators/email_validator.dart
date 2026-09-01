import '../../../core/constants/app_constants.dart';

/// 邮箱验证工具
class EmailValidator {
  /// 验证邮箱格式
  ///
  /// 返回: 验证通过返回null，失败返回错误消息
  static String? validate(String? value) {
    if (value == null || value.isEmpty) {
      return '请输入邮箱地址';
    }

    if (!RegExp(RegexConstants.email).hasMatch(value)) {
      return '请输入有效的邮箱地址';
    }

    return null;
  }

  /// 检查邮箱格式是否有效
  static bool isValid(String email) {
    return validate(email) == null;
  }

  /// 从邮箱中提取域名
  static String? extractDomain(String email) {
    if (!isValid(email)) return null;
    return email.split('@')[1];
  }

  /// 常见邮箱提供商
  static const List<String> commonProviders = [
    'qq.com',
    '163.com',
    '126.com',
    'gmail.com',
    'outlook.com',
    'hotmail.com',
    'yahoo.com',
    'sina.com',
    'foxmail.com',
  ];

  /// 检查是否为常见邮箱提供商
  static bool isCommonProvider(String email) {
    final domain = extractDomain(email);
    return domain != null && commonProviders.contains(domain);
  }

  /// 标准化邮箱（转为小写）
  static String normalize(String email) {
    return email.toLowerCase().trim();
  }
}
