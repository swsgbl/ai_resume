import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/config/theme_config.dart';
import '../../../data/models/resume_template.dart';
import '../../routes/app_router.dart';
import '../../widgets/common/app_nav_bar.dart';
import '../../widgets/common/bottom_nav_bar.dart';
import '../../widgets/template/template_card.dart';

/// 模板库页面
class TemplatesPage extends ConsumerStatefulWidget {
  const TemplatesPage({super.key});

  @override
  ConsumerState<TemplatesPage> createState() => _TemplatesPageState();
}

class _TemplatesPageState extends ConsumerState<TemplatesPage> {
  TemplateCategory _selectedCategory = TemplateCategory.all;
  String _searchQuery = '';

  // 模拟模板数据
  final List<ResumeTemplate> _templates = [
    ResumeTemplate(
      id: 1,
      name: '专业经典',
      description: '适合大多数职位的专业简历模板',
      category: 'professional',
      preview: '📄',
      colorScheme: 1,
      isPro: false,
      tags: ['通用', '简洁', '专业'],
      usageCount: 15234,
    ),
    ResumeTemplate(
      id: 2,
      name: '现代简约',
      description: '简洁大气，突出重点信息',
      category: 'simple',
      preview: '📝',
      colorScheme: 2,
      isPro: false,
      tags: ['简洁', '现代'],
      usageCount: 12456,
    ),
    ResumeTemplate(
      id: 3,
      name: '创意设计',
      description: '适合设计师、创意工作者',
      category: 'creative',
      preview: '🎨',
      colorScheme: 5,
      isPro: true,
      tags: ['设计', '创意', '艺术'],
      usageCount: 8934,
    ),
    ResumeTemplate(
      id: 4,
      name: '技术专家',
      description: '突出技术能力和项目经验',
      category: 'professional',
      preview: '💻',
      colorScheme: 1,
      isPro: false,
      tags: ['技术', '开发', 'IT'],
      usageCount: 9876,
    ),
    ResumeTemplate(
      id: 5,
      name: '高管风范',
      description: '适合中高层管理职位',
      category: 'executive',
      preview: '👔',
      colorScheme: 3,
      isPro: true,
      tags: ['管理', '高管', '领导'],
      usageCount: 5432,
    ),
    ResumeTemplate(
      id: 6,
      name: '清新应届',
      description: '适合应届毕业生的简历模板',
      category: 'modern',
      preview: '🎓',
      colorScheme: 4,
      isPro: false,
      tags: ['应届', '实习', '入门'],
      usageCount: 21345,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;
    final filteredTemplates = _filterTemplates();

    return Scaffold(
      body: Stack(
        children: [
          // 背景
          Container(
            decoration: const BoxDecoration(
              gradient: ThemeConfig.primaryGradient,
            ),
          ),

          // 主要内容
          SafeArea(
            child: Column(
              children: [
                // 顶部导航栏
                const AppNavBar(),

                // 内容区域
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      24,
                      24,
                      24,
                      isMobile ? 80 : 24,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 标题和搜索
                        _buildHeader(context),

                        const SizedBox(height: 24),

                        // 分类筛选
                        _buildCategoryFilters(),

                        const SizedBox(height: 24),

                        // 模板网格
                        _buildTemplateGrid(filteredTemplates),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),

      // 底部导航栏 (仅移动端)
      bottomNavigationBar: isMobile
          ? const BottomNavBar(currentIndex: 2)
          : null,
    );
  }

  /// 头部区域
  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '模板库',
          style: ThemeConfig.heading1.copyWith(
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '选择精美模板，快速创建专业简历',
          style: ThemeConfig.bodyMedium.copyWith(
            color: Colors.white60,
          ),
        ),
        const SizedBox(height: 24),

        // 搜索框
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
            ),
          ),
          child: TextField(
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: '搜索模板名称或标签...',
              hintStyle: TextStyle(
                color: Colors.white.withOpacity(0.4),
              ),
              prefixIcon: Icon(
                Icons.search,
                color: Colors.white.withOpacity(0.6),
              ),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: Icon(
                        Icons.clear,
                        color: Colors.white.withOpacity(0.6),
                      ),
                      onPressed: () {
                        setState(() {
                          _searchQuery = '';
                        });
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
        ),
      ],
    );
  }

  /// 分类筛选器
  Widget _buildCategoryFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: TemplateCategory.values.map((category) {
          final isSelected = _selectedCategory == category;
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilterChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(category.icon, style: const TextStyle(fontSize: 14)),
                  const SizedBox(width: 4),
                  Text(category.displayName),
                ],
              ),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedCategory = category;
                });
              },
              backgroundColor: Colors.white.withOpacity(0.1),
              selectedColor: ThemeConfig.primary.withOpacity(0.3),
              labelStyle: ThemeConfig.bodyMedium.copyWith(
                color: isSelected ? ThemeConfig.primary : Colors.white70,
              ),
              side: BorderSide(
                color: isSelected ? ThemeConfig.primary : Colors.white.withOpacity(0.2),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// 模板网格
  Widget _buildTemplateGrid(List<ResumeTemplate> templates) {
    if (templates.isEmpty) {
      return _buildEmptyState();
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _getGridCount(context),
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: _getAspectRatio(context),
      ),
      itemCount: templates.length,
      itemBuilder: (context, index) {
        return TemplateCard(
          template: templates[index],
          onTap: () => _handleTemplateTap(templates[index]),
        );
      },
    );
  }

  /// 空状态
  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(48),
      decoration: ThemeConfig.glassDecoration,
      child: Column(
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Colors.white.withOpacity(0.3),
          ),
          const SizedBox(height: 24),
          Text(
            '没有找到匹配的模板',
            style: ThemeConfig.heading3.copyWith(
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '试试其他筛选条件吧',
            style: ThemeConfig.bodyMedium.copyWith(
              color: Colors.white60,
            ),
          ),
        ],
      ),
    );
  }

  /// 筛选模板
  List<ResumeTemplate> _filterTemplates() {
    var filtered = _templates;

    // 分类筛选
    if (_selectedCategory != TemplateCategory.all) {
      filtered = filtered
          .where((t) => t.category == _selectedCategory.name)
          .toList();
    }

    // 搜索筛选
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((t) {
        return t.name.toLowerCase().contains(query) ||
            t.description.toLowerCase().contains(query) ||
            t.tags?.any((tag) => tag.toLowerCase().contains(query)) == true;
      }).toList();
    }

    return filtered;
  }

  /// 处理模板点击
  void _handleTemplateTap(ResumeTemplate template) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildTemplateBottomSheet(template),
    );
  }

  /// 模板底部弹出面板
  Widget _buildTemplateBottomSheet(ResumeTemplate template) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            ThemeConfig.cardBg,
            ThemeConfig.darkBg,
          ],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 拖动指示器
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // 预览图
            Container(
              margin: const EdgeInsets.all(24),
              height: 300,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: template.getThemeColor().withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      template.preview,
                      style: const TextStyle(fontSize: 64),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      template.name,
                      style: ThemeConfig.heading3.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 信息
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          template.name,
                          style: ThemeConfig.heading2.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ),
                      if (template.isPro)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.amber.shade400,
                                Colors.orange.shade400,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'PRO',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    template.description,
                    style: ThemeConfig.bodyMedium.copyWith(
                      color: Colors.white60,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 标签
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: (template.tags ?? []).map((tag) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.1),
                          ),
                        ),
                        child: Text(
                          tag,
                          style: ThemeConfig.bodySmall.copyWith(
                            color: Colors.white70,
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 8),

                  // 使用次数
                  Row(
                    children: [
                      Icon(
                        Icons.trending_up,
                        size: 16,
                        color: Colors.white.withOpacity(0.5),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${template.usageCount} 次使用',
                        style: ThemeConfig.bodySmall.copyWith(
                          color: Colors.white.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 操作按钮
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        // TODO: 预览功能
                      },
                      icon: const Icon(Icons.visibility_outlined, size: 18),
                      label: const Text('预览'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: BorderSide(color: Colors.white.withOpacity(0.3)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        // TODO: 应用模板创建简历
                        context.go(RouteConstants.resumeNew);
                      },
                      icon: const Icon(Icons.add_circle_outline, size: 18),
                      label: const Text('使用此模板'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: template.getThemeColor(),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  int _getGridCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 600) return 1;
    if (width < 900) return 2;
    return 3;
  }

  double _getAspectRatio(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 600) return 0.85;
    return 1.1;
  }
}
