import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/config/api_config.dart';
import '../../models/auth_models.dart';

/// 认证API
///
/// 处理所有认证相关的网络请求
class AuthApi {
  final ApiClient _apiClient = ApiClient();

  AuthApi();

  /// 初始化API客户端
  void initialize() {
    _apiClient.initialize();
  }

  /// 用户登录
  Future<LoginResponse> login(LoginRequest request) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        ApiConfig.endpoints.login,
        data: request.toJson(),
      );
      return LoginResponse.fromJson(response);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// 用户注册
  Future<RegisterResponse> register(RegisterRequest request) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        ApiConfig.endpoints.register,
        data: request.toJson(),
      );
      return RegisterResponse.fromJson(response);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// 发送验证码
  Future<VerifyCodeResponse> sendVerificationCode(
    SendCodeRequest request) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        ApiConfig.endpoints.sendCode,
        data: request.toJson(),
      );
      return VerifyCodeResponse.fromJson(response);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// 获取当前用户信息
  Future<dynamic> getCurrentUser() async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        ApiConfig.endpoints.currentUser,
      );
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// 登出
  Future<void> logout() async {
    try {
      await _apiClient.post(ApiConfig.endpoints.logout);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// 刷新Token
  Future<String> refreshToken(String refreshToken) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        ApiConfig.endpoints.refreshToken,
        data: {'refreshToken': refreshToken},
      );
      return response['accessToken'] as String;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// 修改密码
  Future<void> changePassword(ChangePasswordRequest request) async {
    try {
      await _apiClient.post<Map<String, dynamic>>(
        ApiConfig.endpoints.changePassword,
        data: request.toJson(),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// 重置密码
  Future<void> resetPassword(ResetPasswordRequest request) async {
    try {
      await _apiClient.post<Map<String, dynamic>>(
        ApiConfig.endpoints.resetPassword,
        data: request.toJson(),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// 请求注销账号
  ///
  /// 发起账号注销请求，后端会：
  /// 1. 发送确认邮件到用户邮箱
  /// 2. 记录注销请求原因
  /// 3. 设置30天删除倒计时
  Future<AccountDeletionResponse> requestAccountDeletion(
    AccountDeletionRequest request,
  ) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        ApiConfig.endpoints.accountDeletion,
        data: request.toJson(),
      );
      return AccountDeletionResponse.fromJson(response);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// 取消注销请求
  ///
  /// 在30天宽限期内可以取消注销
  Future<void> cancelAccountDeletion() async {
    try {
      await _apiClient.post<Map<String, dynamic>>(
        ApiConfig.endpoints.cancelAccountDeletion,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// 请求导出个人数据
  ///
  /// 用户在注销前可以请求导出所有个人数据
  /// 后端会生成数据包并发送到用户邮箱
  Future<DataExportResponse> exportAccountData() async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        ApiConfig.endpoints.accountDataExport,
      );
      return DataExportResponse.fromJson(response);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// 处理API错误
  Exception _handleError(DioException error) {
    String message;

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        message = '网络连接超时';
        break;
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final responseData = error.response?.data;

        if (responseData is Map<String, dynamic>) {
          message = responseData['message'] ?? '请求失败';
        } else {
          message = '请求失败: $statusCode';
        }
        break;
      case DioExceptionType.cancel:
        message = '请求已取消';
        break;
      case DioExceptionType.connectionError:
        message = '网络连接失败';
        break;
      default:
        message = '发生未知错误';
    }

    return Exception(message);
  }
}
