import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/config/theme_config.dart';
import 'core/storage/storage_service.dart';
import 'presentation/routes/app_router.dart';

/// AI Resume 应用入口
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化存储服务
  await StorageService().initialize();

  runApp(const ProviderScope(child: AiResumeApp()));
}

/// AI Resume 应用根组件
class AiResumeApp extends ConsumerWidget {
  const AiResumeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'AI Resume',
      debugShowCheckedModeBanner: false,
      theme: ThemeConfig.lightTheme,
      darkTheme: ThemeConfig.darkTheme,
      themeMode: ThemeMode.dark, // 默认使用暗色主题（赛博朋克风格）
      routerConfig: router,
    );
  }
}
