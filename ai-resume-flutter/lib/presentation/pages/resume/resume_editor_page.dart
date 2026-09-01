import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/config/theme_config.dart';
import '../../../data/models/resume.dart';
import '../../routes/app_router.dart';
import '../../widgets/resume_editor/basic_info_tab.dart';
import '../../widgets/resume_editor/education_tab.dart';
import '../../widgets/resume_editor/work_experience_tab.dart';
import '../../widgets/resume_editor/project_tab.dart';
import '../../widgets/resume_editor/skills_tab.dart';

/// 简历编辑器
class ResumeEditorPage extends ConsumerStatefulWidget {
  final String? resumeId;

  const ResumeEditorPage({super.key, this.resumeId});

  @override
  ConsumerState<ResumeEditorPage> createState() => _ResumeEditorPageState();
}

class _ResumeEditorPageState extends ConsumerState<ResumeEditorPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late ResumeContent _content;
  final TextEditingController _titleController = TextEditingController();

  // 标签页定义
  final List<_TabInfo> _tabs = const [
    _TabInfo(label: '基本信息', icon: Icons.person_outline),
    _TabInfo(label: '教育经历', icon: Icons.school_outlined),
    _TabInfo(label: '工作经历', icon: Icons.work_outline),
    _TabInfo(label: '项目经历', icon: Icons.rocket_launch_outlined),
    _TabInfo(label: '技能特长', icon: Icons.stars_outlined),
  ];

  bool _isSaving = false;
  bool _isGenerating = false;
  bool _isNew = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _content = ResumeContent.empty();
    _isNew = widget.resumeId == null;
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: ThemeConfig.primaryGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // 顶部工具栏
              _buildToolbar(context, isMobile),

              // 标题输入
              _buildTitleSection(isMobile),

              // 标签页
              Expanded(
                child: Container(
                  margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  decoration: ThemeConfig.glassDecoration,
                  child: Column(
                    children: [
                      // 标签页头部
                      _buildTabHeader(context),

                      const Divider(
                        height: 1,
                        color: Colors.white10,
                      ),

                      // 标签页内容
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _buildBasicInfoTab(),
                            _buildEducationTab(),
                            _buildWorkExperienceTab(),
                            _buildProjectTab(),
                            _buildSkillsTab(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 顶部工具栏
  Widget _buildToolbar(BuildContext context, bool isMobile) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // 返回按钮
          IconButton(
            onPressed: () => context.go(RouteConstants.resumes),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.1),
            ),
          ),

          const SizedBox(width: 16),

          // 标题
          Expanded(
            child: Text(
              _isNew ? '新建简历' : '编辑简历',
              style: ThemeConfig.heading3.copyWith(
                color: Colors.white,
              ),
            ),
          ),

          // AI生成按钮
          if (!_isNew) ...[
            Container(
              height: 36,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.amber.shade400,
                    Colors.orange.shade400,
                  ],
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.amber.withOpacity(0.3),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: _isGenerating ? null : _handleAIGenerate,
                icon: _isGenerating
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.auto_awesome, size: 18),
                label: Text(_isGenerating ? '生成中...' : 'AI生成'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],

          // 保存按钮
          ElevatedButton.icon(
            onPressed: _isSaving ? null : _handleSave,
            icon: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.save, size: 18),
            label: Text(_isSaving ? '保存中...' : '保存'),
            style: ElevatedButton.styleFrom(
              backgroundColor: ThemeConfig.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 标题输入区域
  Widget _buildTitleSection(bool isMobile) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        controller: _titleController,
        style: ThemeConfig.heading2.copyWith(
          color: Colors.white,
        ),
        decoration: InputDecoration(
          hintText: '输入简历标题',
          hintStyle: TextStyle(
            color: Colors.white.withOpacity(0.3),
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  /// 标签页头部
  Widget _buildTabHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        indicatorColor: ThemeConfig.primary,
        indicatorSize: TabBarIndicatorSize.label,
        labelColor: ThemeConfig.primary,
        unselectedLabelColor: Colors.white54,
        labelStyle: ThemeConfig.bodyMedium.copyWith(
          fontWeight: FontWeight.w600,
        ),
        tabs: _tabs
            .map((tab) => Tab(
                  text: tab.label,
                  icon: Icon(tab.icon, size: 20),
                ))
            .toList(),
      ),
    );
  }

  /// 基本信息标签页
  Widget _buildBasicInfoTab() {
    return BasicInfoTab(
      basicInfo: _content.basicInfo ?? BasicInfo.empty(),
      onChanged: (value) {
        setState(() {
          _content = _content.copyWith(basicInfo: value);
        });
      },
    );
  }

  /// 教育经历标签页
  Widget _buildEducationTab() {
    return EducationTab(
      education: _content.education ?? [],
      onChanged: (value) {
        setState(() {
          _content = _content.copyWith(education: value);
        });
      },
    );
  }

  /// 工作经历标签页
  Widget _buildWorkExperienceTab() {
    return WorkExperienceTab(
      workExperience: _content.workExperience ?? [],
      onChanged: (value) {
        setState(() {
          _content = _content.copyWith(workExperience: value);
        });
      },
    );
  }

  /// 项目经历标签页
  Widget _buildProjectTab() {
    return ProjectTab(
      projects: _content.projects ?? [],
      onChanged: (value) {
        setState(() {
          _content = _content.copyWith(projects: value);
        });
      },
    );
  }

  /// 技能特长标签页
  Widget _buildSkillsTab() {
    return SkillsTab(
      skills: _content.skills ?? [],
      onChanged: (value) {
        setState(() {
          _content = _content.copyWith(skills: value);
        });
      },
    );
  }

  /// 处理保存
  Future<void> _handleSave() async {
    if (_titleController.text.trim().isEmpty) {
      _showError('请输入简历标题');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // TODO: 调用API保存
      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        _showSuccess('保存成功');
        context.go(RouteConstants.resumes);
      }
    } catch (e) {
      if (mounted) {
        _showError(e.toString());
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  /// 处理AI生成
  Future<void> _handleAIGenerate() async {
    final basicInfo = _content.basicInfo;
    if (basicInfo == null ||
        (basicInfo.jobIntention == null || basicInfo.jobIntention!.isEmpty)) {
      _showError('请先填写求职意向');
      _tabController.animateTo(0);
      return;
    }

    setState(() {
      _isGenerating = true;
    });

    try {
      // TODO: 调用AI生成API
      await Future.delayed(const Duration(seconds: 3));

      if (mounted) {
        _showSuccess('AI生成完成');
      }
    } catch (e) {
      if (mounted) {
        _showError(e.toString());
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
    }
  }

  /// 显示错误消息
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: ThemeConfig.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// 显示成功消息
  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

/// 标签页信息
class _TabInfo {
  final String label;
  final IconData icon;

  const _TabInfo({
    required this.label,
    required this.icon,
  });
}
