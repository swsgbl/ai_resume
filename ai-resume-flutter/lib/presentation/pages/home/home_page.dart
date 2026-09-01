import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:math' as math;
import '../../../core/config/theme_config.dart';
import '../../../core/config/app_config.dart';
import '../../routes/app_router.dart';
import '../../widgets/common/app_nav_bar.dart';
import '../../widgets/common/bottom_nav_bar.dart';
import '../../widgets/home/feature_card.dart';

/// 首页
///
/// 应用主页，展示功能入口和快速操作
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  /// 获取当前导航索引
  int _getCurrentIndex() {
    final location = GoRouterState.of(context).matchedLocation;
    if (location == RouteConstants.home) return 0;
    if (location.startsWith(RouteConstants.resumes)) return 1;
    if (location.startsWith(RouteConstants.templates)) return 2;
    if (location.startsWith(RouteConstants.profile)) return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Scaffold(
      body: Stack(
        children: [
          // 背景装饰
          _buildBackground(),

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
                        // Hero 区域
                        _buildHeroSection(context),

                        const SizedBox(height: 40),

                        // 快速统计区域
                        _buildStatsSection(),

                        const SizedBox(height: 40),

                        // 快速操作区域
                        _buildQuickActions(context),

                        const SizedBox(height: 40),

                        // 功能特性区域
                        _buildFeaturesSection(context),

                        const SizedBox(height: 40),

                        // CTA 行动号召区域
                        _buildCTASection(context),
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
          ? BottomNavBar(currentIndex: _getCurrentIndex())
          : null,
    );
  }

  /// 背景装饰
  Widget _buildBackground() {
    return Positioned.fill(
      child: Stack(
        children: [
          // 主渐变背景
          Container(
            decoration: const BoxDecoration(
              gradient: ThemeConfig.primaryGradient,
            ),
          ),
          // 装饰球体
          Positioned(
            top: -100,
            right: -100,
            child: _Orb(
              size: 300,
              color: ThemeConfig.primary.withOpacity(0.3),
            ),
          ),
          Positioned(
            bottom: -150,
            left: -150,
            child: _Orb(
              size: 400,
              color: ThemeConfig.accent.withOpacity(0.2),
            ),
          ),
          Positioned(
            top: 300,
            left: -100,
            child: _Orb(
              size: 200,
              color: ThemeConfig.primary.withOpacity(0.15),
            ),
          ),
        ],
      ),
    );
  }

  /// Hero 区域
  Widget _buildHeroSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '欢迎使用 ${AppConfig.appName}',
          style: ThemeConfig.heading1.copyWith(
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          '使用AI技术快速创建专业简历，让求职更简单',
          style: ThemeConfig.bodyLarge.copyWith(
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            ElevatedButton.icon(
              onPressed: () => context.go(RouteConstants.resumeNew),
              icon: const Icon(Icons.add, size: 20),
              label: const Text('创建新简历'),
              style: ElevatedButton.styleFrom(
                backgroundColor: ThemeConfig.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(width: 16),
            OutlinedButton.icon(
              onPressed: () => context.go(RouteConstants.templates),
              icon: const Icon(Icons.grid_view, size: 20),
              label: const Text('浏览模板'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(
                  color: Colors.white.withOpacity(0.3),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 统计区域
  Widget _buildStatsSection() {
    return Row(
      children: [
        Expanded(
          child: StatCard(
            value: '0',
            label: '我的简历',
            color: ThemeConfig.primary,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: StatCard(
            value: '10+',
            label: '精选模板',
            color: ThemeConfig.accent,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: StatCard(
            value: 'AI',
            label: '智能生成',
            color: Colors.green,
          ),
        ),
      ],
    );
  }

  /// 快速操作区域
  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '快速操作',
          style: ThemeConfig.heading3.copyWith(
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: QuickActionCard(
                icon: Icons.add_circle_outline,
                label: '新建简历',
                onTap: () => context.go(RouteConstants.resumeNew),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: QuickActionCard(
                icon: Icons.upload_file_outlined,
                label: '导入简历',
                iconColor: ThemeConfig.accent,
                onTap: () {
                  // TODO: 实现导入功能
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: QuickActionCard(
                icon: Icons.auto_awesome_outlined,
                label: 'AI生成',
                iconColor: Colors.amber,
                onTap: () {
                  // TODO: 实现AI生成功能
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: QuickActionCard(
                icon: Icons.history,
                label: '历史记录',
                iconColor: Colors.green,
                onTap: () => context.go(RouteConstants.resumes),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 功能特性区域
  Widget _buildFeaturesSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '核心功能',
          style: ThemeConfig.heading3.copyWith(
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: _getGridCount(context),
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.3,
          children: [
            FeatureCard(
              icon: Icons.edit_note_outlined,
              title: '在线编辑',
              description: '所见即所得的简历编辑器，支持多种格式导出',
              onTap: () => context.go(RouteConstants.resumes),
            ),
            FeatureCard(
              icon: Icons.auto_awesome_outlined,
              title: 'AI生成',
              description: '输入职位描述，AI自动生成匹配的简历内容',
              onTap: () => context.go(RouteConstants.resumeNew),
            ),
            FeatureCard(
              icon: Icons.grid_view_outlined,
              title: '精美模板',
              description: '多种专业模板，一键应用，快速开始',
              onTap: () => context.go(RouteConstants.templates),
            ),
            FeatureCard(
              icon: Icons.sync_outlined,
              title: '实时同步',
              description: '云端存储，多端同步，随时随地编辑',
              onTap: () => context.go(RouteConstants.settings),
            ),
            FeatureCard(
              icon: Icons.download_outlined,
              title: 'PDF导出',
              description: '一键导出高质量PDF，支持打印和分享',
              onTap: () => context.go(RouteConstants.resumes),
            ),
            FeatureCard(
              icon: Icons.security_outlined,
              title: '数据安全',
              description: '加密存储，保护您的隐私数据安全',
              onTap: () => context.go(RouteConstants.settings),
            ),
          ],
        ),
      ],
    );
  }

  /// CTA 行动号召区域
  Widget _buildCTASection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            ThemeConfig.primary.withOpacity(0.3),
            ThemeConfig.accent.withOpacity(0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '准备好创建你的专业简历了吗？',
                  style: ThemeConfig.heading3.copyWith(
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '加入数千名求职者，使用AI创建令人印象深刻的简历',
                  style: ThemeConfig.bodyMedium.copyWith(
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          ElevatedButton(
            onPressed: () => context.go(RouteConstants.resumeNew),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: ThemeConfig.primary,
              padding: const EdgeInsets.symmetric(
                horizontal: 32,
                vertical: 16,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('开始创建'),
          ),
        ],
      ),
    );
  }

  /// 获取网格列数
  int _getGridCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 600) return 1;
    if (width < 900) return 2;
    return 3;
  }
}

/// 装饰球体组件
class _Orb extends StatelessWidget {
  final double size;
  final Color color;

  const _Orb({
    required this.size,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color,
            color.withOpacity(0.5),
            Colors.transparent,
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
    );
  }
}
