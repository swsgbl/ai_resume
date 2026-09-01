import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/storage_constants.dart';
import '../../../core/storage/storage_service.dart';
import '../datasources/remote/auth_api.dart';
import '../models/auth_models.dart';
import '../models/user.dart';

/// 认证仓库
///
/// 处理认证相关的业务逻辑
class AuthRepository {
  final AuthApi _authApi = AuthApi();
  final StorageService _storage = StorageService();

  AuthRepository();

  /// 初始化仓库
  Future<void> initialize() async {
    await _storage.initialize();
    _authApi.initialize();
  }

  /// 用户登录
  Future<User> login({
    required String email,
    required String password,
  }) async {
    final request = LoginRequest(
      email: email,
      password: password,
    );

    final response = await _authApi.login(request);

    // 保存Token到安全存储（加密）
    await _storage.setSecureString(
      StorageConstants.keyAccessToken,
      response.token,
    );
    await _storage.setSecureString(
      StorageConstants.keyRefreshToken,
      response.refreshToken,
    );

    // 保存用户信息
    await _saveUserInfo(response.user);

    return response.user;
  }

  /// 用户注册
  Future<User> register({
    required String email,
    required String password,
    required String nickname,
    String? code,
  }) async {
    final request = RegisterRequest(
      email: email,
      password: password,
      nickname: nickname,
      code: code,
    );

    final response = await _authApi.register(request);

    // 保存Token到安全存储（加密）
    await _storage.setSecureString(
      StorageConstants.keyAccessToken,
      response.token,
    );
    await _storage.setSecureString(
      StorageConstants.keyRefreshToken,
      response.refreshToken,
    );

    // 保存用户信息
    await _saveUserInfo(response.user);

    return response.user;
  }

  /// 发送验证码
  Future<void> sendVerificationCode(String email) async {
    final request = SendCodeRequest(email: email);
    await _authApi.sendVerificationCode(request);
  }

  /// 检查登录状态
  Future<bool> isLoggedIn() async {
    final token = await _storage.getSecureString(
      StorageConstants.keyAccessToken,
    );
    return token != null && token.isNotEmpty;
  }

  /// 获取当前用户
  Future<User?> getCurrentUser() async {
    try {
      final response = await _authApi.getCurrentUser();
      return User.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  /// 登出
  Future<void> logout() async {
    try {
      // 通知服务器登出
      await _authApi.logout();
    } finally {
      // 无论服务器请求是否成功，都清除本地存储
      await _storage.clear();
    }
  }

  /// 修改密码
  ///
  /// [oldPassword] 旧密码
  /// [newPassword] 新密码
  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    final request = ChangePasswordRequest(
      oldPassword: oldPassword,
      newPassword: newPassword,
    );
    await _authApi.changePassword(request);
  }

  /// 重置密码
  ///
  /// [email] 用户邮箱
  /// [code] 验证码
  /// [newPassword] 新密码
  Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    final request = ResetPasswordRequest(
      email: email,
      code: code,
      newPassword: newPassword,
    );
    await _authApi.resetPassword(request);
  }

  /// 请求注销账号
  ///
  /// 根据GDPR和个人信息保护法，用户有权要求删除其个人数据
  ///
  /// [reason] 注销原因（可选）
  /// [exportData] 是否需要导出数据
  /// [password] 用户密码（用于身份验证）
  ///
  /// 返回注销响应，包含删除倒计时天数
  Future<AccountDeletionResponse> requestAccountDeletion({
    String? reason,
    bool exportData = false,
    required String password,
  }) async {
    final request = AccountDeletionRequest(
      reason: reason,
      exportData: exportData,
      password: password,
    );
    return await _authApi.requestAccountDeletion(request);
  }

  /// 取消注销请求
  ///
  /// 在30天宽限期内可以取消注销
  Future<void> cancelAccountDeletion() async {
    await _authApi.cancelAccountDeletion();
  }

  /// 请求导出个人数据
  ///
  /// 用户可以在注销前请求导出所有个人数据
  /// 后端会生成数据包并发送到用户邮箱
  ///
  /// 返回导出响应，包含下载链接和过期时间
  Future<DataExportResponse> exportAccountData() async {
    return await _authApi.exportAccountData();
  }

  /// 保存用户信息到本地
  Future<void> _saveUserInfo(User user) async {
    await _storage.setString(StorageConstants.keyUserId, user.id);
    await _storage.setString(StorageConstants.keyUserEmail, user.email);
    if (user.nickname != null) {
      await _storage.setString(
        StorageConstants.keyUserNickname,
        user.nickname!,
      );
    }
  }

  /// 获取本地存储的用户ID
  Future<String?> getUserId() async {
    return await _storage.getString(StorageConstants.keyUserId);
  }
}

/// 认证仓库Provider
///
/// 提供AuthRepository实例
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final repository = AuthRepository();
  // 这里可以添加初始化逻辑
  return repository;
});
