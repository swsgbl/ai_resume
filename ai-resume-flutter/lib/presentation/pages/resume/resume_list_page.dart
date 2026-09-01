import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/config/theme_config.dart';
import '../../routes/app_router.dart';
import '../../widgets/common/app_nav_bar.dart';
import '../../widgets/common/bottom_nav_bar.dart';

/// 简历列表页
class ResumeListPage extends ConsumerStatefulWidget {
  const ResumeListPage({super.key});

  @override
  ConsumerState<ResumeListPage> createState() => _ResumeListPageState();
}

class _ResumeListPageState extends ConsumerState<ResumeListPage> {
  String _selectedFilter = 'all';

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

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
                        // 标题和操作按钮
                        _buildHeader(context),

                        const SizedBox(height: 24),

                        // 筛选器
                        _buildFilters(),

                        const SizedBox(height: 24),

                        // 简历列表
                        _buildResumeList(context),
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
          ? const BottomNavBar(currentIndex: 1)
          : null,

      // 浮动操作按钮
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go(RouteConstants.resumeNew),
        backgroundColor: ThemeConfig.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          '新建简历',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  /// 头部区域
  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '我的简历',
                style: ThemeConfig.heading1.copyWith(
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '管理您的所有简历',
                style: ThemeConfig.bodyMedium.copyWith(
                  color: Colors.white60,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        IconButton(
          onPressed: () {
            // TODO: 打开搜索
          },
          icon: Icon(
            Icons.search_outlined,
            color: Colors.white.withOpacity(0.7),
          ),
          style: IconButton.styleFrom(
            backgroundColor: Colors.white.withOpacity(0.1),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: () {
            // TODO: 打开排序选项
          },
          icon: Icon(
            Icons.sort_outlined,
            color: Colors.white.withOpacity(0.7),
          ),
          style: IconButton.styleFrom(
            backgroundColor: Colors.white.withOpacity(0.1),
          ),
        ),
      ],
    );
  }

  /// 筛选器
  Widget _buildFilters() {
    final filters = [
      {'value': 'all', 'label': '全部'},
      {'value': 'draft', 'label': '草稿'},
      {'value': 'published', 'label': '已发布'},
      {'value': 'archived', 'label': '已归档'},
    ];

    return Wrap(
      spacing: 8,
      children: filters.map((filter) {
        final isSelected = _selectedFilter == filter['value'];
        return FilterChip(
          label: Text(filter['label'] as String),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              _selectedFilter = filter['value'] as String;
            });
          },
          backgroundColor: Colors.white.withOpacity(0.1),
          selectedColor: ThemeConfig.primary.withOpacity(0.5),
          labelStyle: ThemeConfig.bodySmall.copyWith(
            color: isSelected ? Colors.white : Colors.white70,
          ),
          side: BorderSide(
            color: isSelected ? ThemeConfig.primary : Colors.white.withOpacity(0.2),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        );
      }).toList(),
    );
  }

  /// 简历列表
  Widget _buildResumeList(BuildContext context) {
    // TODO: 从API获取实际数据
    final resumes = <dynamic>[];

    if (resumes.isEmpty) {
      return _buildEmptyState(context);
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
      itemCount: resumes.length,
      itemBuilder: (context, index) {
        return _buildResumeCard(context, resumes[index]);
      },
    );
  }

  /// 空状态
  Widget _buildEmptyState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(48),
      decoration: ThemeConfig.glassDecoration,
      child: Column(
        children: [
          Icon(
            Icons.description_outlined,
            size: 80,
            color: Colors.white.withOpacity(0.3),
          ),
          const SizedBox(height: 24),
          Text(
            '还没有简历',
            style: ThemeConfig.heading2.copyWith(
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '创建您的第一份简历，开启求职之旅',
            style: ThemeConfig.bodyMedium.copyWith(
              color: Colors.white60,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => context.go(RouteConstants.resumeNew),
            icon: const Icon(Icons.add, size: 20),
            label: const Text('创建新简历'),
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
          ),
        ],
      ),
    );
  }

  /// 简历卡片
  Widget _buildResumeCard(BuildContext context, dynamic resume) {
    return InkWell(
      onTap: () => context.go(RouteConstants.resumeDetailPath(resume.id.toString())),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withOpacity(0.1),
              Colors.white.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题和状态
            Row(
              children: [
                Expanded(
                  child: Text(
                    resume.title ?? '未命名简历',
                    style: ThemeConfig.heading3.copyWith(
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _buildStatusBadge(resume.status ?? 0),
              ],
            ),
            const SizedBox(height: 12),

            // 预览图
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Icon(
                    Icons.description_outlined,
                    size: 48,
                    color: Colors.white.withOpacity(0.2),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // 更新时间
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 14,
                  color: Colors.white.withOpacity(0.5),
                ),
                const SizedBox(width: 4),
                Text(
                  _formatDate(resume.updatedAt),
                  style: ThemeConfig.bodySmall.copyWith(
                    color: Colors.white.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 状态徽章
  Widget _buildStatusBadge(int status) {
    String label;
    Color color;

    switch (status) {
      case 0: // 草稿
        label = '草稿';
        color = Colors.grey;
        break;
      case 1: // 已发布
        label = '已发布';
        color = Colors.green;
        break;
      case 2: // 已归档
        label = '已归档';
        color = Colors.orange;
        break;
      default:
        label = '未知';
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.5),
        ),
      ),
      child: Text(
        label,
        style: ThemeConfig.bodySmall.copyWith(
          color: color,
          fontSize: 10,
        ),
      ),
    );
  }

  /// 格式化日期
  String _formatDate(dynamic date) {
    if (date == null) return '未知时间';
    // TODO: 实现日期格式化
    return '刚刚';
  }

  /// 获取网格列数
  int _getGridCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 600) return 1;
    if (width < 900) return 2;
    return 3;
  }

  /// 获取卡片宽高比
  double _getAspectRatio(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 600) return 1.2;
    return 1.4;
  }
}
