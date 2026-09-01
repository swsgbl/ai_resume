import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/ai_models.dart';
import '../../../data/models/resume.dart';
import '../../../data/datasources/remote/ai_api.dart';

/// AI生成状态
class AIGenerationState {
  /// 当前任务
  final AIGenerationTask? task;

  /// 是否正在生成
  bool get isGenerating => task?.status == AITaskStatus.generating ||
      task?.status == AITaskStatus.analyzing ||
      task?.status == AITaskStatus.optimizing;

  /// 是否完成
  bool get isCompleted => task?.status == AITaskStatus.completed;

  /// 是否失败
  bool get isFailed => task?.status == AITaskStatus.failed;

  /// 进度 (0-100)
  int get progress => task?.progress ?? 0;

  /// 当前步骤描述
  String get currentStep => task?.currentStep ?? '';

  /// 生成的内容
  ResumeContent? get content => task?.content;

  /// 错误信息
  String? get error => task?.error;

  AIGenerationState({
    this.task,
  });

  AIGenerationState copyWith({
    AIGenerationTask? task,
  }) {
    return AIGenerationState(
      task: task ?? this.task,
    );
  }
}

/// AI生成状态管理
class AIGenerationNotifier extends StateNotifier<AIGenerationState> {
  final AIApi _aiApi = AIApi();

  AIGenerationNotifier() : super(AIGenerationState()) {
    _aiApi.initialize();
  }

  /// 开始AI生成简历
  Future<void> generateResume({
    required String targetPosition,
    int? workYears,
    String? industry,
    List<String>? skills,
    String? expectedSalary,
    String? location,
    AIGenerationConfig? config,
  }) async {
    // 创建新任务
    final task = AIGenerationTask.create();
    state = AIGenerationState(task: task.copyWith(
      status: AITaskStatus.analyzing,
      currentStep: '正在分析职位要求...',
      progress: 10,
    ));

    try {
      // 模拟进度更新
      await _simulateProgress();

      // 调用API生成
      final response = await _aiApi.generateResume(
        targetPosition: targetPosition,
        workYears: workYears,
        industry: industry,
        skills: skills,
        expectedSalary: expectedSalary,
        location: location,
        config: config?.toJson(),
      );

      state = AIGenerationState(task: task.copyWith(
        status: AITaskStatus.completed,
        progress: 100,
        currentStep: '生成完成！',
        content: response.content,
      ));
    } catch (e) {
      state = AIGenerationState(task: task.copyWith(
        status: AITaskStatus.failed,
        error: e.toString(),
        currentStep: '生成失败',
      ));
    }
  }

  /// 优化内容
  Future<String?> optimizeContent({
    required String content,
    required AIOptimizeType type,
    String? targetPosition,
  }) async {
    try {
      final response = await _aiApi.optimizeContent(
        content: content,
        type: type,
        targetPosition: targetPosition,
      );
      return response.optimizedContent;
    } catch (e) {
      return null;
    }
  }

  /// 获取AI建议
  Future<List<AISuggestion>> getSuggestions({
    required ResumeContent content,
    String? targetPosition,
  }) async {
    try {
      return await _aiApi.getSuggestions(
        content: content,
        targetPosition: targetPosition,
      );
    } catch (e) {
      return [];
    }
  }

  /// 生成工作描述
  Future<String?> generateWorkDescription({
    required String company,
    required String position,
    String? industry,
    List<String>? skills,
  }) async {
    try {
      return await _aiApi.generateWorkDescription(
        company: company,
        position: position,
        industry: industry,
        skills: skills,
      );
    } catch (e) {
      return null;
    }
  }

  /// 生成项目亮点
  Future<List<String>?> generateProjectHighlights({
    required String projectName,
    required String description,
    List<String>? techStack,
  }) async {
    try {
      return await _aiApi.generateProjectHighlights(
        projectName: projectName,
        description: description,
        techStack: techStack,
      );
    } catch (e) {
      return null;
    }
  }

  /// 推荐技能
  Future<List<String>> suggestSkills({
    required String targetPosition,
    String? industry,
  }) async {
    try {
      return await _aiApi.suggestSkills(
        targetPosition: targetPosition,
        industry: industry,
      );
    } catch (e) {
      return [];
    }
  }

  /// 取消生成
  void cancelGeneration() {
    if (state.task != null && !state.isCompleted) {
      state = AIGenerationState(task: state.task!.copyWith(
        status: AITaskStatus.cancelled,
        currentStep: '已取消',
      ));
    }
  }

  /// 重置状态
  void reset() {
    state = AIGenerationState();
  }

  /// 模拟进度更新
  Future<void> _simulateProgress() async {
    final steps = [
      (30, '正在分析职位信息...'),
      (50, '正在匹配技能关键词...'),
      (70, '正在生成工作经历...'),
      (85, '正在优化语言表达...'),
      (95, '即将完成...'),
    ];

    for (final (progress, step) in steps) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (state.isFailed || state.task?.status == AITaskStatus.cancelled) {
        return;
      }
      state = AIGenerationState(task: state.task?.copyWith(
        progress: progress,
        currentStep: step,
      ));
    }
  }
}

/// AI生成状态Provider
final aiGenerationProvider =
    StateNotifierProvider<AIGenerationNotifier, AIGenerationState>((ref) {
  return AIGenerationNotifier();
});

/// AI技能建议Provider
final aiSkillsSuggestionProvider =
    FutureProvider.family<List<String>, _SkillParams>((ref, params) async {
  final notifier = ref.watch(aiGenerationProvider.notifier);
  return await notifier.suggestSkills(
    targetPosition: params.targetPosition,
    industry: params.industry,
  );
});

/// 技能建议参数
class _SkillParams {
  final String targetPosition;
  final String? industry;

  const _SkillParams({
    required this.targetPosition,
    this.industry,
  });
}

/// 便捷方法：获取技能建议
List<String> useSkillsSuggestions(
  WidgetRef ref, {
  required String targetPosition,
  String? industry,
}) {
  return ref.watch(aiSkillsSuggestionProvider(
    _SkillParams(targetPosition: targetPosition, industry: industry),
  )).value ?? [];
}
