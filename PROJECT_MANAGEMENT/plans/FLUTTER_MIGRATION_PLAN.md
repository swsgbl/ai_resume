# AI Resume 项目 - Flutter 统一迁移计划

> **文档创建时间**: 2026-02-07
> **项目代号**: Phoenix (从React多端架构重生为Flutter统一架构)
> **目标**: 使用Flutter统一Web、Desktop、Mobile三端代码

---

## 📋 项目概述

### 当前状态
```
┌─────────────────────────────────────────────────────────────┐
│  当前架构 (技术栈分裂)                                        │
├─────────────────────────────────────────────────────────────┤
│  ai-resume-web/      → React + Vite + TailwindCSS           │
│  ai-resume-desktop/  → Tauri + React (复用Web)               │
│  ai-resume-shared/   → TypeScript 共享代码                   │
│  AI-/platform/       → Flutter (完全独立) ❌                 │
└─────────────────────────────────────────────────────────────┘
```

### 目标架构
```
┌─────────────────────────────────────────────────────────────┐
│  目标架构 (Flutter 统一)                                      │
├─────────────────────────────────────────────────────────────┤
│  ┌──────────────────┐                                        │
│  │  Flutter Core    │  (Dart 代码 100% 复用)                 │
│  │  - 业务逻辑       │                                        │
│  │  - 状态管理       │                                        │
│  │  - UI组件        │                                        │
│  │  - API层         │                                        │
│  └──────────────────┘                                        │
│           │                                                 │
│           ├─► Flutter Web    (HTML/Canvas渲染)               │
│           ├─► Flutter Desktop (Windows/Mac/Linux)            │
│           └─► Flutter Mobile   (Android/iOS)                 │
└─────────────────────────────────────────────────────────────┘
```

---

## 🎯 迁移目标

| 项目 | 状态 | 说明 |
|------|------|------|
| 代码复用率 | 95%+ | 三端共享同一套Dart代码 |
| 功能完整性 | 100% | 完全迁移现有所有功能 |
| UI一致性 | 100% | 统一的设计语言 |
| 性能优化 | 提升 | Flutter原生性能优于React Web |

---

## 📊 功能迁移清单

### Phase 1: 基础架构 (Week 1-2)
- [ ] Flutter项目初始化 (支持Web/Desktop/Mobile)
- [ ] 状态管理选型与搭建 (Riverpod)
- [ ] 路由系统搭建 (GoRouter)
- [ ] API层封装 (Dio)
- [ ] 本地存储方案 (shared_preferences/hive)
- [ ] 主题系统搭建 (赛博朋克风格)

### Phase 2: 认证模块 (Week 2-3)
- [ ] 登录页面
- [ ] 注册页面
- [ ] 验证码功能
- [ ] Token管理
- [ ] 路由守卫
- [ ] 自动登录

### Phase 3: 核心页面 (Week 3-4)
- [ ] 首页 (HomePage)
- [ ] 简历列表页 (ResumeListPage)
- [ ] 个人中心 (ProfilePage)
- [ ] 设置页面 (SettingsPage)
- [ ] 导航栏组件

### Phase 4: 简历编辑器 (Week 5-6)
- [ ] 编辑器基础布局
- [ ] 基本信息标签页
- [ ] 教育经历标签页
- [ ] 工作经历标签页
- [ ] 项目经历标签页
- [ ] 技能特长标签页
- [ ] 实时保存功能
- [ ] 表单验证

### Phase 5: AI功能 (Week 6-7)
- [ ] AI生成简历
- [ ] AI优化内容
- [ ] Prompt模板管理
- [ ] 多AI提供商支持

### Phase 6: 模板系统 (Week 7-8)
- [ ] 模板库页面
- [ ] 模板预览
- [ ] 模板应用
- [ ] 模板筛选与搜索

### Phase 7: 高级功能 (Week 8-9)
- [ ] PDF导出
- [ ] Word导出
- [ ] 简历分享
- [ ] 数据导入

### Phase 8: 测试与优化 (Week 9-10)
- [ ] 单元测试
- [ ] Widget测试
- [ ] 集成测试
- [ ] E2E测试
- [ ] 性能优化
- [ ] 打包发布

---

## 🏗️ 技术架构设计

