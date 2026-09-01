/// 模板仓库接口
///
/// 定义模板相关的数据操作契约
library;

import 'package:dartz/dartz.dart';
import '../entities/template.dart';
import '../../core/errors/failures.dart';

/// 模板仓库接口
abstract class TemplateRepository {
  /// 获取模板列表
  ///
  /// [page] 页码（从1开始）
  /// [pageSize] 每页数量
  /// [category] 分类筛选（可选）
  /// [isVip] 是否只看VIP模板（可选）
  ///
  /// 返回 [Right] 包含模板列表，失败返回 [Left]
  Future<Either<Failure, List<TemplateEntity>>> getTemplates({
    int page = 1,
    int pageSize = 20,
    TemplateCategory? category,
    bool? isVip,
  });

  /// 获取模板详情
  ///
  /// [id] 模板ID
  ///
  /// 返回 [Right] 包含模板详情，失败返回 [Left]
  Future<Either<Failure, TemplateEntity>> getTemplateById(String id);

  /// 获取热门模板
  ///
  /// [limit] 返回数量限制
  ///
  /// 返回 [Right] 包含热门模板列表，失败返回 [Left]
  Future<Either<Failure, List<TemplateEntity>>> getPopularTemplates({
    int limit = 10,
  });

  /// 获取推荐模板
  ///
  /// [limit] 返回数量限制
  ///
  /// 返回 [Right] 包含推荐模板列表，失败返回 [Left]
  Future<Either<Failure, List<TemplateEntity>>> getRecommendedTemplates({
    int limit = 10,
  });

  /// 搜索模板
  ///
  /// [keyword] 搜索关键词
  /// [category] 分类筛选（可选）
  ///
  /// 返回 [Right] 包含搜索结果，失败返回 [Left]
  Future<Either<Failure, List<TemplateEntity>>> searchTemplates({
    required String keyword,
    TemplateCategory? category,
  });
}
