import 'package:json_annotation/json_annotation.dart';
import 'package:flutter/material.dart';

part 'resume_template.g.dart';

/// 简历模板模型
@JsonSerializable()
class ResumeTemplate {
  final int id;
  final String name;
  final String description;
  final String category;
  final String preview;
  final int? colorScheme;
  final bool isPro;
  final List<String>? tags;
  final int usageCount;

  ResumeTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.preview,
    this.colorScheme,
    this.isPro = false,
    this.tags,
    this.usageCount = 0,
  });

  factory ResumeTemplate.fromJson(Map<String, dynamic> json) =>
      _$ResumeTemplateFromJson(json);

  Map<String, dynamic> toJson() => _$ResumeTemplateToJson(this);

  ResumeTemplate copyWith({
    int? id,
    String? name,
    String? description,
    String? category,
    String? preview,
    int? colorScheme,
    bool? isPro,
    List<String>? tags,
    int? usageCount,
  }) {
    return ResumeTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      preview: preview ?? this.preview,
      colorScheme: colorScheme ?? this.colorScheme,
      isPro: isPro ?? this.isPro,
      tags: tags ?? this.tags,
      usageCount: usageCount ?? this.usageCount,
    );
  }

  /// 获取主题颜色
  Color getThemeColor() {
    switch (colorScheme) {
      case 1:
        return const Color(0xFF0EA5E9); // 蓝色
      case 2:
        return const Color(0xFF8B5CF6); // 紫色
      case 3:
        return const Color(0xFF22C55E); // 绿色
      case 4:
        return const Color(0xFFF59E0B); // 橙色
      case 5:
        return const Color(0xFFEC4899); // 粉色
      default:
        return const Color(0xFF6366F1); // 默认蓝紫色
    }
  }
}

/// 模板分类
enum TemplateCategory {
  @JsonValue('all')
  all,
  @JsonValue('professional')
  professional,
  @JsonValue('creative')
  creative,
  @JsonValue('simple')
  simple,
  @JsonValue('modern')
  modern,
  @JsonValue('executive')
  executive,
}

/// 模板分类扩展
extension TemplateCategoryExtension on TemplateCategory {
  String get displayName {
    switch (this) {
      case TemplateCategory.all:
        return '全部';
      case TemplateCategory.professional:
        return '专业';
      case TemplateCategory.creative:
        return '创意';
      case TemplateCategory.simple:
        return '简洁';
      case TemplateCategory.modern:
        return '现代';
      case TemplateCategory.executive:
        return '高管';
    }
  }

  String get icon {
    switch (this) {
      case TemplateCategory.all:
        return '📋';
      case TemplateCategory.professional:
        return '💼';
      case TemplateCategory.creative:
        return '🎨';
      case TemplateCategory.simple:
        return '📄';
      case TemplateCategory.modern:
        return '✨';
      case TemplateCategory.executive:
        return '👔';
    }
  }
}

/// 应用模板请求
@JsonSerializable()
class ApplyTemplateRequest {
  final int templateId;
  final int resumeId;

  ApplyTemplateRequest({
    required this.templateId,
    required this.resumeId,
  });

  factory ApplyTemplateRequest.fromJson(Map<String, dynamic> json) =>
      _$ApplyTemplateRequestFromJson(json);

  Map<String, dynamic> toJson() => _$ApplyTemplateRequestToJson(this);
}

/// 模板预览数据
class TemplatePreview {
  final String name;
  final String category;
  final List<PreviewSection> sections;

  TemplatePreview({
    required this.name,
    required this.category,
    required this.sections,
  });
}

/// 预览区域
class PreviewSection {
  final String type;
  final String title;
  final String content;

  PreviewSection({
    required this.type,
    required this.title,
    this.content = '',
  });
}

/// 模板颜色方案
class TemplateColorScheme {
  final int id;
  final String name;
  final Color primaryColor;
  final Color secondaryColor;
  final Color backgroundColor;
  final Color textColor;

  TemplateColorScheme({
    required this.id,
    required this.name,
    required this.primaryColor,
    required this.secondaryColor,
    required this.backgroundColor,
    required this.textColor,
  });

  /// 预定义颜色方案
  static List<TemplateColorScheme> get presets => [
    TemplateColorScheme(
      id: 1,
      name: '天空蓝',
      primaryColor: const Color(0xFF0EA5E9),
      secondaryColor: const Color(0xFF0284C7),
      backgroundColor: const Color(0xFFF0F9FF),
      textColor: const Color(0xFF0C4A6E),
    ),
    TemplateColorScheme(
      id: 2,
      name: '紫罗兰',
      primaryColor: const Color(0xFF8B5CF6),
      secondaryColor: const Color(0xFF7C3AED),
      backgroundColor: const Color(0xFFF5F3FF),
      textColor: const Color(0xFF5B21B6),
    ),
    TemplateColorScheme(
      id: 3,
      name: '翡翠绿',
      primaryColor: const Color(0xFF22C55E),
      secondaryColor: const Color(0xFF16A34A),
      backgroundColor: const Color(0xFFF0FDF4),
      textColor: const Color(0xFF14532D),
    ),
    TemplateColorScheme(
      id: 4,
      name: '琥珀橙',
      primaryColor: const Color(0xFFF59E0B),
      secondaryColor: const Color(0xFFD97706),
      backgroundColor: const Color(0xFFFFFBEB),
      textColor: const Color(0xFF78350F),
    ),
    TemplateColorScheme(
      id: 5,
      name: '玫瑰粉',
      primaryColor: const Color(0xFFEC4899),
      secondaryColor: const Color(0xFFDB2777),
      backgroundColor: const Color(0xFFFDF2F8),
      textColor: const Color(0xFF9F1239),
    ),
  ];
}
