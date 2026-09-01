/// 登录用例
library;

import 'package:dartz/dartz.dart';
import '../usecase.dart';
import '../../entities/auth_result.dart';
import '../../repositories/auth_repository.dart';
import '../../../core/errors/failures.dart';

/// 登录参数
class LoginParams {
  final String email;
  final String password;

  const LoginParams({
    required this.email,
    required this.password,
  });

  @override
  List<Object> get props => [email, password];
}

/// 登录用例
class LoginUseCase implements AsyncUseCase<AuthResult, LoginParams> {
  final AuthRepository repository;

  LoginUseCase(this.repository);

  @override
  Future<Either<Failure, AuthResult>> call(LoginParams params) async {
    // 验证邮箱
    if (params.email.isEmpty) {
      return const Left(ValidationFailure.invalidEmail());
    }

    // 验证密码
    if (params.password.isEmpty) {
      return const Left(ValidationFailure.emptyField('密码'));
    }

    // 调用仓库
    return await repository.login(
      email: params.email,
      password: params.password,
    );
  }
}
