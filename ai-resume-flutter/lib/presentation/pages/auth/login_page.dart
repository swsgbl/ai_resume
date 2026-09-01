import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/config/theme_config.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/storage_constants.dart';
import '../../../core/storage/storage_service.dart';
import '../../providers/auth_provider.dart';
import '../../routes/app_router.dart';

/// 登录页面
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberPassword = false;
  final _storageService = StorageService();

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  /// 加载保存的凭据
  Future<void> _loadSavedCredentials() async {
    final remember = await _storageService.getBool(StorageConstants.keyRememberPassword);
    if (remember == true) {
      final email = await _storageService.getString(StorageConstants.keySavedEmail);
      final password = await _storageService.getSecureString(StorageConstants.keySavedPassword);
      if (mounted) {
        setState(() {
          _rememberPassword = true;
          if (email != null) {
            _emailController.text = email;
          }
          if (password != null) {
            _passwordController.text = password;
          }
        });
      }
    }
  }

  /// 保存凭据
  Future<void> _saveCredentials() async {
    if (_rememberPassword) {
      await _storageService.setBool(StorageConstants.keyRememberPassword, true);
      await _storageService.setString(StorageConstants.keySavedEmail, _emailController.text.trim());
      await _storageService.setSecureString(StorageConstants.keySavedPassword, _passwordController.text);
    } else {
      // 取消记住密码时清除保存的凭据
      await _storageService.setBool(StorageConstants.keyRememberPassword, false);
      await _storageService.remove(StorageConstants.keySavedEmail);
      await _storageService.removeSecureString(StorageConstants.keySavedPassword);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final authNotifier = ref.read(authProvider.notifier);

    try {
      await authNotifier.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      // 登录成功后保存凭据
      await _saveCredentials();

      if (mounted) {
        // 登录成功，导航到首页
        context.go(RouteConstants.home);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll("Exception: ", "")),
            backgroundColor: ThemeConfig.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

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
                constraints: const BoxConstraints(maxWidth: 400),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Logo区域
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
                          size: 40,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // 标题
                      Text(
                        '欢迎回来',
                        style: ThemeConfig.heading2.copyWith(
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),

                      Text(
                        '登录以继续创建你的专业简历',
                        style: ThemeConfig.bodyMedium.copyWith(
                          color: Colors.white70,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 48),

                      // 登录表单卡片
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: ThemeConfig.glassDecoration,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              '账户登录',
                              style: ThemeConfig.heading3,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '输入你的账户信息',
                              style: ThemeConfig.bodySmall,
                            ),
                            const SizedBox(height: 24),

                            // 邮箱输入框
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                labelText: '邮箱地址',
                                hintText: 'your@email.com',
                                prefixIcon: const Icon(
                                  Icons.email_outlined,
                                  color: ThemeConfig.textSecondary,
                                ),
                                labelStyle: const TextStyle(
                                  color: ThemeConfig.textSecondary,
                                ),
                                hintStyle: const TextStyle(
                                  color: ThemeConfig.textTertiary,
                                ),
                                filled: true,
                                fillColor: Colors.white.withOpacity(0.05),
                                border: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(ThemeConfig.inputRadius),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(ThemeConfig.inputRadius),
                                  borderSide: BorderSide(
                                    color: Colors.white.withOpacity(0.1),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(ThemeConfig.inputRadius),
                                  borderSide: const BorderSide(
                                    color: ThemeConfig.primary,
                                    width: 2,
                                  ),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(ThemeConfig.inputRadius),
                                  borderSide: const BorderSide(
                                    color: ThemeConfig.error,
                                    width: 1,
                                  ),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return '请输入邮箱地址';
                                }
                                if (!RegExp(RegexConstants.email).hasMatch(value)) {
                                  return '请输入有效的邮箱地址';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // 密码输入框
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                labelText: '密码',
                                hintText: '•••••••••',
                                prefixIcon: const Icon(
                                  Icons.lock_outlined,
                                  color: ThemeConfig.textSecondary,
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                    color: ThemeConfig.textSecondary,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                                labelStyle: const TextStyle(
                                  color: ThemeConfig.textSecondary,
                                ),
                                hintStyle: const TextStyle(
                                  color: ThemeConfig.textTertiary,
                                ),
                                filled: true,
                                fillColor: Colors.white.withOpacity(0.05),
                                border: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(ThemeConfig.inputRadius),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(ThemeConfig.inputRadius),
                                  borderSide: BorderSide(
                                    color: Colors.white.withOpacity(0.1),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(ThemeConfig.inputRadius),
                                  borderSide: const BorderSide(
                                    color: ThemeConfig.primary,
                                    width: 2,
                                  ),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return '请输入密码';
                                }
                                if (value.length < 6) {
                                  return '密码至少6位';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),

                            // 记住密码
                            Row(
                              children: [
                                SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: Checkbox(
                                    value: _rememberPassword,
                                    onChanged: (value) {
                                      setState(() {
                                        _rememberPassword = value ?? false;
                                      });
                                    },
                                    fillColor: WidgetStateProperty.resolveWith((states) {
                                      if (states.contains(WidgetState.selected)) {
                                        return ThemeConfig.primary;
                                      }
                                      return Colors.white.withOpacity(0.1);
                                    }),
                                    side: BorderSide(
                                      color: _rememberPassword
                                          ? ThemeConfig.primary
                                          : Colors.white.withOpacity(0.3),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '记住密码',
                                  style: ThemeConfig.bodySmall.copyWith(
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // 错误提示
                            if (authState.error != null)
                              Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: ThemeConfig.errorBackground,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: ThemeConfig.error.withOpacity(0.5),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.error_outline,
                                      color: ThemeConfig.error,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        authState.error!,
                                        style: ThemeConfig.bodySmall.copyWith(
                                          color: ThemeConfig.error,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                            // 登录按钮
                            SizedBox(
                              height: 48,
                              child: ElevatedButton(
                                onPressed:
                                    authState.isLoading ? null : _handleLogin,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: ThemeConfig.primary,
                                  foregroundColor: Colors.white,
                                  disabledBackgroundColor:
                                      Colors.grey.shade700,
                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(ThemeConfig.buttonRadius),
                                  ),
                                  elevation: 0,
                                ),
                                child: authState.isLoading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                      )
                                    : const Text(
                                        '登录',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // 注册链接
                      TextButton(
                        onPressed: () => context.go(RouteConstants.register),
                        child: Text(
                          '还没有账号？立即注册',
                          style: ThemeConfig.bodyMedium.copyWith(
                            color: Colors.white,
                          ),
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
}
