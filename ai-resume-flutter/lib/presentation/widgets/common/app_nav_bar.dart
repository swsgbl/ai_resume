import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/config/theme_config.dart';
import '../../routes/app_router.dart';
import '../../providers/auth_provider.dart';

/// 应用顶部导航栏
///
/// 用于桌面端和移动端的顶部导航
class AppNavBar extends ConsumerWidget implements PreferredSizeWidget {
  final String title;
  final bool showBackButton;
  final List<Widget>? actions;

  const AppNavBar({
    super.key,
    this.title = '',
    this.showBackButton = false,
    this.actions,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 16);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: ThemeConfig.glassDecoration,
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            // Logo
            _buildLogo(context),
            const SizedBox(width: 32),

            // 导航链接 (仅桌面端显示)
            if (MediaQuery.of(context).size.width > 768) ...[
              _buildNavLink(context, '我的简历', RouteConstants.resumes),
              const SizedBox(width: 24),
              _buildNavLink(context, '模板库', RouteConstants.templates),
              const SizedBox(width: 24),
              _buildNavLink(context, '个人中心', RouteConstants.profile),
              const Spacer(),
            ],

            // 移动端使用Spacer
            if (MediaQuery.of(context).size.width <= 768) ...[
              const Spacer(),
            ],

            // 用户信息区域
            if (user != null) ...[
              _buildUserInfo(user),
              const SizedBox(width: 16),
            ],

            // 设置按钮
            _buildIconButton(
              context,
              Icons.settings_outlined,
              () => context.go(RouteConstants.settings),
            ),
            const SizedBox(width: 8),

            // 退出按钮 (仅登录后显示)
            if (user != null) ...[
              _buildIconButton(
                context,
                Icons.logout_outlined,
                () async {
                  final notifier = ref.read(authProvider.notifier);
                  await notifier.logout();
                  if (context.mounted) {
                    context.go(RouteConstants.login);
                  }
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLogo(BuildContext context) {
    return InkWell(
      onTap: () => context.go(RouteConstants.home),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: ThemeConfig.primaryGradient,
                borderRadius: BorderRadius.circular(10),
                boxShadow: ThemeConfig.neonShadow,
              ),
              child: const Icon(
                Icons.description_outlined,
                size: 20,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'AI Resume',
              style: ThemeConfig.heading3.copyWith(
                foreground: Paint()
                  ..shader = ThemeConfig.primaryGradient.createShader(
                    const Rect.fromLTWH(0, 0, 200, 20),
                  ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavLink(BuildContext context, String label, String route) {
    final currentLocation = GoRouterState.of(context).matchedLocation;
    final isActive = currentLocation.startsWith(route);

    return InkWell(
      onTap: () => context.go(route),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Text(
          label,
          style: ThemeConfig.bodyMedium.copyWith(
            color: isActive ? ThemeConfig.primary : ThemeConfig.textSecondary,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildUserInfo(dynamic user) {
    final nickname = user.nickname ?? user.email ?? '用户';
    final initial = nickname.isNotEmpty ? nickname[0].toUpperCase() : 'U';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              gradient: ThemeConfig.primaryGradient,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                initial,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            nickname,
            style: ThemeConfig.bodySmall.copyWith(
              color: Colors.white70,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: user.isVip ? Colors.amber.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: user.isVip ? Colors.amber : Colors.grey.withOpacity(0.3),
              ),
            ),
            child: Text(
              user.isVip ? 'PRO' : 'FREE',
              style: ThemeConfig.bodySmall.copyWith(
                color: user.isVip ? Colors.amber : Colors.grey,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton(BuildContext context, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(8),
        child: Icon(
          icon,
          color: ThemeConfig.textSecondary,
          size: 20,
        ),
      ),
    );
  }
}
