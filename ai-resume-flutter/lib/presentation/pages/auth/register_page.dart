import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';
import '../../../core/config/theme_config.dart';
import '../../../core/config/app_config.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/storage_constants.dart';
import '../../../core/storage/storage_service.dart';
import '../../providers/auth_provider.dart';
import '../../routes/app_router.dart';
import '../../widgets/common/doc_viewer.dart';

/// 注册页面
class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nicknameController = TextEditingController();
  final _codeController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreeToTerms = false;
  bool _agreeToAgeConfirmation = false;

  // 验证码倒计时
  int _countdown = 0;
  Timer? _countdownTimer;
  bool _isSendingCode = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nicknameController.dispose();
    _codeController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  /// 发送验证码
  Future<void> _handleSendCode() async {
    // 验证邮箱格式
    if (_emailController.text.isEmpty) {
      _showError('请先输入邮箱地址');
      return;
    }

    if (!RegExp(RegexConstants.email).hasMatch(_emailController.text)) {
      _showError('请输入有效的邮箱地址');
      return;
    }

    setState(() {
      _isSendingCode = true;
    });

    try {
      final authNotifier = ref.read(authProvider.notifier);
      await authNotifier.sendVerificationCode(_emailController.text.trim());

      if (mounted) {
        _showSuccess('验证码已发送');
        _startCountdown();
      }
    } catch (e) {
      if (mounted) {
        _showError(e.toString().replaceAll('Exception: ', ''));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSendingCode = false;
        });
      }
    }
  }

  /// 开始倒计时
  void _startCountdown() {
    setState(() {
      _countdown = 60;
    });

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 0) {
        setState(() {
          _countdown--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  /// 处理注册
  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_agreeToTerms) {
      _showError('请同意服务条款和隐私政策');
      return;
    }

    if (!_agreeToAgeConfirmation) {
      _showError('请确认您已年满${AgeConstants.minimumAge}周岁');
      return;
    }

    final authNotifier = ref.read(authProvider.notifier);

    try {
      await authNotifier.register(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        nickname: _nicknameController.text.trim(),
        code: _codeController.text.trim(),
      );

      if (mounted) {
        // 注册成功，导航到首页
        context.go(RouteConstants.home);
      }
    } catch (e) {
      if (mounted) {
        _showError(e.toString().replaceAll('Exception: ', ''));
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

  /// 显示文档查看器
  void _showDocViewer(String type) {
    String title;
    String assetPath;

    switch (type) {
      case 'terms':
        title = '用户服务协议';
        assetPath = 'assets/docs/terms_of_service.md';
        break;
      case 'privacy':
        title = '隐私政策';
        assetPath = 'assets/docs/privacy_policy.md';
        break;
      default:
        return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => DocViewerPage(
          title: title,
          assetPath: assetPath,
        ),
      ),
    );
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
                        '创建账户',
                        style: ThemeConfig.heading2.copyWith(
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),

                      Text(
                        '注册以开始创建你的专业简历',
                        style: ThemeConfig.bodyMedium.copyWith(
                          color: Colors.white70,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),

                      // 注册表单卡片
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: ThemeConfig.glassDecoration,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
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

                            // 昵称输入框
                            TextFormField(
                              controller: _nicknameController,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                labelText: '昵称',
                                hintText: '请输入昵称',
                                prefixIcon: const Icon(
                                  Icons.person_outlined,
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
                                  return '请输入昵称';
                                }
                                if (value.length < 2) {
                                  return '昵称至少2个字符';
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
                                hintText: '至少6位',
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
                                  return '请输入密码';
                                }
                                if (value.length < 6) {
                                  return '密码至少6位';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // 确认密码输入框
                            TextFormField(
                              controller: _confirmPasswordController,
                              obscureText: _obscureConfirmPassword,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                labelText: '确认密码',
                                hintText: '再次输入密码',
                                prefixIcon: const Icon(
                                  Icons.lock_outlined,
                                  color: ThemeConfig.textSecondary,
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscureConfirmPassword
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                    color: ThemeConfig.textSecondary,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscureConfirmPassword = !_obscureConfirmPassword;
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
                                  return '请确认密码';
                                }
                                if (value != _passwordController.text) {
                                  return '两次输入的密码不一致';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // 验证码输入框
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _codeController,
                                    keyboardType: TextInputType.number,
                                    style: const TextStyle(color: Colors.white),
                                    decoration: InputDecoration(
                                      labelText: '验证码',
                                      hintText: '6位数字',
                                      prefixIcon: const Icon(
                                        Icons.verified_outlined,
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
                                        return '请输入验证码';
                                      }
                                      if (!RegExp(RegexConstants.verifyCode).hasMatch(value)) {
                                        return '请输入6位数字验证码';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                SizedBox(
                                  height: 48,
                                  child: ElevatedButton(
                                    onPressed: _countdown > 0 || _isSendingCode
                                        ? null
                                        : _handleSendCode,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _countdown > 0
                                          ? Colors.grey.shade700
                                          : ThemeConfig.accent,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(ThemeConfig.buttonRadius),
                                      ),
                                      elevation: 0,
                                    ),
                                    child: _isSendingCode
                                        ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(Colors.white),
                                            ),
                                          )
                                        : Text(
                                            _countdown > 0
                                                ? '${_countdown}s'
                                                : '发送验证码',
                                            style: const TextStyle(fontSize: 14),
                                          ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // 服务条款同意
                            Row(
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: Checkbox(
                                    value: _agreeToTerms,
                                    onChanged: (value) {
                                      setState(() {
                                        _agreeToTerms = value ?? false;
                                      });
                                    },
                                    fillColor: WidgetStateProperty.resolveWith(
                                      (states) {
                                        if (states.contains(WidgetState.selected)) {
                                          return ThemeConfig.primary;
                                        }
                                        return Colors.white.withOpacity(0.1);
                                      },
                                    ),
                                    side: BorderSide(
                                      color: _agreeToTerms
                                          ? ThemeConfig.primary
                                          : Colors.white.withOpacity(0.3),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Wrap(
                                    children: [
                                      Text(
                                        '我已阅读并同意',
                                        style: ThemeConfig.bodySmall.copyWith(
                                          color: Colors.white70,
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () => _showDocViewer('terms'),
                                        style: TextButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 4,
                                          ),
                                          minimumSize: Size.zero,
                                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        child: Text(
                                          '服务条款',
                                          style: ThemeConfig.bodySmall.copyWith(
                                            color: ThemeConfig.primary,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        '和',
                                        style: ThemeConfig.bodySmall.copyWith(
                                          color: Colors.white70,
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () => _showDocViewer('privacy'),
                                        style: TextButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 4,
                                          ),
                                          minimumSize: Size.zero,
                                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        child: Text(
                                          '隐私政策',
                                          style: ThemeConfig.bodySmall.copyWith(
                                            color: ThemeConfig.primary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // 年龄确认
                            Row(
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: Checkbox(
                                    value: _agreeToAgeConfirmation,
                                    onChanged: (value) {
                                      setState(() {
                                        _agreeToAgeConfirmation = value ?? false;
                                      });
                                    },
                                    fillColor: WidgetStateProperty.resolveWith(
                                      (states) {
                                        if (states.contains(WidgetState.selected)) {
                                          return ThemeConfig.primary;
                                        }
                                        return Colors.white.withOpacity(0.1);
                                      },
                                    ),
                                    side: BorderSide(
                                      color: _agreeToAgeConfirmation
                                          ? ThemeConfig.primary
                                          : Colors.white.withOpacity(0.3),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Wrap(
                                    children: [
                                      Text(
                                        '我确认已年满',
                                        style: ThemeConfig.bodySmall.copyWith(
                                          color: Colors.white70,
                                        ),
                                      ),
                                      Text(
                                        '${AgeConstants.minimumAge}周岁',
                                        style: ThemeConfig.bodySmall.copyWith(
                                          color: ThemeConfig.primary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        '，并同意相关服务条款',
                                        style: ThemeConfig.bodySmall.copyWith(
                                          color: Colors.white70,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

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

                            // 注册按钮
                            SizedBox(
                              height: 48,
                              child: ElevatedButton(
                                onPressed:
                                    authState.isLoading ? null : _handleRegister,
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
                                        '注册',
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

                      // 登录链接
                      TextButton(
                        onPressed: () => context.go(RouteConstants.login),
                        child: Text(
                          '已有账号？立即登录',
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
