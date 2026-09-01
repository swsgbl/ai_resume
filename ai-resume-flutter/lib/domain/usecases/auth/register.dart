/// 注册用例
library;

import 'package:dartz/dartz.dart';
import '../usecase.dart';
import '../../entities/auth_result.dart';
import '../../repositories/auth_repository.dart';
import '../../../core/errors/failures.dart';
import '../../../utils/validators/email_validator.dart';
import '../../../utils/validators/password_validator.dart';

/// 注册参数
class RegisterParams {
  final String email;
  final String password;
  final String confirmPassword;
  final String nickname;
  final String? code;

  const RegisterParams({
    required this.email,
    required this.password,
    required this.confirmPassword,
    required this.nickname,
    this.code,
  });

  @override
  List<Object?> get props => [email, password, confirmPassword, nickname, code];
}

/// 注册用例
class RegisterUseCase implements AsyncUseCase<AuthResult, RegisterParams> {
  final AuthRepository repository;

  RegisterUseCase(this.repository);

  @override
  Future<Either<Failure, AuthResult>> call(RegisterParams params) async {
    // 验证邮箱
    final emailError = EmailValidator.validate(params.email);
    if (emailError != null) {
      return Left(ValidationFailure(emailError));
    }

    // 验证密码
    final passwordError = PasswordValidator.validate(params.password);
    if (passwordError != null) {
      return Left(ValidationFailure(passwordError));
    }

    // 验证确认密码
    if (params.password != params.confirmPassword) {
      return const Left(ValidationFailure.passwordMismatch());
    }

    // 验证昵称
    if (params.nickname.isEmpty) {
      return const Left(ValidationFailure.emptyField('昵称'));
    }

    // 调用仓库
    return await repository.register(
      email: params.email,
      password: params.password,
      nickname: params.nickname,
      code: params.code,
    );
  }
}
