/// 获取简历列表用例
library;

import 'package:dartz/dartz.dart';
import '../usecase.dart';
import '../../entities/resume.dart';
import '../../repositories/resume_repository.dart';
import '../../../core/errors/failures.dart';

/// 获取简历列表参数
class GetResumesParams {
  final int page;
  final int pageSize;
  final ResumeStatus? status;

  const GetResumesParams({
    this.page = 1,
    this.pageSize = 20,
    this.status,
  });

  @override
  List<Object?> get props => [page, pageSize, status];
}

/// 获取简历列表用例
class GetResumesUseCase implements AsyncUseCase<List<ResumeEntity>, GetResumesParams> {
  final ResumeRepository repository;

  GetResumesUseCase(this.repository);

  @override
  Future<Either<Failure, List<ResumeEntity>>> call(GetResumesParams params) async {
    // 参数验证
    if (params.page < 1) {
      return const Left(ValidationFailure('页码必须大于0'));
    }

    if (params.pageSize < 1 || params.pageSize > 100) {
      return const Left(ValidationFailure('每页数量必须在1-100之间'));
    }

    // 调用仓库
    return await repository.getResumes(
      page: params.page,
      pageSize: params.pageSize,
      status: params.status,
    );
  }
}
