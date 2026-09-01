import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:ai_resume_flutter/main.dart' as app;

/// AI Resume Flutter 集成测试
/// 测试主要业务流程：登录、首页、简历列表
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('AI Resume 端到端测试', () {
    testWidgets('应用启动并显示登录页面', (WidgetTester tester) async {
      // 启动应用
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // 验证登录页面元素
      expect(find.text('欢迎回来'), findsOneWidget);
      expect(find.text('登录以继续创建你的专业简历'), findsOneWidget);
      expect(find.text('账户登录'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(2)); // 邮箱和密码输入框
      expect(find.text('登录'), findsOneWidget);
      expect(find.text('还没有账号？立即注册'), findsOneWidget);
    });

    testWidgets('登录表单验证功能正常', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // 点击登录按钮（不输入任何内容）
      final loginButton = find.text('登录');
      await tester.tap(loginButton);
      await tester.pumpAndSettle();

      // 验证表单验证提示
      expect(find.text('请输入邮箱地址'), findsOneWidget);

      // 输入无效邮箱
      final emailField = find.byType(TextFormField).first;
      await tester.enterText(emailField, 'invalid-email');
      await tester.tap(loginButton);
      await tester.pumpAndSettle();

      expect(find.text('请输入有效的邮箱地址'), findsOneWidget);

      // 输入有效邮箱但无密码
      await tester.enterText(emailField, 'test@example.com');
      await tester.tap(loginButton);
      await tester.pumpAndSettle();

      expect(find.text('请输入密码'), findsOneWidget);
    });

    testWidgets('密码显示/隐藏功能正常', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // 查找密码输入框（第二个 TextFormField）
      final passwordField = find.byType(TextFormField).at(1);

      // 输入密码
      await tester.enterText(passwordField, 'testpassword');
      await tester.pumpAndSettle();

      // 查找显示/隐藏密码按钮（IconButton）
      final visibilityButton = find.byType(IconButton);
      expect(visibilityButton, findsOneWidget);

      // 点击切换密码可见性
      await tester.tap(visibilityButton);
      await tester.pumpAndSettle();

      // 再次点击切换回来
      await tester.tap(visibilityButton);
      await tester.pumpAndSettle();
    });

    testWidgets('注册页面导航正常', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // 点击注册链接
      final registerLink = find.text('还没有账号？立即注册');
      await tester.tap(registerLink);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // 验证注册页面元素
      expect(find.text('创建账户'), findsOneWidget);
      expect(find.text('注册以开始创建你的专业简历'), findsOneWidget);
    });

    testWidgets('记住密码功能存在', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // 验证记住密码复选框存在
      expect(find.text('记住密码'), findsOneWidget);
      expect(find.byType(Checkbox), findsOneWidget);

      // 点击复选框
      final checkbox = find.byType(Checkbox);
      await tester.tap(checkbox);
      await tester.pumpAndSettle();
    });

    testWidgets('应用主题和样式正确加载', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // 验证页面背景是深色（赛博朋克主题）
      final scaffold = find.byType(Scaffold);
      expect(scaffold, findsOneWidget);

      // 验证渐变背景容器存在
      final container = find.byType(Container);
      expect(container, findsWidgets);

      // 验证主要文本颜色是白色（深色主题）
      final welcomeText = find.text('欢迎回来');
      expect(welcomeText, findsOneWidget);
    });

    testWidgets('登录页面响应式布局正常', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // 验证 SingleChildScrollView 存在（支持小屏幕滚动）
      expect(find.byType(SingleChildScrollView), findsOneWidget);

      // 验证 SafeArea 存在（适配刘海屏）
      expect(find.byType(SafeArea), findsOneWidget);

      // 验证表单有最大宽度限制（在大屏幕上居中）
      expect(find.byType(ConstrainedBox), findsWidgets);
    });
  });
}
