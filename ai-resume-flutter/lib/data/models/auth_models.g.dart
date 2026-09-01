// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LoginRequest _$LoginRequestFromJson(Map<String, dynamic> json) => LoginRequest(
  email: json['email'] as String,
  password: json['password'] as String,
);

Map<String, dynamic> _$LoginRequestToJson(LoginRequest instance) =>
    <String, dynamic>{'email': instance.email, 'password': instance.password};

LoginResponse _$LoginResponseFromJson(Map<String, dynamic> json) =>
    LoginResponse(
      token: json['token'] as String,
      refreshToken: json['refreshToken'] as String,
      user: User.fromJson(json['user'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$LoginResponseToJson(LoginResponse instance) =>
    <String, dynamic>{
      'token': instance.token,
      'refreshToken': instance.refreshToken,
      'user': instance.user,
    };

RegisterRequest _$RegisterRequestFromJson(Map<String, dynamic> json) =>
    RegisterRequest(
      email: json['email'] as String,
      password: json['password'] as String,
      nickname: json['nickname'] as String,
      code: json['code'] as String?,
    );

Map<String, dynamic> _$RegisterRequestToJson(RegisterRequest instance) =>
    <String, dynamic>{
      'email': instance.email,
      'password': instance.password,
      'nickname': instance.nickname,
      'code': instance.code,
    };

RegisterResponse _$RegisterResponseFromJson(Map<String, dynamic> json) =>
    RegisterResponse(
      token: json['token'] as String,
      refreshToken: json['refreshToken'] as String,
      user: User.fromJson(json['user'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$RegisterResponseToJson(RegisterResponse instance) =>
    <String, dynamic>{
      'token': instance.token,
      'refreshToken': instance.refreshToken,
      'user': instance.user,
    };

SendCodeRequest _$SendCodeRequestFromJson(Map<String, dynamic> json) =>
    SendCodeRequest(email: json['email'] as String);

Map<String, dynamic> _$SendCodeRequestToJson(SendCodeRequest instance) =>
    <String, dynamic>{'email': instance.email};

VerifyCodeResponse _$VerifyCodeResponseFromJson(Map<String, dynamic> json) =>
    VerifyCodeResponse(
      success: json['success'] as bool,
      message: json['message'] as String?,
    );

Map<String, dynamic> _$VerifyCodeResponseToJson(VerifyCodeResponse instance) =>
    <String, dynamic>{'success': instance.success, 'message': instance.message};

ChangePasswordRequest _$ChangePasswordRequestFromJson(
  Map<String, dynamic> json,
) => ChangePasswordRequest(
  oldPassword: json['oldPassword'] as String,
  newPassword: json['newPassword'] as String,
);

Map<String, dynamic> _$ChangePasswordRequestToJson(
  ChangePasswordRequest instance,
) => <String, dynamic>{
  'oldPassword': instance.oldPassword,
  'newPassword': instance.newPassword,
};

ResetPasswordRequest _$ResetPasswordRequestFromJson(
  Map<String, dynamic> json,
) => ResetPasswordRequest(
  email: json['email'] as String,
  code: json['code'] as String,
  newPassword: json['newPassword'] as String,
);

Map<String, dynamic> _$ResetPasswordRequestToJson(
  ResetPasswordRequest instance,
) => <String, dynamic>{
  'email': instance.email,
  'code': instance.code,
  'newPassword': instance.newPassword,
};

AccountDeletionRequest _$AccountDeletionRequestFromJson(
  Map<String, dynamic> json,
) => AccountDeletionRequest(
  reason: json['reason'] as String?,
  exportData: json['exportData'] as bool? ?? false,
  password: json['password'] as String,
);

Map<String, dynamic> _$AccountDeletionRequestToJson(
  AccountDeletionRequest instance,
) => <String, dynamic>{
  'reason': instance.reason,
  'exportData': instance.exportData,
  'password': instance.password,
};

AccountDeletionResponse _$AccountDeletionResponseFromJson(
  Map<String, dynamic> json,
) => AccountDeletionResponse(
  success: json['success'] as bool,
  message: json['message'] as String?,
  deletionDays: (json['deletionDays'] as num?)?.toInt(),
);

Map<String, dynamic> _$AccountDeletionResponseToJson(
  AccountDeletionResponse instance,
) => <String, dynamic>{
  'success': instance.success,
  'message': instance.message,
  'deletionDays': instance.deletionDays,
};

DataExportResponse _$DataExportResponseFromJson(Map<String, dynamic> json) =>
    DataExportResponse(
      success: json['success'] as bool,
      message: json['message'] as String?,
      exportUrl: json['exportUrl'] as String?,
      expiresAt: json['expiresAt'] == null
          ? null
          : DateTime.parse(json['expiresAt'] as String),
    );

Map<String, dynamic> _$DataExportResponseToJson(DataExportResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
      'exportUrl': instance.exportUrl,
      'expiresAt': instance.expiresAt?.toIso8601String(),
    };
