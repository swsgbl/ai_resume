import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/config/theme_config.dart';
import '../../../data/models/ai_models.dart';
import '../../providers/ai_generation_provider.dart';
import '../../widgets/ai/ai_input_field.dart';
import '../../widgets/ai/ai_input_field.dart' as ai_widgets;
import '../../routes/app_router.dart';

/// AI一键生成简历页面
///
/// 用户只需输入目标职位等信息，AI自动生成完整简历
class AIGeneratePage extends ConsumerStatefulWidget {
  const AIGeneratePage({super.key});

  @override
  ConsumerState<AIGeneratePage> createState() => _AIGeneratePageState();
}

class _AIGeneratePageState extends ConsumerState<AIGeneratePage> {
  final _formKey = GlobalKey<FormState>();
  final _positionController = TextEditingController();
  final _industryController = TextEditingController();
  final _locationController = TextEditingController();
  final _salaryController = TextEditingController();

  int _workYears = 0;
  List<String> _selectedSkills = [];
  AIGenerationStyle _style = AIGenerationStyle.professional;

  final List<String> _commonSkills = [
    'Java', 'Python', 'JavaScript', 'React', 'Vue', 'Flutter',
    'Docker', 'Kubernetes', 'MySQL', 'MongoDB', 'Git',
    'Agile', 'Scrum', 'Leadership', 'Communication',
  ];

  @override
  void dispose() {
    _positionController.dispose();
    _industryController.dispose();
    _locationController.dispose();
    _salaryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(aiGenerationProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: ThemeConfig.primaryGradient,
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 返回按钮
                      IconButton(
                        onPressed: () => context.pop(),
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.1),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // 标题
                      Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.amber.shade400,
                                  Colors.orange.shade400,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.amber.withOpacity(0.3),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.auto_awesome,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'AI智能生成简历',
                                style: ThemeConfig.heading2.copyWith(
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                '只需输入目标职位，AI自动生成专业简历',
                                style: ThemeConfig.bodySmall.copyWith(
                                  color: Colors.white60,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 40),

                      // 表单卡片
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: ThemeConfig.glassDecoration,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 必填信息
                            _buildSectionTitle('基本信息', '必填'),
                            const SizedBox(height: 16),

                            AISmartInputField(
                              label: '目标职位',
                              hint: '例如：高级前端工程师',
                              icon: Icons.work_outline,
                              controller: _positionController,
                              showSkillSuggestions: true,
                            ),

                            const SizedBox(height: 32),

                            // 可选信息
                            _buildSectionTitle('更多信息', '选填，帮助AI生成更精准的简历'),
                            const SizedBox(height: 16),

                            // 工作年限
                            _buildWorkYearsSelector(),
                            const SizedBox(height: 16),

                            // 行业
                            _buildInputField(
                              '行业',
                              '例如：互联网、金融、医疗',
                              Icons.business_outlined,
                              _industryController,
                            ),
                            const SizedBox(height: 16),

                            // 工作地点
                            _buildInputField(
                              '期望工作地点',
                              '例如：北京、上海、远程',
                              Icons.location_on_outlined,
                              _locationController,
                            ),
                            const SizedBox(height: 16),

                            // 期望薪资
                            _buildInputField(
                              '期望薪资',
                              '例如：15-25K',
                              Icons.payments_outlined,
                              _salaryController,
                            ),

                            const SizedBox(height: 24),

                            // 技能标签
                            _buildSkillsSelector(),

                            const SizedBox(height: 24),

                            // 生成风格
                            _buildStyleSelector(),

                            const SizedBox(height: 32),

                            // 生成按钮
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                onPressed: state.isGenerating ? null : _handleGenerate,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.amber,
                                  foregroundColor: Colors.white,
                                  disabledBackgroundColor: Colors.grey.shade700,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 0,
                                ),
                                child: state.isGenerating
                                    ? const Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                            ),
                                          ),
                                          SizedBox(width: 12),
                                          Text('AI正在生成中...'),
                                        ],
                                      )
                                    : const Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.auto_awesome, size: 20),
                                          SizedBox(width: 8),
                                          Text('开始生成', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: ThemeConfig.heading3.copyWith(color: Colors.white)),
        const SizedBox(height: 4),
        Text(subtitle, style: ThemeConfig.bodySmall.copyWith(color: Colors.white60)),
      ],
    );
  }

  Widget _buildInputField(
    String label,
    String hint,
    IconData icon,
    TextEditingController controller,
  ) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: ThemeConfig.textSecondary),
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
    );
  }

  Widget _buildWorkYearsSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('工作年限', style: const TextStyle(color: Colors.white70)),
        const SizedBox(height: 12),
        Row(
          children: List.generate(11, (index) {
            final years = index;
            final isSelected = _workYears == years;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _workYears = years),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? ThemeConfig.primary : Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? ThemeConfig.primary : Colors.white.withOpacity(0.1),
                    ),
                  ),
                  child: Text(
                    years == 10 ? '10+' : years.toString(),
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white60,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildSkillsSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('相关技能', style: const TextStyle(color: Colors.white70)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _commonSkills.map((skill) {
            final isSelected = _selectedSkills.contains(skill);
            return FilterChip(
              label: Text(skill),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedSkills.add(skill);
                  } else {
                    _selectedSkills.remove(skill);
                  }
                });
              },
              backgroundColor: Colors.white.withOpacity(0.05),
              selectedColor: ThemeConfig.primary.withOpacity(0.3),
              labelStyle: TextStyle(
                color: isSelected ? ThemeConfig.primary : Colors.white60,
                fontSize: 13,
              ),
              side: BorderSide(
                color: isSelected ? ThemeConfig.primary : Colors.white.withOpacity(0.1),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildStyleSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('简历风格', style: const TextStyle(color: Colors.white70)),
        const SizedBox(height: 12),
        Row(
          children: AIGenerationStyle.values.map((style) {
            final isSelected = _style == style;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _style = style),
                child: Container(
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: isSelected ? ThemeConfig.primary.withOpacity(0.2) : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? ThemeConfig.primary : Colors.white.withOpacity(0.1),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Text(
                    _getStyleLabel(style),
                    style: TextStyle(
                      color: isSelected ? ThemeConfig.primary : Colors.white60,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  String _getStyleLabel(AIGenerationStyle style) {
    switch (style) {
      case AIGenerationStyle.professional:
        return '专业正式';
      case AIGenerationStyle.concise:
        return '简洁明了';
      case AIGenerationStyle.detailed:
        return '详细全面';
      case AIGenerationStyle.creative:
        return '创意新颖';
    }
  }

  Future<void> _handleGenerate() async {
    if (_positionController.text.trim().isEmpty) {
      _showError('请输入目标职位');
      return;
    }

    // 显示进度对话框
    final dialogResult = await ai_widgets.AIGenerationDialog.show(context);

    if (dialogResult == true) {
      // 生成成功，导航到编辑器
      final content = ref.read(aiGenerationProvider).content;
      if (content != null && mounted) {
        // TODO: 创建新简历并导航到编辑器
        context.go(RouteConstants.resumeNew);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: ThemeConfig.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
