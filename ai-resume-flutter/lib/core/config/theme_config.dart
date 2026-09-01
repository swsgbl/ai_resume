import 'package:flutter/material.dart';

/// 主题配置
///
/// 定义应用的主题样式，采用赛博朋克风格
class ThemeConfig {
  ThemeConfig._();

  /// 主色调 - 蓝色
  static const Color primary = Color(0xFF0EA5E9); // sky-500

  /// 强调色 - 紫色
  static const Color accent = Color(0xFF8B5CF6); // violet-500

  /// 深色背景
  static const Color darkBg = Color(0xFF0F172A); // slate-900

  /// 卡片背景（半透明）
  static const Color cardBg = Color(0x1E293B80); // slate-800/50

  /// 文字颜色
  static const Color textPrimary = Color(0xFFF8FAFC); // slate-50
  static const Color textSecondary = Color(0xFF94A3B8); // slate-400
  static const Color textTertiary = Color(0xFF64748B); // slate-500

  /// 错误色
  static const Color error = Color(0xFFEF4444); // red-500
  static const Color errorBackground = Color(0x1EF444420); // red-500/10

  /// 成功色
  static const Color success = Color(0xFF10B981); // emerald-500

  /// 警告色
  static const Color warning = Color(0xFFF59E0B); // amber-500

  /// 霓虹阴影
  static List<BoxShadow> get neonShadow => [
        BoxShadow(
          color: primary.withOpacity(0.5),
          blurRadius: 20,
          spreadRadius: 0,
          offset: const Offset(0, 0),
        ),
      ];

  static List<BoxShadow> get neonShadowAccent => [
        BoxShadow(
          color: accent.withOpacity(0.5),
          blurRadius: 20,
          spreadRadius: 0,
          offset: const Offset(0, 0),
        ),
      ];

  /// 玻璃态装饰
  static BoxDecoration get glassDecoration => BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            spreadRadius: 0,
          ),
        ],
      );

  /// 霓虹边框装饰
  static BoxDecoration neonBorderDecoration({Color? color}) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: color ?? primary,
        width: 2,
      ),
      boxShadow: [
        BoxShadow(
          color: (color ?? primary).withOpacity(0.3),
          blurRadius: 10,
          spreadRadius: -2,
        ),
      ],
    );
  }

  /// 亮色主题
  static ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.light(
          primary: primary,
          secondary: accent,
          surface: Colors.white,
          error: error,
        ),
        scaffoldBackgroundColor: const Color(0xFFF1F5F9),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: darkBg,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: primary, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: error, width: 1),
          ),
        ),
      );

  /// 暗色主题（赛博朋克风格）
  static ThemeData get darkTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.dark(
          primary: primary,
          secondary: accent,
          surface: darkBg,
          error: error,
        ),
        scaffoldBackgroundColor: darkBg,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: cardBg,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: primary, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: error, width: 1),
          ),
        ),
      );

  /// 文本样式
  static const TextStyle heading1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: textPrimary,
  );

  static const TextStyle heading2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );

  static const TextStyle heading3 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );

  static const TextStyle heading4 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );

  static const TextStyle heading5 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );

  static const TextStyle heading6 = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    color: textPrimary,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    color: textSecondary,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    color: textTertiary,
  );

  /// 渐变色
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, accent],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accent, Color(0xFFEC4899)],
  );

  /// 卡片圆角
  static const double cardRadius = 16;

  /// 按钮圆角
  static const double buttonRadius = 12;

  /// 输入框圆角
  static const double inputRadius = 12;
}
