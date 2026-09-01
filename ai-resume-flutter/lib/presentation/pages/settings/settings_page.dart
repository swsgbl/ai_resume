import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/config/theme_config.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/app_nav_bar.dart';
import '../../widgets/common/bottom_nav_bar.dart';
import '../../routes/app_router.dart';

/// 设置页面
class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  bool _notificationsEnabled = true;
  bool _emailNotificationsEnabled = true;
  bool _darkModeEnabled = true;
  bool _autoSaveEnabled = true;
  String _language = 'zh-CN';
  String _fontSize = 'medium';

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
                AppNavBar(
                  title: '设置',
                  showBackButton: true,
                ),

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
                        // 账号设置
                        _buildSectionHeader('账号设置'),
                        const SizedBox(height: 12),
                        _buildSettingsCard([
                          _buildMenuItem(
                            icon: Icons.person_outline,
                            title: '个人资料',
                            subtitle: '修改昵称、头像等',
                            onTap: () {
                              // TODO: 打开个人资料编辑
                            },
                          ),
                          _buildMenuItem(
                            icon: Icons.lock_outline,
                            title: '修改密码',
                            subtitle: '更改登录密码',
                            onTap: () {
                              _showChangePasswordDialog();
                            },
                          ),
                          _buildMenuItem(
                            icon: Icons.security_outlined,
                            title: '账号安全',
                            subtitle: '绑定手机、邮箱等',
                            onTap: () {
                              // TODO: 打开账号安全
                            },
                          ),
                          _buildMenuItem(
                            icon: Icons.person_remove_outlined,
                            title: '注销账号',
                            subtitle: '永久删除账号和所有数据',
                            onTap: () {
                              _showAccountDeletionDialog();
                            },
                            isDestructive: true,
                          ),
                        ]),
                        const SizedBox(height: 24),

                        // 偏好设置
                        _buildSectionHeader('偏好设置'),
                        const SizedBox(height: 12),
                        _buildSettingsCard([
                          _buildSwitchItem(
                            icon: Icons.notifications_outlined,
                            title: '推送通知',
                            subtitle: '接收简历相关通知',
                            value: _notificationsEnabled,
                            onChanged: (value) {
                              setState(() {
                                _notificationsEnabled = value;
                              });
                            },
                          ),
                          _buildSwitchItem(
                            icon: Icons.email_outlined,
                            title: '邮件通知',
                            subtitle: '接收邮件提醒',
                            value: _emailNotificationsEnabled,
                            onChanged: (value) {
                              setState(() {
                                _emailNotificationsEnabled = value;
                              });
                            },
                          ),
                          _buildSwitchItem(
                            icon: Icons.dark_mode_outlined,
                            title: '深色模式',
                            subtitle: '使用深色主题',
                            value: _darkModeEnabled,
                            onChanged: (value) {
                              setState(() {
                                _darkModeEnabled = value;
                              });
                            },
                          ),
                          _buildSwitchItem(
                            icon: Icons.save_outlined,
                            title: '自动保存',
                            subtitle: '编辑时自动保存简历',
                            value: _autoSaveEnabled,
                            onChanged: (value) {
                              setState(() {
                                _autoSaveEnabled = value;
                              });
                            },
                          ),
                        ]),
                        const SizedBox(height: 24),

                        // 通用设置
                        _buildSectionHeader('通用'),
                        const SizedBox(height: 12),
                        _buildSettingsCard([
                          _buildSelectorItem(
                            icon: Icons.language_outlined,
                            title: '语言',
                            subtitle: '选择应用语言',
                            value: _language,
                            options: const {
                              'zh-CN': '简体中文',
                              'zh-TW': '繁體中文',
                              'en': 'English',
                            },
                            onChanged: (value) {
                              setState(() {
                                _language = value;
                              });
                            },
                          ),
                          _buildSelectorItem(
                            icon: Icons.text_fields_outlined,
                            title: '字体大小',
                            subtitle: '调整界面文字大小',
                            value: _fontSize,
                            options: const {
                              'small': '小',
                              'medium': '中',
                              'large': '大',
                            },
                            onChanged: (value) {
                              setState(() {
                                _fontSize = value;
                              });
                            },
                          ),
                          _buildMenuItem(
                            icon: Icons.cleaning_services_outlined,
                            title: '清除缓存',
                            subtitle: '释放存储空间',
                            onTap: () {
                              _showClearCacheDialog();
                            },
                          ),
                        ]),
                        const SizedBox(height: 24),

                        // 关于
                        _buildSectionHeader('关于'),
                        const SizedBox(height: 12),
                        _buildSettingsCard([
                          _buildMenuItem(
                            icon: Icons.info_outline,
                            title: '关于我们',
                            subtitle: '版本 1.0.0',
                            onTap: () {
                              _showAboutDialog();
                            },
                          ),
                          _buildMenuItem(
                            icon: Icons.description_outlined,
                            title: '用户协议',
                            subtitle: '查看服务条款',
                            onTap: () {
                              // TODO: 打开用户协议
                            },
                          ),
                          _buildMenuItem(
                            icon: Icons.privacy_tip_outlined,
                            title: '隐私政策',
                            subtitle: '了解隐私保护',
                            onTap: () {
                              // TODO: 打开隐私政策
                            },
                          ),
                          _buildMenuItem(
                            icon: Icons.contact_support_outlined,
                            title: '联系客服',
                            subtitle: '获取帮助支持',
                            onTap: () {
                              // TODO: 打开客服
                            },
                          ),
                        ]),
                        const SizedBox(height: 24),

                        // 退出登录和注销账号按钮
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => _showLogoutDialog(),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: ThemeConfig.error,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 32,
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  side: BorderSide(
                                    color: ThemeConfig.error.withOpacity(0.5),
                                  ),
                                ),
                                child: const Text('退出登录'),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () => _showAccountDeletionDialog(),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red.shade900.withOpacity(0.3),
                                  foregroundColor: Colors.red.shade300,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 32,
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  side: BorderSide(
                                    color: Colors.red.shade700.withOpacity(0.5),
                                  ),
                                ),
                                child: const Text('注销账号'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
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

  /// 区块标题
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Text(
        title,
        style: ThemeConfig.bodyMedium.copyWith(
          color: Colors.white70,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  /// 设置卡片容器
  Widget _buildSettingsCard(List<Widget> children) {
    return Container(
      decoration: ThemeConfig.glassDecoration,
      child: Column(
        children: List.generate(
          children.length,
          (index) => Column(
            children: [
              if (index > 0)
                Divider(
                  height: 1,
                  color: Colors.white.withOpacity(0.1),
                  indent: 60,
                ),
              children[index],
            ],
          ),
        ),
      ),
    );
  }

  /// 普通菜单项
  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
    bool isDestructive = false,
  }) {
    final iconColor = isDestructive ? Colors.red.shade400 : ThemeConfig.primary;
    final iconBgColor = isDestructive
        ? Colors.red.shade900.withOpacity(0.3)
        : ThemeConfig.primary.withOpacity(0.2);
    final titleColor = isDestructive ? Colors.red.shade300 : Colors.white;

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
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: ThemeConfig.bodyMedium.copyWith(
                        color: titleColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: ThemeConfig.bodySmall.copyWith(
                        color: Colors.white.withOpacity(0.5),
                      ),
                    ),
                  ],
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

  /// 开关菜单项
  Widget _buildSwitchItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 12,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: ThemeConfig.primary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: ThemeConfig.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: ThemeConfig.bodyMedium.copyWith(
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: ThemeConfig.bodySmall.copyWith(
                    color: Colors.white.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: ThemeConfig.primary,
            activeTrackColor: ThemeConfig.primary.withOpacity(0.5),
          ),
        ],
      ),
    );
  }

  /// 选择器菜单项
  Widget _buildSelectorItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required String value,
    required Map<String, String> options,
    required ValueChanged<String> onChanged,
  }) {
    return InkWell(
      onTap: () => _showSelectorDialog(
        title: title,
        options: options,
        value: value,
        onChanged: onChanged,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: ThemeConfig.primary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: ThemeConfig.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: ThemeConfig.bodyMedium.copyWith(
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: ThemeConfig.bodySmall.copyWith(
                      color: Colors.white.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    options[value] ?? value,
                    style: ThemeConfig.bodySmall.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.expand_more,
                    color: Colors.white.withOpacity(0.5),
                    size: 16,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 显示选择器对话框
  void _showSelectorDialog({
    required String title,
    required Map<String, String> options,
    required String value,
    required ValueChanged<String> onChanged,
  }) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                ThemeConfig.cardBg,
                ThemeConfig.darkBg,
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: ThemeConfig.heading3.copyWith(
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              ...options.entries.map((entry) {
                final isSelected = entry.key == value;
                return InkWell(
                  onTap: () {
                    onChanged(entry.key);
                    Navigator.of(context).pop();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? ThemeConfig.primary.withOpacity(0.2)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? ThemeConfig.primary
                            : Colors.transparent,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            entry.value,
                            style: ThemeConfig.bodyMedium.copyWith(
                              color: isSelected
                                  ? ThemeConfig.primary
                                  : Colors.white70,
                            ),
                          ),
                        ),
                        if (isSelected)
                          Icon(
                            Icons.check,
                            color: ThemeConfig.primary,
                            size: 20,
                          ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ],
          ),
        ),
      ),
    );
  }

  /// 显示修改密码对话框
  void _showChangePasswordDialog() {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  ThemeConfig.cardBg,
                  ThemeConfig.darkBg,
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '修改密码',
                  style: ThemeConfig.heading3.copyWith(
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: oldPasswordController,
                  obscureText: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: '当前密码',
                    labelStyle: const TextStyle(color: Colors.white54),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: ThemeConfig.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: newPasswordController,
                  obscureText: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: '新密码',
                    labelStyle: const TextStyle(color: Colors.white54),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: ThemeConfig.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: confirmPasswordController,
                  obscureText: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: '确认新密码',
                    labelStyle: const TextStyle(color: Colors.white54),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: ThemeConfig.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('取消'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: isLoading
                            ? null
                            : () async {
                                if (oldPasswordController.text.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('请输入当前密码'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                  return;
                                }
                                if (newPasswordController.text.length < 6) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('新密码至少6位'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                  return;
                                }
                                if (newPasswordController.text !=
                                    confirmPasswordController.text) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('两次密码不一致'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                  return;
                                }

                                setDialogState(() {
                                  isLoading = true;
                                });

                                try {
                                  await ref
                                      .read(authProvider.notifier)
                                      .changePassword(
                                        oldPassword:
                                            oldPasswordController.text,
                                        newPassword:
                                            newPasswordController.text,
                                      );

                                  if (context.mounted) {
                                    Navigator.of(context).pop();
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(
                                      const SnackBar(
                                        content: Text('密码修改成功'),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  setDialogState(() {
                                    isLoading = false;
                                  });
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(
                                      SnackBar(
                                        content: Text(e.toString()),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ThemeConfig.primary,
                        ),
                        child: isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Text('确认'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 显示清除缓存对话框
  void _showClearCacheDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                ThemeConfig.cardBg,
                ThemeConfig.darkBg,
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.cleaning_services,
                  color: Colors.orange,
                  size: 30,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '清除缓存',
                style: ThemeConfig.heading3.copyWith(
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '清除后将释放约 128 MB 空间\n已缓存的模板和图片需要重新下载',
                style: ThemeConfig.bodyMedium.copyWith(
                  color: Colors.white60,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('取消'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('缓存已清除'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                      ),
                      child: const Text('确认清除'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 显示关于对话框
  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
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
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: ThemeConfig.primary.withOpacity(0.3),
              width: 2,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Logo
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: ThemeConfig.primaryGradient,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: ThemeConfig.neonShadow,
                ),
                child: const Icon(
                  Icons.description_outlined,
                  color: Colors.white,
                  size: 40,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'AI 简历',
                style: ThemeConfig.heading2.copyWith(
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '版本 1.0.0',
                style: ThemeConfig.bodyMedium.copyWith(
                  color: Colors.white.withOpacity(0.5),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Build 20240207',
                style: ThemeConfig.bodySmall.copyWith(
                  color: Colors.white30,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                '一款基于AI技术的智能简历生成工具\n让求职更简单',
                style: ThemeConfig.bodyMedium.copyWith(
                  color: Colors.white60,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ThemeConfig.primary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 48,
                    vertical: 12,
                  ),
                ),
                child: const Text('关闭'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 显示退出登录确认对话框
  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                ThemeConfig.cardBg,
                ThemeConfig.darkBg,
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: ThemeConfig.error.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.logout,
                  color: ThemeConfig.error,
                  size: 30,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '退出登录',
                style: ThemeConfig.heading3.copyWith(
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '确定要退出当前账号吗？',
                style: ThemeConfig.bodyMedium.copyWith(
                  color: Colors.white60,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('取消'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        final notifier = ref.read(authProvider.notifier);
                        await notifier.logout();
                        if (context.mounted) {
                          Navigator.of(context).pop();
                          context.go(RouteConstants.login);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ThemeConfig.error,
                      ),
                      child: const Text('确认退出'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 显示注销账号确认对话框
  void _showAccountDeletionDialog() {
    // 第一步：警告对话框
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.red.shade900.withOpacity(0.3),
                ThemeConfig.darkBg,
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.red.shade700.withOpacity(0.5),
              width: 2,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 警告图标
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: Colors.red.shade900.withOpacity(0.4),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.red.shade600,
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.warning_rounded,
                  color: Colors.red,
                  size: 40,
                ),
              ),
              const SizedBox(height: 20),

              // 标题
              Text(
                '⚠️ 警告：此操作不可恢复',
                style: ThemeConfig.heading3.copyWith(
                  color: Colors.red.shade300,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // 警告内容
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade900.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.red.shade700.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildWarningItem('永久删除您的账号和所有个人信息'),
                    _buildWarningItem('删除所有简历、模板和创作记录'),
                    _buildWarningItem('VIP会员权益将立即终止'),
                    _buildWarningItem('此操作无法撤销，请谨慎考虑'),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 数据保留说明
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade900.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.blue.shade700.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.blue.shade300,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '根据法律规定，您的数据将在注销后保留30天，之后将被永久删除',
                        style: ThemeConfig.bodySmall.copyWith(
                          color: Colors.blue.shade200,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 按钮
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white70,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('我再想想'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _showAccountDeletionReasonDialog();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade800,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('我已了解，继续'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建警告项
  Widget _buildWarningItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 2),
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: ThemeConfig.bodySmall.copyWith(
                color: Colors.white70,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 显示注销原因选择对话框
  void _showAccountDeletionReasonDialog() {
    String? selectedReason;
    final customReasonController = TextEditingController();
    bool _exportData = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  ThemeConfig.cardBg,
                  ThemeConfig.darkBg,
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
              ),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '请告诉我们您为什么想注销账号',
                    style: ThemeConfig.heading3.copyWith(
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 注销原因选项
                  ...[
                    '功能不符合需求',
                    '找到了更好的替代产品',
                    '隐私顾虑',
                    '使用体验不佳',
                    '暂时不需要',
                    '其他原因',
                  ].map((reason) => InkWell(
                        onTap: () {
                          setDialogState(() {
                            selectedReason = reason;
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: selectedReason == reason
                                ? ThemeConfig.primary.withOpacity(0.3)
                                : Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: selectedReason == reason
                                  ? ThemeConfig.primary
                                  : Colors.white.withOpacity(0.1),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                selectedReason == reason
                                    ? Icons.radio_button_checked
                                    : Icons.radio_button_unchecked,
                                color: selectedReason == reason
                                    ? ThemeConfig.primary
                                    : Colors.white54,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  reason,
                                  style: ThemeConfig.bodyMedium.copyWith(
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )),

                  // 自定义原因输入框
                  if (selectedReason == '其他原因') ...[
                    const SizedBox(height: 8),
                    TextField(
                      controller: customReasonController,
                      maxLines: 3,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: '请告诉我们您的具体原因...',
                        hintStyle: const TextStyle(color: Colors.white38),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.05),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Colors.white.withOpacity(0.1),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: ThemeConfig.primary,
                          ),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),

                  // 数据导出选项
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade900.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.blue.shade700.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.download_outlined,
                          color: Colors.blue.shade300,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '导出我的数据',
                                style: ThemeConfig.bodyMedium.copyWith(
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                '在删除前获取您所有数据的副本',
                                style: ThemeConfig.bodySmall.copyWith(
                                  color: Colors.white60,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _exportData,
                          onChanged: (value) {
                            setDialogState(() {
                              _exportData = value;
                            });
                          },
                          activeColor: Colors.blue.shade400,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 按钮
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('取消'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: selectedReason == null
                              ? null
                              : () {
                                  Navigator.of(context).pop();
                                  _showAccountDeletionConfirmDialog(
                                    reason: selectedReason == '其他原因'
                                        ? (customReasonController.text.isEmpty
                                            ? '用户未提供具体原因'
                                            : customReasonController.text)
                                        : selectedReason!,
                                    exportData: _exportData,
                                  );
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade800,
                          ),
                          child: const Text('下一步'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 显示最终确认对话框
  void _showAccountDeletionConfirmDialog({
    required String reason,
    required bool exportData,
  }) {
    final passwordController = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.red.shade900.withOpacity(0.3),
                  ThemeConfig.darkBg,
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.red.shade700.withOpacity(0.5),
                width: 2,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.password_rounded,
                  color: Colors.red,
                  size: 50,
                ),
                const SizedBox(height: 16),

                Text(
                  '最后一步：确认您的身份',
                  style: ThemeConfig.heading3.copyWith(
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    '为了保护您的账号安全，请输入您的登录密码以确认注销操作。',
                    style: ThemeConfig.bodyMedium.copyWith(
                      color: Colors.white70,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                const SizedBox(height: 20),

                // 密码输入框
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: '登录密码',
                    labelStyle: const TextStyle(color: Colors.white54),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Colors.red,
                      ),
                    ),
                  ),
                ),

                if (exportData) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade900.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.blue.shade300,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '您的数据将在注销后发送到您的注册邮箱',
                            style: ThemeConfig.bodySmall.copyWith(
                              color: Colors.blue.shade200,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // 按钮
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white70,
                        ),
                        child: const Text('取消'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: isLoading
                            ? null
                            : () async {
                                if (passwordController.text.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('请输入密码'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                  return;
                                }

                                setDialogState(() {
                                  isLoading = true;
                                });

                                try {
                                  // 调用注销API
                                  final deletionDays = await ref
                                      .read(authProvider.notifier)
                                      .requestAccountDeletion(
                                        reason: reason,
                                        exportData: exportData,
                                        password: passwordController.text,
                                      );

                                  if (context.mounted) {
                                    Navigator.of(context).pop();

                                    if (deletionDays != null) {
                                      _showAccountDeletionSuccessDialog(
                                        exportData: exportData,
                                        deletionDays: deletionDays,
                                      );
                                    } else {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text('密码错误，请重试'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  }
                                } catch (e) {
                                  setDialogState(() {
                                    isLoading = false;
                                  });
                                  if (context.mounted) {
                                    Navigator.of(context).pop();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('操作失败: $e'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade800,
                        ),
                        child: isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Text('确认注销'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 显示注销成功对话框
  void _showAccountDeletionSuccessDialog({
    required bool exportData,
    int deletionDays = 30,
  }) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.orange.shade900.withOpacity(0.3),
                ThemeConfig.darkBg,
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.orange.shade700.withOpacity(0.5),
              width: 2,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: Colors.orange.shade900.withOpacity(0.4),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.schedule_send_rounded,
                  color: Colors.orange,
                  size: 40,
                ),
              ),
              const SizedBox(height: 20),

              Text(
                '注销请求已提交',
                style: ThemeConfig.heading3.copyWith(
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoItem(
                      Icons.calendar_today,
                      '$deletionDays天冷静期',
                      '您的账号将在$deletionDays天后被永久删除',
                    ),
                    const Divider(height: 24, color: Colors.white10),
                    _buildInfoItem(
                      Icons.email_outlined,
                      '确认邮件已发送',
                      '我们已向您的邮箱发送了确认邮件',
                    ),
                    const Divider(height: 24, color: Colors.white10),
                    _buildInfoItem(
                      Icons.refresh_outlined,
                      '可以随时撤销',
                      '在$deletionDays天内您可以随时登录取消注销',
                    ),
                    if (exportData) ...[
                      const Divider(height: 24, color: Colors.white10),
                      _buildInfoItem(
                        Icons.download_done,
                        '数据导出处理中',
                        '您的数据将在24小时内发送到邮箱',
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  // 退出登录
                  final notifier = ref.read(authProvider.notifier);
                  await notifier.logout();
                  if (context.mounted) {
                    context.go(RouteConstants.login);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: ThemeConfig.primary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 48,
                    vertical: 14,
                  ),
                ),
                child: const Text('我知道了'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建信息项
  Widget _buildInfoItem(IconData icon, String title, String subtitle) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: ThemeConfig.primary.withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: ThemeConfig.primary,
            size: 20,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: ThemeConfig.bodyMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: ThemeConfig.bodySmall.copyWith(
                  color: Colors.white60,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
