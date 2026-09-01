# AI Resume - Flutter统一版本

> AI智能简历生成应用 - Flutter跨平台统一版本

## 项目概述

本项目是AI Resume应用的Flutter统一版本，旨在通过Flutter框架实现Web、Desktop、Mobile三端代码完全复用。

### 项目代号
**Phoenix** - 从React多端架构重生为Flutter统一架构

### 技术栈

| 类别 | 技术选型 | 版本 |
|------|---------|------|
| Flutter SDK | 3.10.8+ | |
| 状态管理 | Riverpod | 2.6.1+ |
| 路由 | GoRouter | 14.6.2+ |
| 网络 | Dio | 5.7.0+ |
| 本地存储 | Hive | 2.2.3+ |

### 支持平台

- ✅ Web (HTML渲染)
- ✅ Windows (桌面)
- ✅ Android (移动)
- 🚧 macOS (待开发)
- 🚧 Linux (待开发)
- 🚧 iOS (待开发)

## 项目结构

```
lib/
├── core/                     # 核心层
│   ├── config/               # 配置
│   ├── constants/            # 常量
│   ├── errors/               # 错误处理
│   ├── network/              # 网络层
│   └── utils/                # 工具类
├── data/                     # 数据层
│   ├── models/               # 数据模型
│   ├── repositories/         # 仓库
│   └── datasources/          # 数据源
├── domain/                   # 领域层
│   ├── entities/             # 领域实体
│   ├── usecases/             # 用例
│   └── repositories/         # 仓库接口
└── presentation/             # 表现层
    ├── providers/            # 状态管理
    ├── pages/                # 页面
    ├── widgets/              # 组件
    └── routes/               # 路由
```

## 开发指南

### 环境要求

1. Flutter SDK 3.10.8+
2. Dart 3.10.8+

### 安装依赖

```bash
flutter pub get
```

### 运行项目

```bash
# Web
flutter run -d chrome

# Windows
flutter run -d windows

# Android
flutter run -d android
```

## 设计系统

赛博朋克风格设计：

- **主色调**: 蓝色 (#0EA5E9)
- **强调色**: 紫色 (#8B5CF6)
- **风格**: 霓虹发光、玻璃态效果

## 项目管理

详细文档请查看 `../PROJECT_MANAGEMENT/` 目录：

- `plans/FLUTTER_MIGRATION_PLAN.md` - 迁移计划
- `requirements/REQUIREMENTS_TRACEABILITY.md` - 需求跟踪
- `logs/DEVELOPMENT_LOG.md` - 开发日志

## 开发规范

- 命名: 文件用`snake_case`，类用`PascalCase`，变量用`camelCase`
- 注释: 使用`///`文档注释
- 格式: 使用`flutter format`自动格式化

---

*最后更新: 2026-02-07*
