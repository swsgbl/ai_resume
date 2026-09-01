import 'package:flutter/material.dart';
import '../../../core/config/theme_config.dart';

/// 功能卡片
///
/// 用于展示应用功能的卡片组件
class FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback? onTap;

  const FeatureCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
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
            // 图标
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: ThemeConfig.primaryGradient,
                borderRadius: BorderRadius.circular(12),
                boxShadow: ThemeConfig.neonShadow,
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(height: 16),

            // 标题
            Text(
              title,
              style: ThemeConfig.heading3.copyWith(
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),

            // 描述
            Text(
              description,
              style: ThemeConfig.bodySmall.copyWith(
                color: Colors.white60,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

/// 统计卡片
///
/// 用于展示统计数据
class StatCard extends StatelessWidget {
  final String value;
  final String label;
  final Color? color;

  const StatCard({
    super.key,
    required this.value,
    required this.label,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            (color ?? ThemeConfig.primary).withOpacity(0.2),
            (color ?? ThemeConfig.primary).withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: (color ?? ThemeConfig.primary).withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: ThemeConfig.heading1.copyWith(
              color: color ?? ThemeConfig.primary,
              fontSize: 36,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: ThemeConfig.bodySmall.copyWith(
              color: Colors.white60,
            ),
          ),
        ],
      ),
    );
  }
}

/// 快速操作卡片
///
/// 用于首页快速操作区域
class QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? iconColor;
  final VoidCallback onTap;

  const QuickActionCard({
    super.key,
    required this.icon,
    required this.label,
    this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: iconColor ?? ThemeConfig.primary,
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: ThemeConfig.bodySmall.copyWith(
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
