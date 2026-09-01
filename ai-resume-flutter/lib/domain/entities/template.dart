/// 模板领域实体
library;

import '../../data/models/template.dart';

/// 模板实体
///
///表示简历模板
class TemplateEntity {
  final String id;
  final String name;
  final String? description;
  final String? preview;
  final String thumbnail;
  final TemplateCategory category;
  final bool isVip;
  final List<String> tags;
  final int usageCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TemplateEntity({
    required this.id,
    required this.name,
    this.description,
    this.preview,
    required this.thumbnail,
    this.category = TemplateCategory.general,
    this.isVip = false,
    this.tags = const [],
    this.usageCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  /// 从数据模型创建实体
  factory TemplateEntity.fromModel(Template model) {
    return TemplateEntity(
      id: model.id,
      name: model.name,
      description: model.description,
      preview: model.preview,
      thumbnail: model.thumbnail,
      category: TemplateCategory.fromValue(model.category),
      isVip: model.isVip,
      tags: model.tags ?? [],
      usageCount: model.usageCount ?? 0,
      createdAt: model.createdAt,
      updatedAt: model.updatedAt,
    );
  }

  /// 转换为数据模型
  Template toModel() {
    return Template(
      id: id,
      name: name,
      description: description,
      preview: preview,
      thumbnail: thumbnail,
      category: category.value,
      isVip: isVip,
      tags: tags,
      usageCount: usageCount,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  /// 复制并修改部分属性
  TemplateEntity copyWith({
    String? id,
    String? name,
    String? description,
    String? preview,
    String? thumbnail,
    TemplateCategory? category,
    bool? isVip,
    List<String>? tags,
    int? usageCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TemplateEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      preview: preview ?? this.preview,
      thumbnail: thumbnail ?? this.thumbnail,
      category: category ?? this.category,
      isVip: isVip ?? this.isVip,
      tags: tags ?? this.tags,
      usageCount: usageCount ?? this.usageCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// 是否为免费模板
  bool get isFree => !isVip;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TemplateEntity && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'TemplateEntity(id: $id, name: $name, category: $category, isVip: $isVip)';
  }
}

/// 模板分类枚举
enum TemplateCategory {
  general('通用', 'general'),
  tech('技术', 'tech'),
  design('设计', 'design'),
  finance('金融', 'finance'),
  education('教育', 'education'),
  sales('销售', 'sales'),
  marketing('市场', 'marketing'),
  management('管理', 'management'),
  intern('实习生', 'intern');

  final String label;
  final String value;

  const TemplateCategory(this.label, this.value);

  /// 从值获取分类
  static TemplateCategory fromValue(String value) {
    return TemplateCategory.values.firstWhere(
      (category) => category.value == value,
      orElse: () => TemplateCategory.general,
    );
  }
}
