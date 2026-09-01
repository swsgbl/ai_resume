import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/config/theme_config.dart';
import '../../providers/auth_provider.dart';
import '../../routes/app_router.dart';
import '../../widgets/common/app_nav_bar.dart';
import '../../widgets/common/bottom_nav_bar.dart';

/// 个人中心页面
class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
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
                      children: [
                        // 用户信息卡片
                        _buildUserInfoCard(user),
                        const SizedBox(height: 24),

                        // 统计数据
                        _buildStatsSection(),
                        const SizedBox(height: 24),

                        // 功能菜单
                        _buildMenuSection(context, ref),
                        const SizedBox(height: 24),

                        // VIP会员卡片
                        _buildVIPCard(context),
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
          ? const BottomNavBar(currentIndex: 3)
          : null,
    );
  }

  /// 用户信息卡片
  Widget _buildUserInfoCard(dynamic user) {
    final nickname = user?.nickname ?? '用户';
    final email = user?.email ?? '';
    final initial = nickname.isNotEmpty ? nickname[0].toUpperCase() : 'U';
    final isVip = user?.isVip ?? false;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: ThemeConfig.glassDecoration,
      child: Column(
        children: [
          // 头像
          GestureDetector(
            onTap: () {
              // TODO: 打开头像选择
            },
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: ThemeConfig.primaryGradient,
                borderRadius: BorderRadius.circular(20),
                boxShadow: ThemeConfig.neonShadow,
              ),
              child: Center(
                child: Text(
                  initial,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 昵称和VIP徽章
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                nickname,
                style: ThemeConfig.heading2.copyWith(
                  color: Colors.white,
                ),
              ),
              if (isVip) ...[
                const SizedBox(width: 8),
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
                    boxShadow: [
                      BoxShadow(
                        color: Colors.amber.withOpacity(0.3),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: const Text(
                    'VIP',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: 8),

          // 邮箱
          Text(
            email,
            style: ThemeConfig.bodyMedium.copyWith(
              color: Colors.white60,
            ),
          ),
        ],
      ),
    );
  }

  /// 统计数据
  Widget _buildStatsSection() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard('我的简历', '0', Icons.description_outlined),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard('已使用模板', '0', Icons.grid_view_outlined),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard('AI生成次数', '0', Icons.auto_awesome_outlined),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
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
        children: [
          Icon(icon, color: ThemeConfig.primary, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: ThemeConfig.heading2.copyWith(
              color: Colors.white,
            ),
          ),
          Text(
            title,
            style: ThemeConfig.bodySmall.copyWith(
              color: Colors.white60,
            ),
          ),
        ],
      ),
    );
  }

  /// 功能菜单
  Widget _buildMenuSection(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: ThemeConfig.glassDecoration,
      child: Column(
        children: [
          _buildMenuItem(
            context,
            Icons.person_outline,
            '个人资料',
            () {
              // TODO: 打开个人资料编辑
            },
          ),
          _buildMenuItem(
            context,
            Icons.security_outlined,
            '账号安全',
            () {
              // TODO: 打开账号安全设置
            },
          ),
          _buildMenuItem(
            context,
            Icons.history_outlined,
            '使用记录',
            () {
              // TODO: 打开使用记录
            },
          ),
          _buildMenuItem(
            context,
            Icons.help_outline,
            '帮助与反馈',
            () {
              // TODO: 打开帮助中心
            },
          ),
          Divider(
            height: 1,
            color: Colors.white.withOpacity(0.1),
          ),
          _buildMenuItem(
            context,
            Icons.settings_outlined,
            '设置',
            () {
              context.go(RouteConstants.settings);
            },
          ),
          _buildMenuItem(
            context,
            Icons.logout_outlined,
            '退出登录',
            () async {
              final notifier = ref.read(authProvider.notifier);
              await notifier.logout();
              if (context.mounted) {
                context.go(RouteConstants.login);
              }
            },
            color: ThemeConfig.error,
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context,
    IconData icon,
    String title,
    VoidCallback onTap, {
    Color? color,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: color ?? ThemeConfig.textSecondary,
                size: 22,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: ThemeConfig.bodyMedium.copyWith(
                    color: color ?? Colors.white70,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Colors.white.withOpacity(0.3),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// VIP会员卡片
  Widget _buildVIPCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.amber.withOpacity(0.2),
            Colors.orange.withOpacity(0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.amber.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.amber.shade400,
                      Colors.orange.shade400,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.amber.withOpacity(0.3),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.diamond,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '升级VIP会员',
                      style: ThemeConfig.heading3.copyWith(
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '解锁更多模板和AI功能',
                      style: ThemeConfig.bodySmall.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              // TODO: 打开VIP购买页面
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 32,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('立即升级'),
          ),
        ],
      ),
    );
  }
}
