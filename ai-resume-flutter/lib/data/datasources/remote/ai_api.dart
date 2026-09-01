import 'package:flutter/foundation.dart';
import '../../models/ai_models.dart' as models;
import '../../models/resume.dart';
import '../../../core/network/api_client.dart';

/// AI简历生成API
///
/// 处理所有AI相关的API调用
class AIApi {
  late final ApiClient _client;

  /// 初始化API
  void initialize() {
    _client = ApiClient();
  }

  /// AI生成完整简历
  ///
  /// 根据目标职位和用户信息，自动生成完整的简历内容
  Future<models.AIGenerateResponse> generateResume({
    required String targetPosition,
    int? workYears,
    String? industry,
    List<String>? skills,
    String? expectedSalary,
    String? location,
    Map<String, dynamic>? config,
  }) async {
    final request = models.AIGenerateRequest(
      targetPosition: targetPosition,
      workYears: workYears,
      industry: industry,
      skills: skills,
      expectedSalary: expectedSalary,
      location: location,
    );

    final response = await _client.post(
      '/ai/resume/generate',
      data: {
        ...request.toJson(),
        if (config != null) 'config': config,
      },
    );

    return models.AIGenerateResponse.fromJson(response);
  }

  /// AI优化简历内容
  ///
  /// 对指定内容进行AI优化，提升表达质量
  Future<models.AIOptimizeResponse> optimizeContent({
    required String content,
    required models.AIOptimizeType type,
    String? targetPosition,
  }) async {
    final request = models.AIOptimizeRequest(
      content: content,
      type: type,
      targetPosition: targetPosition,
    );

    final response = await _client.post(
      '/ai/optimize',
      data: request.toJson(),
    );

    return models.AIOptimizeResponse.fromJson(response);
  }

  /// 获取AI建议
  ///
  /// 分析当前简历，提供改进建议
  Future<List<models.AISuggestion>> getSuggestions({
    required ResumeContent content,
    String? targetPosition,
  }) async {
    final response = await _client.post(
      '/ai/suggestions',
      data: {
        'content': content.toJson(),
        if (targetPosition != null) 'targetPosition': targetPosition,
      },
    );

    final List<dynamic> suggestions = response['suggestions'] ?? [];
    return suggestions.map((e) => models.AISuggestion(
      id: e['id'] ?? '',
      type: _parseSuggestionType(e['type']),
      title: e['title'] ?? '',
      description: e['description'] ?? '',
      suggestedContent: e['suggestedContent'],
      priority: e['priority'] ?? 0,
    )).toList();
  }

  /// 生成工作描述
  ///
  /// 根据职位和公司信息生成专业的工作描述
  Future<String> generateWorkDescription({
    required String company,
    required String position,
    String? industry,
    List<String>? skills,
  }) async {
    final response = await _client.post(
      '/ai/work-description',
      data: {
        'company': company,
        'position': position,
        if (industry != null) 'industry': industry,
        if (skills != null) 'skills': skills,
      },
    );

    return response['description'] ?? '';
  }

  /// 生成项目亮点
  ///
  /// 根据项目描述生成项目亮点
  Future<List<String>> generateProjectHighlights({
    required String projectName,
    required String description,
    List<String>? techStack,
  }) async {
    final response = await _client.post(
      '/ai/project-highlights',
      data: {
        'projectName': projectName,
        'description': description,
        if (techStack != null) 'techStack': techStack,
      },
    );

    final List<dynamic> highlights = response['highlights'] ?? [];
    return highlights.map((e) => e.toString()).toList();
  }

  /// 推荐技能
  ///
  /// 根据目标职位推荐相关技能
  Future<List<String>> suggestSkills({
    required String targetPosition,
    String? industry,
  }) async {
    final response = await _client.post(
      '/ai/suggest-skills',
      data: {
        'targetPosition': targetPosition,
        if (industry != null) 'industry': industry,
      },
    );

    final List<dynamic> skills = response['skills'] ?? [];
    return skills.map((e) => e.toString()).toList();
  }

  /// 获取简历模板列表
  ///
  /// 获取所有可用的简历模板
  Future<List<models.ResumeTemplate>> getTemplates() async {
    final response = await _client.get('/templates');

    final List<dynamic> templates = response['templates'] ?? [];
    return templates.map((e) => models.ResumeTemplate.fromJson(e)).toList();
  }

  /// 根据职位推荐模板
  ///
  /// AI根据目标职位推荐最适合的模板
  Future<List<models.ResumeTemplate>> recommendTemplates({
    required String targetPosition,
    String? industry,
  }) async {
    final response = await _client.post(
      '/ai/recommend-templates',
      data: {
        'targetPosition': targetPosition,
        if (industry != null) 'industry': industry,
      },
    );

    final List<dynamic> templates = response['templates'] ?? [];
    return templates.map((e) => models.ResumeTemplate.fromJson(e)).toList();
  }

  /// 获取生成进度
  ///
  /// 轮询获取AI生成任务的当前进度
  Future<models.AIGenerationTask> getGenerationProgress(String taskId) async {
    final response = await _client.get('/ai/generate/$taskId/progress');

    return models.AIGenerationTask(
      id: response['taskId'] ?? '',
      status: _parseTaskStatus(response['status']),
      progress: response['progress'] ?? 0,
      currentStep: response['currentStep'] ?? '',
      content: response['content'] != null
          ? ResumeContent.fromJson(response['content'])
          : null,
      error: response['error'],
      startTime: DateTime.now(),
    );
  }

  /// 取消生成任务
  Future<void> cancelGeneration(String taskId) async {
    await _client.post('/ai/generate/$taskId/cancel');
  }

  models.AISuggestionType _parseSuggestionType(String? type) {
    switch (type) {
      case 'missing':
        return models.AISuggestionType.missing;
      case 'improvement':
        return models.AISuggestionType.improvement;
      case 'format':
        return models.AISuggestionType.format;
      case 'keyword':
        return models.AISuggestionType.keyword;
      case 'skill':
        return models.AISuggestionType.skill;
      default:
        return models.AISuggestionType.improvement;
    }
  }

  models.AITaskStatus _parseTaskStatus(String? status) {
    switch (status) {
      case 'idle':
        return models.AITaskStatus.idle;
      case 'analyzing':
        return models.AITaskStatus.analyzing;
      case 'generating':
        return models.AITaskStatus.generating;
      case 'optimizing':
        return models.AITaskStatus.optimizing;
      case 'completed':
        return models.AITaskStatus.completed;
      case 'failed':
        return models.AITaskStatus.failed;
      case 'cancelled':
        return models.AITaskStatus.cancelled;
      default:
        return models.AITaskStatus.idle;
    }
  }
}
