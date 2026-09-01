/// 简历领域实体
library;

import '../../data/models/resume.dart';

/// 简历实体
///
/// 表示应用中的简历概念
class ResumeEntity {
  final String id;
  final String userId;
  final String title;
  final String? summary;
  final ResumeStatus status;
  final String? templateId;
  final Map<String, dynamic>? content;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? publishedAt;

  const ResumeEntity({
    required this.id,
    required this.userId,
    required this.title,
    this.summary,
    this.status = ResumeStatus.draft,
    this.templateId,
    this.content,
    required this.createdAt,
    required this.updatedAt,
    this.publishedAt,
  });

  /// 从数据模型创建实体
  factory ResumeEntity.fromModel(Resume model) {
    return ResumeEntity(
      id: model.id,
      userId: model.userId,
      title: model.title,
      summary: model.summary,
      status: ResumeStatus.fromValue(model.status),
      templateId: model.templateId,
      content: model.content,
      createdAt: model.createdAt,
      updatedAt: model.updatedAt,
      publishedAt: model.publishedAt,
    );
  }

  /// 转换为数据模型
  Resume toModel() {
    return Resume(
      id: id,
      userId: userId,
      title: title,
      summary: summary,
      status: status.value,
      templateId: templateId,
      content: content,
      createdAt: createdAt,
      updatedAt: updatedAt,
      publishedAt: publishedAt,
    );
  }

  /// 复制并修改部分属性
  ResumeEntity copyWith({
    String? id,
    String? userId,
    String? title,
    String? summary,
    ResumeStatus? status,
    String? templateId,
    Map<String, dynamic>? content,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? publishedAt,
  }) {
    return ResumeEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      summary: summary ?? this.summary,
      status: status ?? this.status,
      templateId: templateId ?? this.templateId,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      publishedAt: publishedAt ?? this.publishedAt,
    );
  }

  /// 是否为草稿
  bool get isDraft => status == ResumeStatus.draft;

  /// 是否已发布
  bool get isPublished => status == ResumeStatus.published;

  /// 是否已归档
  bool get isArchived => status == ResumeStatus.archived;

  /// 是否可以编辑（草稿和已发布可编辑）
  bool get canEdit => isDraft || isPublished;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ResumeEntity && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'ResumeEntity(id: $id, title: $title, status: $status)';
  }
}

/// 简历状态枚举
enum ResumeStatus {
  draft('草稿', 0),
  published('已发布', 1),
  archived('已归档', 2);

  final String label;
  final int value;

  const ResumeStatus(this.label, this.value);

  /// 从值获取状态
  static ResumeStatus fromValue(int value) {
    return ResumeStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => ResumeStatus.draft,
    );
  }

  /// 获取下一个状态
  ResumeStatus? get nextStatus {
    switch (this) {
      case ResumeStatus.draft:
        return ResumeStatus.published;
      case ResumeStatus.published:
        return ResumeStatus.archived;
      case ResumeStatus.archived:
        return null;
    }
  }
}
