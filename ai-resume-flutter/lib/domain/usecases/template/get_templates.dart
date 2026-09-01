/// 获取模板列表用例
library;

import 'package:dartz/dartz.dart';
import '../usecase.dart';
import '../../entities/template.dart';
import '../../repositories/template_repository.dart';
import '../../../core/errors/failures.dart';

/// 获取模板列表参数
class GetTemplatesParams {
  final int page;
  final int pageSize;
  final TemplateCategory? category;
  final bool? isVip;

  const GetTemplatesParams({
    this.page = 1,
    this.pageSize = 20,
    this.category,
    this.isVip,
  });

  @override
  List<Object?> get props => [page, pageSize, category, isVip];
}

/// 获取模板列表用例
class GetTemplatesUseCase implements AsyncUseCase<List<TemplateEntity>, GetTemplatesParams> {
  final TemplateRepository repository;

  GetTemplatesUseCase(this.repository);

  @override
  Future<Either<Failure, List<TemplateEntity>>> call(GetTemplatesParams params) async {
    // 参数验证
    if (params.page < 1) {
      return const Left(ValidationFailure('页码必须大于0'));
    }

    if (params.pageSize < 1 || params.pageSize > 100) {
      return const Left(ValidationFailure('每页数量必须在1-100之间'));
    }

    // 调用仓库
    return await repository.getTemplates(
      page: params.page,
      pageSize: params.pageSize,
      category: params.category,
      isVip: params.isVip,
    );
  }
}
