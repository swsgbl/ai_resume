/// 简历仓库接口
///
/// 定义简历相关的数据操作契约
library;

import 'package:dartz/dartz.dart';
import '../entities/resume.dart';
import '../../core/errors/failures.dart';

/// 简历仓库接口
abstract class ResumeRepository {
  /// 获取简历列表
  ///
  /// [page] 页码（从1开始）
  /// [pageSize] 每页数量
  /// [status] 状态筛选（可选）
  ///
  /// 返回 [Right] 包含简历列表，失败返回 [Left]
  Future<Either<Failure, List<ResumeEntity>>> getResumes({
    int page = 1,
    int pageSize = 20,
    ResumeStatus? status,
  });

  /// 获取简历详情
  ///
  /// [id] 简历ID
  ///
  /// 返回 [Right] 包含简历详情，失败返回 [Left]
  Future<Either<Failure, ResumeEntity>> getResumeById(String id);

  /// 创建简历
  ///
  /// [title] 简历标题
  /// [templateId] 模板ID（可选）
  ///
  /// 返回 [Right] 包含创建的简历，失败返回 [Left]
  Future<Either<Failure, ResumeEntity>> createResume({
    required String title,
    String? templateId,
  });

  /// 更新简历
  ///
  /// [id] 简历ID
  /// [title] 简历标题
  /// [summary] 简历摘要
  /// [content] 简历内容
  ///
  /// 返回 [Right] 包含更新后的简历，失败返回 [Left]
  Future<Either<Failure, ResumeEntity>> updateResume({
    required String id,
    String? title,
    String? summary,
    Map<String, dynamic>? content,
  });

  /// 删除简历
  ///
  /// [id] 简历ID
  ///
  /// 返回 [Right] 删除成功，失败返回 [Left]
  Future<Either<Failure, void>> deleteResume(String id);

  /// 发布简历
  ///
  /// [id] 简历ID
  ///
  /// 返回 [Right] 包含发布后的简历，失败返回 [Left]
  Future<Either<Failure, ResumeEntity>> publishResume(String id);

  /// 归档简历
  ///
  /// [id] 简历ID
  ///
  /// 返回 [Right] 包含归档后的简历，失败返回 [Left]
  Future<Either<Failure, ResumeEntity>> archiveResume(String id);

  /// 复制简历
  ///
  /// [id] 简历ID
  ///
  /// 返回 [Right] 包含复制后的新简历，失败返回 [Left]
  Future<Either<Failure, ResumeEntity>> duplicateResume(String id);

  /// AI生成简历
  ///
  /// [prompt] 用户输入的描述
  /// [templateId] 模板ID（可选）
  ///
  /// 返回 [Right] 包含生成的简历，失败返回 [Left]
  Future<Either<Failure, ResumeEntity>> generateResumeWithAI({
    required String prompt,
    String? templateId,
  });
}
