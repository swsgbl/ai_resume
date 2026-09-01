import 'package:json_annotation/json_annotation.dart';
import 'resume.dart';

part 'ai_models.g.dart';

/// AI生成请求
@JsonSerializable()
class AIGenerateRequest {
  /// 目标职位
  final String targetPosition;

  /// 工作年限
  final int? workYears;

  /// 目标行业
  final String? industry;

  /// 技能关键词
  final List<String>? skills;

  /// 期望薪资
  final String? expectedSalary;

  /// 工作地点
  final String? location;

  AIGenerateRequest({
    required this.targetPosition,
    this.workYears,
    this.industry,
    this.skills,
    this.expectedSalary,
    this.location,
  });

  factory AIGenerateRequest.fromJson(Map<String, dynamic> json) =>
      _$AIGenerateRequestFromJson(json);

  Map<String, dynamic> toJson() => _$AIGenerateRequestToJson(this);
}

/// AI生成响应
@JsonSerializable()
class AIGenerateResponse {
  /// 生成的简历内容
  final ResumeContent content;

  /// 使用的模板ID
  final int? templateId;

  /// 生成耗时（秒）
  final int duration;

  /// 生成状态
  final String status;

  AIGenerateResponse({
    required this.content,
    this.templateId,
    required this.duration,
    required this.status,
  });

  factory AIGenerateResponse.fromJson(Map<String, dynamic> json) =>
      _$AIGenerateResponseFromJson(json);

  Map<String, dynamic> toJson() => _$AIGenerateResponseToJson(this);
}

/// AI优化请求
@JsonSerializable()
class AIOptimizeRequest {
  /// 需要优化的内容
  final String content;

  /// 优化类型
  final AIOptimizeType type;

  /// 目标职位（用于上下文）
  final String? targetPosition;

  AIOptimizeRequest({
    required this.content,
    required this.type,
    this.targetPosition,
  });

  factory AIOptimizeRequest.fromJson(Map<String, dynamic> json) =>
      _$AIOptimizeRequestFromJson(json);

  Map<String, dynamic> toJson() => _$AIOptimizeRequestToJson(this);
}

/// AI优化类型
enum AIOptimizeType {
  /// 优化个人简介
  @JsonValue('summary')
  summary,

  /// 优化工作描述
  @JsonValue('work_description')
  workDescription,

  /// 优化项目描述
  @JsonValue('project_description')
  projectDescription,

  /// 生成技能关键词
  @JsonValue('skills')
  skills,

  /// 生成自我介绍
  @JsonValue('self_introduction')
  selfIntroduction,
}

/// AI优化响应
@JsonSerializable()
class AIOptimizeResponse {
  /// 优化后的内容
  final String optimizedContent;

  /// 原始内容
  final String originalContent;

  /// 优化建议
  final List<String>? suggestions;

  /// 评分 (0-100)
  final int? score;

  AIOptimizeResponse({
    required this.optimizedContent,
    required this.originalContent,
    this.suggestions,
    this.score,
  });

  factory AIOptimizeResponse.fromJson(Map<String, dynamic> json) =>
      _$AIOptimizeResponseFromJson(json);

  Map<String, dynamic> toJson() => _$AIOptimizeResponseToJson(this);
}

/// AI生成任务状态
class AIGenerationTask {
  /// 任务ID
  final String id;

  /// 状态
  final AITaskStatus status;

  /// 进度 (0-100)
  final int progress;

  /// 当前步骤描述
  final String currentStep;

  /// 生成的内容（部分或完整）
  final ResumeContent? content;

  /// 错误信息
  final String? error;

  /// 开始时间
  final DateTime startTime;

  AIGenerationTask({
    required this.id,
    required this.status,
    this.progress = 0,
    this.currentStep = '',
    this.content,
    this.error,
    required this.startTime,
  });

  /// 创建空任务
  factory AIGenerationTask.create() {
    return AIGenerationTask(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      status: AITaskStatus.idle,
      startTime: DateTime.now(),
    );
  }

  AIGenerationTask copyWith({
    String? id,
    AITaskStatus? status,
    int? progress,
    String? currentStep,
    ResumeContent? content,
    String? error,
    DateTime? startTime,
  }) {
    return AIGenerationTask(
      id: id ?? this.id,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      currentStep: currentStep ?? this.currentStep,
      content: content ?? this.content,
      error: error ?? this.error,
      startTime: startTime ?? this.startTime,
    );
  }
}

/// AI任务状态
enum AITaskStatus {
  /// 空闲
  @JsonValue('idle')
  idle,

  /// 分析中
  @JsonValue('analyzing')
  analyzing,

  /// 生成中
  @JsonValue('generating')
  generating,

  /// 优化中
  @JsonValue('optimizing')
  optimizing,

  /// 完成
  @JsonValue('completed')
  completed,

  /// 失败
  @JsonValue('failed')
  failed,

  /// 已取消
  @JsonValue('cancelled')
  cancelled,
}

/// 简历模板
@JsonSerializable()
class ResumeTemplate {
  final int id;
  final String name;
  final String description;
  final String category;
  final String preview;
  final int? colorScheme;
  final bool isPro;

  ResumeTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.preview,
    this.colorScheme,
    this.isPro = false,
  });

  factory ResumeTemplate.fromJson(Map<String, dynamic> json) =>
      _$ResumeTemplateFromJson(json);

  Map<String, dynamic> toJson() => _$ResumeTemplateToJson(this);
}

/// AI生成配置
class AIGenerationConfig {
  /// 是否自动匹配模板
  final bool autoMatchTemplate;

  /// 是否生成成就数据
  final bool generateAchievements;

  /// 是否优化语言表达
  final bool optimizeLanguage;

  /// 生成风格
  final AIGenerationStyle style;

  AIGenerationConfig({
    this.autoMatchTemplate = true,
    this.generateAchievements = true,
    this.optimizeLanguage = true,
    this.style = AIGenerationStyle.professional,
  });

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'autoMatchTemplate': autoMatchTemplate,
      'generateAchievements': generateAchievements,
      'optimizeLanguage': optimizeLanguage,
      'style': style.name,
    };
  }
}

/// AI生成风格
enum AIGenerationStyle {
  /// 专业正式
  professional,

  /// 简洁明了
  concise,

  /// 详细全面
  detailed,

  /// 创意新颖
  creative,
}

/// AI智能建议
class AISuggestion {
  final String id;
  final AISuggestionType type;
  final String title;
  final String description;
  final String? suggestedContent;
  final int priority;

  AISuggestion({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    this.suggestedContent,
    this.priority = 0,
  });
}

/// AI建议类型
enum AISuggestionType {
  /// 缺少重要信息
  missing,

  /// 可以改进
  improvement,

  /// 格式问题
  format,

  /// 关键词优化
  keyword,

  /// 技能建议
  skill,
}
