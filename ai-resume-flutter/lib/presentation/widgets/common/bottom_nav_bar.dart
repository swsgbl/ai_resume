import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/config/theme_config.dart';
import '../../routes/app_router.dart';

/// 底部导航栏
///
/// 用于移动端的底部导航
class BottomNavBar extends StatelessWidget {
  final int currentIndex;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
  });

  void _onTap(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go(RouteConstants.home);
        break;
      case 1:
        context.go(RouteConstants.resumes);
        break;
      case 2:
        context.go(RouteConstants.templates);
        break;
      case 3:
        context.go(RouteConstants.profile);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ThemeConfig.cardBg.withOpacity(0.9),
        border: Border(
          top: BorderSide(
            color: Colors.white.withOpacity(0.1),
          ),
        ),
      ),
      child: SafeArea(
        child: SizedBox(
          height: 65,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                icon: Icons.home_outlined,
                activeIcon: Icons.home,
                label: '首页',
                index: 0,
                context: context,
              ),
              _buildNavItem(
                icon: Icons.description_outlined,
                activeIcon: Icons.description,
                label: '简历',
                index: 1,
                context: context,
              ),
              _buildNavItem(
                icon: Icons.grid_view_outlined,
                activeIcon: Icons.grid_view,
                label: '模板',
                index: 2,
                context: context,
              ),
              _buildNavItem(
                icon: Icons.person_outline,
                activeIcon: Icons.person,
                label: '我的',
                index: 3,
                context: context,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
    required BuildContext context,
  }) {
    final isActive = currentIndex == index;

    return Expanded(
      child: InkWell(
        onTap: () => _onTap(index, context),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Icon(
              isActive ? activeIcon : icon,
              color: isActive ? ThemeConfig.primary : ThemeConfig.textSecondary,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: ThemeConfig.bodySmall.copyWith(
                color: isActive ? ThemeConfig.primary : ThemeConfig.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