### 目录结构
```
ai-resume-flutter/
├── lib/
│   ├── main.dart                 # 入口文件
│   ├── app.dart                  # App根组件
│   │
│   ├── core/                     # 核心层
│   │   ├── config/               # 配置
│   │   │   ├── app_config.dart
│   │   │   ├── api_config.dart
│   │   │   └── theme_config.dart
│   │   ├── constants/            # 常量
│   │   │   ├── api_constants.dart
│   │   │   ├── storage_constants.dart
│   │   │   └── app_constants.dart
│   │   ├── errors/               # 错误处理
│   │   │   ├── exceptions.dart
│   │   │   └── failures.dart
│   │   ├── network/              # 网络层
│   │   │   ├── api_client.dart
│   │   │   ├── api_interceptors.dart
│   │   │   └── dio_provider.dart
│   │   ├── storage/              # 存储层
│   │   │   ├── storage_service.dart
│   │   │   └── secure_storage.dart
│   │   └── utils/                # 工具类
│   │       ├── date_utils.dart
│   │       ├── validation_utils.dart
│   │       └── logger.dart
│   │
│   ├── data/                     # 数据层
│   │   ├── models/               # 数据模型
│   │   │   ├── user.dart
│   │   │   ├── resume.dart
│   │   │   ├── template.dart
│   │   │   └── education.dart
│   │   ├── repositories/         # 仓库模式
│   │   │   ├── auth_repository.dart
│   │   │   ├── resume_repository.dart
│   │   │   └── template_repository.dart
│   │   └── datasources/          # 数据源
│   │       ├── remote/           # 远程数据源
│   │       │   ├── auth_api.dart
│   │       │   ├── resume_api.dart
│   │       │   └── template_api.dart
│   │       └── local/            # 本地数据源
│   │           ├── auth_local_ds.dart
│   │           └── resume_local_ds.dart
│   │
│   ├── domain/                   # 领域层
│   │   ├── entities/             # 领域实体
│   │   ├── usecases/             # 用例
│   │   │   ├── login_usecase.dart
│   │   │   ├── register_usecase.dart
│   │   │   ├── get_resumes_usecase.dart
│   │   │   └── save_resume_usecase.dart
│   │   └── repositories/         # 仓库接口
│   │       ├── auth_repository_interface.dart
│   │       └── resume_repository_interface.dart
│   │
│   ├── presentation/             # 表现层
│   │   ├── providers/            # Riverpod Providers
│   │   │   ├── auth_provider.dart
│   │   │   ├── resume_provider.dart
│   │   │   └── template_provider.dart
│   │   ├── pages/                # 页面
│   │   │   ├── auth/
│   │   │   │   ├── login_page.dart
│   │   │   │   └── register_page.dart
│   │   │   ├── home/
│   │   │   │   └── home_page.dart
│   │   │   ├── resume/
│   │   │   │   ├── resume_list_page.dart
│   │   │   │   └── resume_editor_page.dart
│   │   │   ├── template/
│   │   │   │   └── templates_page.dart
│   │   │   ├── profile/
│   │   │   │   └── profile_page.dart
│   │   │   └── settings/
│   │   │       └── settings_page.dart
│   │   ├── widgets/              # 通用Widget
│   │   │   ├── common/
│   │   │   │   ├── app_button.dart
│   │   │   │   ├── app_input.dart
│   │   │   │   ├── app_card.dart
│   │   │   │   └── app_badge.dart
│   │   │   ├── cyber/            # 赛博朋克风格组件
│   │   │   │   ├── neon_button.dart
│   │   │   │   ├── glass_card.dart
│   │   │   │   ├── gradient_text.dart
│   │   │   │   └── orb_background.dart
│   │   │   └── layout/
│   │   │       ├── app_nav_bar.dart
│   │   │       └── app_scaffold.dart
│   │   └── routes/               # 路由配置
│   │       ├── app_router.dart
│   │       └── route_constants.dart
│   │
│   └── l10n/                     # 国际化
│       ├── app_en.arb
│       └── app_zh.arb
│
├── test/                         # 测试
│   ├── unit/                     # 单元测试
│   ├── widget/                   # Widget测试
│   └── integration/              # 集成测试
│
├── pubspec.yaml                  # 依赖配置
└── analysis_options.yaml         # 代码分析配置
```

### 技术栈选型

