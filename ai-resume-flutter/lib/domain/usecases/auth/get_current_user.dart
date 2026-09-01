/// 获取当前用户用例
library;

import 'package:dartz/dartz.dart';
import '../usecase.dart';
import '../../entities/user.dart';
import '../../repositories/auth_repository.dart';
import '../../../core/errors/failures.dart';

/// 获取当前用户用例
class GetCurrentUserUseCase implements AsyncUseCase<UserEntity, NoParams> {
  final AuthRepository repository;

  GetCurrentUserUseCase(this.repository);

  @override
  Future<Either<Failure, UserEntity>> call(NoParams params) async {
    return await repository.getCurrentUser();
  }
}

/// 用户实体（在这里定义以避免循环依赖）
class UserEntity {
  final String id;
  final String email;
  final String? nickname;
  final String? avatar;
  final String role;
  final bool isVip;

  const UserEntity({
    required this.id,
    required this.email,
    this.nickname,
    this.avatar,
    this.role = 'user',
    this.isVip = false,
  });

  /// 获取显示名称
  String get displayName {
    return nickname?.isNotEmpty == true ? nickname! : email.split('@')[0];
  }

  @override
  String toString() {
    return 'UserEntity(id: $id, email: $email, nickname: $nickname)';
  }
}
