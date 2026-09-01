import 'package:json_annotation/json_annotation.dart';
import 'user.dart';

part 'auth_models.g.dart';

/// 登录请求
@JsonSerializable()
class LoginRequest {
  final String email;
  final String password;

  LoginRequest({
    required this.email,
    required this.password,
  });

  factory LoginRequest.fromJson(Map<String, dynamic> json) =>
      _$LoginRequestFromJson(json);

  Map<String, dynamic> toJson() => _$LoginRequestToJson(this);
}

/// 登录响应
@JsonSerializable()
class LoginResponse {
  final String token;
  final String refreshToken;
  final User user;

  LoginResponse({
    required this.token,
    required this.refreshToken,
    required this.user,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) =>
      _$LoginResponseFromJson(json);

  Map<String, dynamic> toJson() => _$LoginResponseToJson(this);
}

/// 注册请求
@JsonSerializable()
class RegisterRequest {
  final String email;
  final String password;
  final String nickname;
  final String? code;

  RegisterRequest({
    required this.email,
    required this.password,
    required this.nickname,
    this.code,
  });

  factory RegisterRequest.fromJson(Map<String, dynamic> json) =>
      _$RegisterRequestFromJson(json);

  Map<String, dynamic> toJson() => _$RegisterRequestToJson(this);
}

/// 注册响应
@JsonSerializable()
class RegisterResponse {
  final String token;
  final String refreshToken;
  final User user;

  RegisterResponse({
    required this.token,
    required this.refreshToken,
    required this.user,
  });

  factory RegisterResponse.fromJson(Map<String, dynamic> json) =>
      _$RegisterResponseFromJson(json);

  Map<String, dynamic> toJson() => _$RegisterResponseToJson(this);
}

/// 发送验证码请求
@JsonSerializable()
class SendCodeRequest {
  final String email;

  SendCodeRequest({
    required this.email,
  });

  factory SendCodeRequest.fromJson(Map<String, dynamic> json) =>
      _$SendCodeRequestFromJson(json);

  Map<String, dynamic> toJson() => _$SendCodeRequestToJson(this);
}

/// 验证码响应
@JsonSerializable()
class VerifyCodeResponse {
  final bool success;
  final String? message;

  VerifyCodeResponse({
    required this.success,
    this.message,
  });

  factory VerifyCodeResponse.fromJson(Map<String, dynamic> json) =>
      _$VerifyCodeResponseFromJson(json);

  Map<String, dynamic> toJson() => _$VerifyCodeResponseToJson(this);
}

/// 修改密码请求
@JsonSerializable()
class ChangePasswordRequest {
  final String oldPassword;
  final String newPassword;

  ChangePasswordRequest({
    required this.oldPassword,
    required this.newPassword,
  });

  factory ChangePasswordRequest.fromJson(Map<String, dynamic> json) =>
      _$ChangePasswordRequestFromJson(json);

  Map<String, dynamic> toJson() => _$ChangePasswordRequestToJson(this);
}

/// 重置密码请求
@JsonSerializable()
class ResetPasswordRequest {
  final String email;
  final String code;
  final String newPassword;

  ResetPasswordRequest({
    required this.email,
    required this.code,
    required this.newPassword,
  });

  factory ResetPasswordRequest.fromJson(Map<String, dynamic> json) =>
      _$ResetPasswordRequestFromJson(json);

  Map<String, dynamic> toJson() => _$ResetPasswordRequestToJson(this);
}

/// 账号注销请求
@JsonSerializable()
class AccountDeletionRequest {
  final String? reason;
  final bool exportData;
  final String password;

  AccountDeletionRequest({
    this.reason,
    this.exportData = false,
    required this.password,
  });

  factory AccountDeletionRequest.fromJson(Map<String, dynamic> json) =>
      _$AccountDeletionRequestFromJson(json);

  Map<String, dynamic> toJson() => _$AccountDeletionRequestToJson(this);
}

/// 账号注销响应
@JsonSerializable()
class AccountDeletionResponse {
  final bool success;
  final String? message;
  final int? deletionDays; // 删除倒计时天数

  AccountDeletionResponse({
    required this.success,
    this.message,
    this.deletionDays,
  });

  factory AccountDeletionResponse.fromJson(Map<String, dynamic> json) =>
      _$AccountDeletionResponseFromJson(json);

  Map<String, dynamic> toJson() => _$AccountDeletionResponseToJson(this);
}

/// 数据导出响应
@JsonSerializable()
class DataExportResponse {
  final bool success;
  final String? message;
  final String? exportUrl; // 导出文件下载链接
  final DateTime? expiresAt; // 导出链接过期时间

  DataExportResponse({
    required this.success,
    this.message,
    this.exportUrl,
    this.expiresAt,
  });

  factory DataExportResponse.fromJson(Map<String, dynamic> json) =>
      _$DataExportResponseFromJson(json);

  Map<String, dynamic> toJson() => _$DataExportResponseToJson(this);
}
