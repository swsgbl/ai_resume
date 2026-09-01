/// UseCase基类定义
///
/// UseCase表示一个业务用例，封装单一的业务逻辑操作
library;

import 'package:dartz/dartz.dart';
import 'package:ai_resume_flutter/core/errors/failures.dart';

/// 同步UseCase基类
///
/// [Type] 返回值类型
/// [Params] 参数类型
abstract class UseCase<Type, Params> {
  /// 执行用例
  ///
  /// 返回 [Right] 包含结果，失败返回 [Left]
  Either<Failure, Type> call(Params params);
}

/// 异步UseCase基类
abstract class AsyncUseCase<Type, Params> {
  /// 执行用例
  ///
  /// 返回 [Right] 包含结果，失败返回 [Left]
  Future<Either<Failure, Type>> call(Params params);
}

/// 无参数UseCase的标记类
class NoParams {
  const NoParams();
}
