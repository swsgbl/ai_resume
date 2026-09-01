import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/config/app_config.dart';
import '../../core/config/theme_config.dart';
import '../../core/constants/storage_constants.dart';
import '../providers/auth_provider.dart';
import '../pages/auth/login_page.dart';
import '../pages/auth/register_page.dart';
import '../pages/home/home_page.dart';
import '../pages/resume/resume_list_page.dart';
import '../pages/resume/resume_editor_page.dart';
import '../pages/template/templates_page.dart';
import '../pages/profile/profile_page.dart';
import '../pages/settings/settings_page.dart';
import '../pages/ai/ai_generate_page.dart';

/// 路由常量
class RouteConstants {
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String resumes = '/resumes';
  static const String resumeDetail = '/resumes/:id';
  static const String resumeNew = '/resumes/new';
  static const String templates = '/templates';
  static const String profile = '/profile';
  static const String settings = '/settings';
  static const String aiGenerate = '/ai/generate';

  // 带参数的路径生成器
  static String resumeDetailPath(String id) => '/resumes/$id';
}

/// GoRouter配置Provider
final routerProvider = Provider<GoRouter>((ref) {
  // 直接从authProvider读取认证状态
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: RouteConstants.home,
    debugLogDiagnostics: AppConfig.isDebug,
    redirect: (BuildContext context, GoRouterState state) {
      // 路由守卫逻辑
      final isAuthenticated = authState.isAuthenticated;
      final isLoginRoute = state.matchedLocation == RouteConstants.login ||
          state.matchedLocation == RouteConstants.register;

      // 如果未认证且不在登录页面，重定向到登录页
      if (!isAuthenticated && !isLoginRoute) {
        return RouteConstants.login;
      }

      // 如果已认证且在登录页面，重定向到首页
      if (isAuthenticated && isLoginRoute) {
        return RouteConstants.home;
      }

      return null;
    },
    routes: [
      // 登录页面
      GoRoute(
        path: RouteConstants.login,
        name: 'login',
        pageBuilder: (context, state) => MaterialPage(
              key: state.pageKey,
              child: const LoginPage(),
            ),
      ),

      // 注册页面
      GoRoute(
        path: RouteConstants.register,
        name: 'register',
        pageBuilder: (context, state) => MaterialPage(
              key: state.pageKey,
              child: const RegisterPage(),
            ),
      ),

      // 首页
      GoRoute(
        path: RouteConstants.home,
        name: 'home',
        pageBuilder: (context, state) => MaterialPage(
              key: state.pageKey,
              child: const HomePage(),
            ),
      ),

      // 简历列表
      GoRoute(
        path: RouteConstants.resumes,
        name: 'resumes',
        pageBuilder: (context, state) => MaterialPage(
              key: state.pageKey,
              child: const ResumeListPage(),
            ),
      ),

      // 简历编辑器（新建）
      GoRoute(
        path: RouteConstants.resumeNew,
        name: 'resume_new',
        pageBuilder: (context, state) => const MaterialPage(
              key: ValueKey('resume_new'),
              child: ResumeEditorPage(),
            ),
      ),

      // 简历编辑器（编辑）
      GoRoute(
        path: RouteConstants.resumeDetail,
        name: 'resume_detail',
        pageBuilder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return MaterialPage(
            key: ValueKey('resume_$id'),
            child: ResumeEditorPage(resumeId: id),
          );
        },
      ),

      // 模板库
      GoRoute(
        path: RouteConstants.templates,
        name: 'templates',
        pageBuilder: (context, state) => MaterialPage(
              key: state.pageKey,
              child: const TemplatesPage(),
            ),
      ),

      // 个人中心
      GoRoute(
        path: RouteConstants.profile,
        name: 'profile',
        pageBuilder: (context, state) => MaterialPage(
              key: state.pageKey,
              child: const ProfilePage(),
            ),
      ),

      // 设置
      GoRoute(
        path: RouteConstants.settings,
        name: 'settings',
        pageBuilder: (context, state) => MaterialPage(
              key: state.pageKey,
              child: const SettingsPage(),
            ),
      ),

      // AI生成简历
      GoRoute(
        path: RouteConstants.aiGenerate,
        name: 'ai_generate',
        pageBuilder: (context, state) => MaterialPage(
              key: state.pageKey,
              child: const AIGeneratePage(),
            ),
      ),
    ],

    // 错误页面
    errorPageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '页面未找到',
                    style: ThemeConfig.heading2,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${state.error}',
                    style: ThemeConfig.bodyMedium,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => context.go(RouteConstants.home),
                    child: const Text('返回首页'),
                  ),
                ],
              ),
            ),
          ),
        ),
  );
});