| 类别 | 技术选型 | 说明 |
|------|---------|------|
| **状态管理** | Riverpod | 现代化、类型安全、测试友好 |
| **路由** | GoRouter | 声明式路由、深链接支持 |
| **网络请求** | Dio | 功能强大、拦截器支持 |
| **本地存储** | Hive | 高性能、NoSQL、支持对象 |
| **安全存储** | flutter_secure_storage | 加密存储敏感数据 |
| **状态持久化** | riverpod_annotation | 代码生成支持 |
| **序列化** | json_annotation | JSON转Dart对象 |
| **表单验证** | flutter_form_builder | 表单管理 |
| **PDF生成** | pdf + printing | PDF导出功能 |

---

## 🎨 设计系统迁移

### 主题配置
```dart
// 从React TailwindCSS迁移到Flutter Theme
class CyberTheme {
  // 颜色系统
  static const primary = Color(0xFF0EA5E9);   // sky-500
  static const accent = Color(0xFF8B5CF6);    // violet-500
  static const darkBg = Color(0xFF0F172A);    // slate-900
  static const cardBg = Color(0x1E293B80);    // slate-800/50

  // 霓虹效果
  static final neonShadow = [
    BoxShadow(
      color: primary.withOpacity(0.5),
      blurRadius: 20,
      spreadRadius: 0,
    ),
  ];

  // 玻璃态效果
  static BoxDecoration glassDecoration = BoxDecoration(
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
      ),
    ],
  );
}
```

### 组件对照表
| React组件 | Flutter Widget | 说明 |
|-----------|---------------|------|
| Button | ElevatedButton/TextButton | 自定义样式封装 |
| Input | TextField | 赛博朋克风格边框 |
| Card | Container/Card | 玻璃态效果 |
| Badge | Container | 小标签样式 |
| Orb | CustomPaint | 背景球体绘制 |

---

## 📝 开发规范

### 命名规范
```dart
// 文件名: snake_case
auth_repository.dart
resume_list_page.dart

// 类名: PascalCase
class AuthRepository {}
class ResumeListPage {}

// 变量/方法: camelCase
final userName = '';
void getUserData() {}

// 常量: lowerCamelCase
const apiBaseUrl = '';

// Private成员: 前缀下划线
String _privateField;
void _privateMethod() {}
```

### 注释规范
```dart
/// 用户认证仓库
///
/// 负责处理用户登录、注册、登出等认证相关操作
class AuthRepository {
  /// 用户登录
  ///
  /// [email] 用户邮箱
  /// [password] 用户密码
  /// 返回 [User] 对象
  Future<User> login(String email, String password) async {
    // ...
  }
}
```

---

## 🔄 迁移策略

### 渐进式迁移方案
```
阶段1: 新建Flutter项目，完成基础架构
        ↓
阶段2: 迁移认证模块，与现有API对接
        ↓
阶段3: 迁移核心页面，保持功能对等
        ↓
阶段4: 并行运行，进行A/B测试
        ↓
阶段5: 逐步切换流量到Flutter版本
        ↓
阶段6: 下线React版本
```

### 数据迁移
- 用户数据：继续使用现有后端API
- 本地数据：提供迁移脚本
- 配置数据：保持格式兼容

---

## 📈 进度跟踪

### 每周检查点
- [ ] Week 1: 项目初始化完成
- [ ] Week 2: 认证模块完成
- [ ] Week 3: 核心页面完成
- [ ] Week 4: 简历编辑器完成
- [ ] Week 5: AI功能完成
- [ ] Week 6: 模板系统完成
- [ ] Week 7: 测试完成
- [ ] Week 8: 发布准备

---

## 🧪 测试策略

### 测试金字塔
```
        /\
       /E2E\        10% - 关键流程
      /------\
     / 集成测试 \    30% - API和组件交互
    /----------\
   /  单元测试   \   60% - 业务逻辑
  /--------------\
```

### 测试覆盖率目标
- 单元测试: 80%+
- Widget测试: 70%+
- 集成测试: 60%+

---

## 📚 参考文档

### Flutter官方文档
- [Flutter中文网](https://flutter.cn/)
- [Flutter实战](https://book.flutterchina.club/)

### 状态管理
- [Riverpod文档](https://riverpod.dev/)
- [Flutter状态管理指南](https://docs.flutter.dev/data-and-backend/state-mgmt/options)

### 代码风格
- [Effective Dart](https://dart.dev/guides/language/effective-dart)
- [Flutter代码规范](https://flutter.dev/docs/development/data-and-backend/code-style)

---

*本文档由AI辅助生成，最后更新: 2026-02-07*
