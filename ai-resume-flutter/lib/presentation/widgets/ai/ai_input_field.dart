import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/theme_config.dart';
import '../../../data/models/ai_models.dart';
import '../../providers/ai_generation_provider.dart';

/// AI智能输入组件
///
/// 支持输入职位后自动推荐相关技能
class AISmartInputField extends ConsumerStatefulWidget {
  final String label;
  final String hint;
  final IconData icon;
  final TextEditingController controller;
  final Function(String)? onChanged;
  final bool showSkillSuggestions;

  const AISmartInputField({
    super.key,
    required this.label,
    required this.hint,
    required this.icon,
    required this.controller,
    this.onChanged,
    this.showSkillSuggestions = false,
  });

  @override
  ConsumerState<AISmartInputField> createState() => _AISmartInputFieldState();
}

class _AISmartInputFieldState extends ConsumerState<AISmartInputField> {
  final FocusNode _focusNode = FocusNode();
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();
  List<String> _suggestions = [];

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _removeOverlay();
    super.dispose();
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus && widget.showSkillSuggestions) {
      _showSuggestions();
    } else {
      _removeOverlay();
    }
  }

  void _showSuggestions() {
    final value = widget.controller.text;
    if (value.isEmpty) return;

    // 获取AI技能建议
    final suggestions = ref.read(aiGenerationProvider.notifier).suggestSkills(
      targetPosition: value,
    );

    suggestions.then((result) {
      if (mounted && result.isNotEmpty) {
        setState(() {
          _suggestions = result;
        });
        _showOverlay();
      }
    });
  }

  void _showOverlay() {
    _removeOverlay();
    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: widget.controller.text.isEmpty ? 0 : 300,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 60),
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 200),
              decoration: BoxDecoration(
                color: ThemeConfig.cardBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: _suggestions.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    dense: true,
                    leading: Icon(
                      Icons.auto_awesome,
                      size: 16,
                      color: ThemeConfig.primary,
                    ),
                    title: Text(
                      _suggestions[index],
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    onTap: () => _selectSuggestion(_suggestions[index]),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _selectSuggestion(String suggestion) {
    widget.controller.text = suggestion;
    widget.onChanged?.call(suggestion);
    _removeOverlay();
    _focusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: TextField(
        controller: widget.controller,
        focusNode: _focusNode,
        style: const TextStyle(color: Colors.white),
        onChanged: widget.onChanged,
        decoration: InputDecoration(
          labelText: widget.label,
          hintText: widget.hint,
          prefixIcon: Icon(widget.icon, color: ThemeConfig.textSecondary),
          suffixIcon: widget.showSkillSuggestions
              ? Icon(Icons.auto_awesome, color: ThemeConfig.accent.withOpacity(0.7), size: 20)
              : null,
          labelStyle: const TextStyle(color: ThemeConfig.textSecondary),
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
          filled: true,
          fillColor: Colors.white.withOpacity(0.05),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(ThemeConfig.inputRadius),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(ThemeConfig.inputRadius),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(ThemeConfig.inputRadius),
            borderSide: const BorderSide(color: ThemeConfig.primary, width: 2),
          ),
        ),
      ),
    );
  }
}

/// AI优化按钮
///
/// 点击后对内容进行AI优化
class AIOptimizeButton extends ConsumerWidget {
  final String content;
  final AIOptimizeType type;
  final String? targetPosition;
  final ValueChanged<String> onOptimized;

  const AIOptimizeButton({
    super.key,
    required this.content,
    required this.type,
    this.targetPosition,
    required this.onOptimized,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.amber.shade400,
            Colors.orange.shade400,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withOpacity(0.3),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _handleOptimize(context, ref),
          borderRadius: BorderRadius.circular(20),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.auto_awesome, size: 16, color: Colors.white),
                SizedBox(width: 6),
                Text('AI优化', style: TextStyle(color: Colors.white, fontSize: 13)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleOptimize(BuildContext context, WidgetRef ref) async {
    final notifier = ref.read(aiGenerationProvider.notifier);
    final optimized = await notifier.optimizeContent(
      content: content,
      type: type,
      targetPosition: targetPosition,
    );

    if (optimized != null) {
      onOptimized(optimized);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('AI优化完成！'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}

/// AI生成进度对话框
class AIGenerationDialog extends ConsumerWidget {
  const AIGenerationDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(aiGenerationProvider);
    final progress = state.progress;
    final currentStep = state.currentStep;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              ThemeConfig.cardBg,
              ThemeConfig.darkBg,
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: ThemeConfig.primary.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // AI动画
            SizedBox(
              width: 80,
              height: 80,
              child: Stack(
                children: [
                  // 外圈光晕
                  Center(
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: ThemeConfig.primary.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                  // 中心图标
                  Center(
                    child: TweenAnimationBuilder<double>(
                      duration: const Duration(milliseconds: 1500),
                      tween: Tween(begin: 0, end: 1),
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: 0.8 + 0.2 * (1 + (value % 1) * 0.3),
                          child: Opacity(
                            opacity: 0.7 + 0.3 * (1 + (value % 1) * 0.3),
                            child: Icon(
                              Icons.auto_awesome,
                              size: 40,
                              color: ThemeConfig.primary,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 标题
            Text(
              state.isCompleted ? '生成完成！' : 'AI正在生成简历',
              style: ThemeConfig.heading3.copyWith(
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 16),

            // 进度条
            if (!state.isCompleted) ...[
              Stack(
                children: [
                  Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: progress / 100,
                    child: Container(
                      height: 8,
                      decoration: BoxDecoration(
                        gradient: ThemeConfig.primaryGradient,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 进度百分比
              Text(
                '$progress%',
                style: ThemeConfig.bodyMedium.copyWith(
                  color: ThemeConfig.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],

            const SizedBox(height: 16),

            // 当前步骤
            Text(
              currentStep,
              style: ThemeConfig.bodySmall.copyWith(
                color: Colors.white60,
              ),
              textAlign: TextAlign.center,
            ),

            // 完成时的按钮
            if (state.isCompleted) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ThemeConfig.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('查看结果'),
              ),
            ],

            // 失败时的按钮
            if (state.isFailed) ...[
              const SizedBox(height: 24),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('关闭'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: () {
                      ref.read(aiGenerationProvider.notifier).reset();
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ThemeConfig.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('重试'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 显示生成对话框
  static Future<bool?> show(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AIGenerationDialog(),
    );
  }
}
