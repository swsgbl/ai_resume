 # AI Resume - HarmonyOS 开发指南

## 项目概述

本项目是基于仓颉(Cangjie)语言开发的鸿蒙原生简历生成应用，与现有的Web、Desktop、Mobile版本形成完整的跨平台解决方案。

## 技术栈

- **开发语言**: 仓颉 (Cangjie)
- **UI框架**: ArkUI (声明式UI)
- **目标平台**: HarmonyOS Next (API 10+)
- **开发工具**: DevEco Studio 4.0+

## 项目结构

```
ai-resume-harmonyos/
├── AppScope/                    # 应用全局配置
│   ├── app.json5               # 应用配置
│   └── resources/              # 全局资源
├── entry/                       # 主入口模块
│   ├── src/main/
│   │   ├── cj/                 # 仓颉源代码
│   │   │   ├── entry/          # 入口
│   │   │   ├── models/         # 数据模型
│   │   │   ├── views/          # UI视图
│   │   │   ├── viewmodels/     # 视图模型
│   │   │   ├── services/       # 服务层
│   │   │   └── utils/          # 工具类
│   │   ├── resources/          # 资源文件
│   │   └── module.json5        # 模块配置
│   ├── build-profile.json5     # 构建配置
│   └── hvigorfile.ts           # 构建脚本
├── build-profile.json5         # 项目构建配置
├── hvigorfile.ts              # 项目构建脚本
└── oh-package.json5           # 依赖配置
```

## 核心功能模块

### 1. 数据模型 (models/)

- **User.cj**: 用户模型、认证Token、登录/注册请求
- **Resume.cj**: 简历模型、简历数据结构（个人信息、教育、工作经历等）
- **Template.cj**: 模板模型、模板样式、模板分类
- **AI.cj**: AI配置、AI使用统计、AI生成请求/响应

### 2. 服务层 (services/)

- **ApiConfig.cj**: API配置和端点定义
- **HttpClient.cj**: HTTP客户端封装
- **AuthService.cj**: 用户认证服务（登录、注册、Token管理）
- **ResumeService.cj**: 简历CRUD服务
- **TemplateService.cj**: 模板管理服务
- **AIService.cj**: AI生成服务
- **ExportService.cj**: 导出服务（PDF、Word、HTML）

### 3. 视图层 (views/)

- **LoginPage.cj**: 登录页面
- **HomePage.cj**: 主页（简历列表、模板、AI助手）
- **ResumeEditorPage.cj**: 简历编辑器
- **TemplateSelectPage.cj**: 模板选择页面

### 4. 视图模型 (viewmodels/)

- **ResumeViewModel.cj**: 简历状态管理
- **AuthViewModel.cj**: 认证状态管理

### 5. 工具类 (utils/)

- **JsonParser.cj**: JSON解析工具
- **Preferences.cj**: 本地存储工具

## 开发环境设置

### 1. 安装 DevEco Studio

从华为开发者官网下载并安装 DevEco Studio 4.0 或更高版本。

### 2. 配置 HarmonyOS SDK

在 DevEco Studio 中配置 HarmonyOS Next SDK (API 10+)。

### 3. 打开项目

使用 DevEco Studio 打开 `ai-resume-harmonyos` 目录。

### 4. 同步依赖

点击 "Sync Now" 同步项目依赖。

## 开发指南

### 创建新页面

1. 在 `entry/src/main/cj/views/` 创建新的 `.cj` 文件
2. 使用 `@Entry` 和 `@Component` 注解定义组件
3. 在 `resources/base/profile/main_pages.json` 中注册页面路径

### 状态管理

使用 `@State` 注解管理组件状态：

```cangjie
@State private var count: Int32 = 0
```

### 网络请求

使用封装好的 HttpClient：

```cangjie
let httpClient = HttpClient(ApiConfig.BASE_URL)
let response = httpClient.get("/api/v1/resumes")
```

### 本地存储

使用 Preferences 工具类：

```cangjie
let prefs = Preferences.get("my_prefs")
prefs.putString("key", "value")
prefs.flush()
```

## API 配置

默认连接到本地后端服务：

```
http://localhost:8000/api/v1
```

修改 `services/ApiConfig.cj` 中的 `BASE_URL` 以连接到生产环境。

## 构建和运行

### 调试模式

1. 连接鸿蒙设备或启动模拟器
2. 点击 DevEco Studio 的运行按钮

### 发布构建

```bash
hvigorw assembleHap --mode release
```

## 功能特性

### 已实现功能

- ✅ 用户认证（登录、注册、Token管理）
- ✅ 简历CRUD操作
- ✅ 模板选择和预览
- ✅ 简历编辑器（个人信息、教育、工作经历、技能）
- ✅ AI内容生成
- ✅ 多格式导出（PDF、Word、HTML）
- ✅ 本地数据缓存
- ✅ 响应式UI设计

### 待实现功能

- 🔲 OAuth登录（微信等）
- 🔲 简历版本管理
- 🔲 离线模式
- 🔲 多语言支持
- 🔲 深色模式

## 与后端集成

应用连接到 AI Resume 后端服务，需要确保：

1. 后端服务正在运行
2. API端点配置正确
3. 网络权限已配置

## 注意事项

1. **仓颉语言**: 这是华为开发的编程语言，语法类似 TypeScript/Kotlin
2. **ArkUI**: 使用声明式UI范式，类似 SwiftUI/Flutter
3. **API兼容**: 确保使用 HarmonyOS Next API 10+ 的特性
4. **权限配置**: 在 `module.json5` 中配置必要的权限

## 相关文档

- [HarmonyOS 开发文档](https://developer.harmonyos.com/cn/docs/documentation/doc-guides-V3/start-overview-0000001478041421-V3)
- [仓颉语言指南](https://developer.harmonyos.com/cn/docs/documentation/doc-guides-V3/cangjie-overview-0000001478041421-V3)
- [ArkUI 开发指南](https://developer.harmonyos.com/cn/docs/documentation/doc-guides-V3/arkui-overview-0000001478041421-V3)

## 许可证

MIT License
