import '../../../core/constants/app_constants.dart';
import '../../../core/errors/exceptions.dart';

/// 密码强度验证工具
///
/// 提供密码强度验证和评分功能
class PasswordValidator {
  /// 验证密码是否符合基本要求
  ///
  /// 返回: 验证通过返回null，失败返回错误消息
  static String? validate(String? password) {
    if (password == null || password.isEmpty) {
      return '请输入密码';
    }

    if (password.length < ValidationConstants.minPasswordLength) {
      return '密码至少${ValidationConstants.minPasswordLength}位';
    }

    if (password.length > ValidationConstants.maxPasswordLength) {
      return '密码最多${ValidationConstants.maxPasswordLength}位';
    }

    // 基础验证：包含字母和数字
    if (!RegExp(r'[A-Za-z]').hasMatch(password)) {
      return '密码必须包含字母';
    }

    if (!RegExp(r'\d').hasMatch(password)) {
      return '密码必须包含数字';
    }

    return null;
  }

  /// 验证密码强度（严格模式）
  ///
  /// 返回: 验证通过返回null，失败返回错误消息
  static String? validateStrong(String? password) {
    if (password == null || password.isEmpty) {
      return '请输入密码';
    }

    if (password.length < ValidationConstants.minPasswordLength) {
      return '密码至少${ValidationConstants.minPasswordLength}位';
    }

    // 检查是否包含小写字母
    if (!RegExp(r'[a-z]').hasMatch(password)) {
      return '密码必须包含至少一个小写字母';
    }

    // 检查是否包含大写字母
    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      return '密码必须包含至少一个大写字母';
    }

    // 检查是否包含数字
    if (!RegExp(r'\d').hasMatch(password)) {
      return '密码必须包含至少一个数字';
    }

    // 检查是否包含特殊字符
    if (!RegExp(r'[@\$!%*?&]').hasMatch(password)) {
      return '密码必须包含至少一个特殊字符(@\$!%*?&)';
    }

    return null;
  }

  /// 计算密码强度分数
  ///
  /// 返回: 0-5的分数，5表示最强
  static int calculateStrength(String password) {
    if (password.isEmpty) return 0;

    int score = 0;

    // 长度评分 (最多2分)
    if (password.length >= 8) score += 1;
    if (password.length >= 12) score += 1;

    // 包含小写字母 (1分)
    if (RegExp(r'[a-z]').hasMatch(password)) score += 1;

    // 包含大写字母 (1分)
    if (RegExp(r'[A-Z]').hasMatch(password)) score += 1;

    // 包含数字 (1分)
    if (RegExp(r'\d').hasMatch(password)) score += 1;

    // 包含特殊字符 (1分)
    if (RegExp(r'[@\$!%*?&]').hasMatch(password)) score += 1;

    // 多样性加分 (最多5分)
    int variety = 0;
    if (RegExp(r'[a-z]').hasMatch(password)) variety++;
    if (RegExp(r'[A-Z]').hasMatch(password)) variety++;
    if (RegExp(r'\d').hasMatch(password)) variety++;
    if (RegExp(r'[@\$!%*?&]').hasMatch(password)) variety++;

    if (variety >= 3 && score < 5) {
      score += 1;
    }

    return score > 5 ? 5 : score;
  }

  /// 获取密码强度描述
  static String getStrengthLabel(String password) {
    final strength = calculateStrength(password);

    switch (strength) {
      case 0:
      case 1:
        return '弱';
      case 2:
        return '较弱';
      case 3:
        return '中等';
      case 4:
        return '强';
      case 5:
        return '很强';
      default:
        return '未知';
    }
  }

  /// 获取密码强度颜色
  static String getStrengthColor(String password) {
    final strength = calculateStrength(password);

    switch (strength) {
      case 0:
      case 1:
        return '#FF4444'; // 红色
      case 2:
        return '#FF8800'; // 橙色
      case 3:
        return '#FFCC00'; // 黄色
      case 4:
        return '#88CC00'; // 浅绿
      case 5:
        return '#00CC66'; // 绿色
      default:
        return '#CCCCCC'; // 灰色
    }
  }

  /// 检查密码是否为弱密码
  static bool isWeakPassword(String password) {
    return calculateStrength(password) <= 2;
  }

  /// 检查密码是否为强密码
  static bool isStrongPassword(String password) {
    return calculateStrength(password) >= 4;
  }

  /// 常见弱密码列表
  static const List<String> commonWeakPasswords = [
    'password',
    '12345678',
    '123456789',
    'qwerty',
    'abc123',
    'password123',
    'admin123',
    '11111111',
    '123123123',
    '12344321',
  ];

  /// 检查是否为常见弱密码
  static bool isCommonWeakPassword(String password) {
    return commonWeakPasswords.contains(password.toLowerCase());
  }

  /// 完整的密码验证（包含所有检查）
  ///
  /// 抛出: ValidationException 如果密码不符合要求
  static void validateOrThrow(String? password) {
    final error = validateStrong(password);
    if (error != null) {
      throw ValidationException(error);
    }

    if (isCommonWeakPassword(password!)) {
      throw const ValidationException(
        '该密码过于常见，请使用更复杂的密码',
      );
    }
  }
}
