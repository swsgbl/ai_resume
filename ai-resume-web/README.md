# AI Resume Web Frontend

AI 简历平台的前端应用，基于 React 18 + TypeScript + Vite 构建。

## 技术栈

### 核心框架
- **React 18** - UI 框架
- **TypeScript** - 类型安全
- **Vite 5** - 构建工具

### 路由与状态
- **React Router v6** - 客户端路由
- **Zustand** - 轻量级状态管理
- **TanStack Query** - 服务端状态管理

### UI 组件
- **TailwindCSS** - 原子化 CSS 框架
- **Lucide React** - 图标库
- **TipTap** - 富文本编辑器
- **DnD Kit** - 拖拽功能

### 代码质量
- **ESLint** - 代码检查
- **Vitest** - 单元测试
- **Testing Library** - React 组件测试
- **Playwright** - E2E 测试

## 项目结构

```
ai-resume-web/
├── src/
│   ├── components/          # 可复用组件
│   │   ├── editor/         # 简历编辑器组件
│   │   │   ├── DraggableResumeEditor.tsx
│   │   │   ├── DraggableSection.tsx
│   │   │   └── RichTextEditor.tsx
│   │   ├── ui/             # UI 基础组件
│   │   │   ├── Button.tsx
│   │   │   ├── Input.tsx
│   │   │   └── ...
│   │   ├── ErrorBoundary.tsx
│   │   ├── ResumePreview.tsx
│   │   └── UIComponents.tsx
│   ├── pages/              # 页面组件
│   │   ├── HomePage.tsx
│   │   ├── LoginPage.tsx
│   │   ├── RegisterPage.tsx
│   │   ├── ResumeEditorPage.tsx
│   │   └── ...
│   ├── store/              # 状态管理
│   │   └── auth.ts
│   ├── utils/              # 工具函数
│   │   └── cn.ts
│   ├── types/              # 类型定义
│   ├── App.tsx
│   └── main.tsx
├── public/                 # 静态资源
├── .eslintrc.cjs           # ESLint 配置
├── tailwind.config.js      # Tailwind 配置
├── tsconfig.json           # TypeScript 配置
├── vite.config.ts          # Vite 配置
└── package.json
```

## 开发指南

### 安装依赖

```bash
npm install
```

### 启动开发服务器

```bash
npm run dev
```

访问 http://localhost:5173

### 构建生产版本

```bash
npm run build
```

构建产物位于 `dist/` 目录。

### 预览生产构建

```bash
npm run preview
```

## 测试

### 运行单元测试

```bash
# 运行所有测试
npm run test

# 监听模式
npm run test:watch

# UI 模式
npm run test:ui

# 测试覆盖率
npm run test:coverage
```

### 运行 E2E 测试

```bash
# 运行 E2E 测试
npm run test:e2e

# UI 模式
npm run test:e2e:ui

# 有头模式（显示浏览器）
npm run test:e2e:headed
```

## 项目质量指标

### 项目规模
- **源文件**: 84 个 TypeScript/TSX 文件
- **组件**: 31+ 个可复用组件（含编辑器组件和Landing组件）
- **页面**: 27 个页面组件
- **测试文件**: 31 个测试文件
- **测试用例**: 362 个测试用例（3 个跳过）

### 代码质量 ✅
- TypeScript 严格模式，0 类型错误
- ESLint 检查通过，仅有测试 mock 警告
- 所有组件使用函数式组件 + Hooks
- 统一的代码风格和规范

### 性能优化 ✅
- **代码分割**: 所有页面使用 React.lazy 懒加载
- **Bundle 优化**: 手动分包（vendor chunks）
- **压缩**: esbuild 最快压缩
- **性能监控**: Web Vitals (CLS, FID, LCP, FCP, TTFB)
- **构建大小**: 972 KB (gzip 后 ~280 KB)

### 测试覆盖 ✅
- 单元测试：30 个测试文件，348 个测试用例（3 个跳过）
- 测试通过率：100% (348/348)
- E2E 测试：多设备覆盖（桌面、移动端）
- 测试框架：Vitest + Testing Library + Playwright

## 代码质量

### 代码检查

```bash
npm run lint
```

### 自动修复

```bash
npm run lint:fix
```

### 类型检查

```bash
npm run type-check
```

## 路由结构

### 公开路由
| 路径 | 组件 | 说明 |
|------|------|------|
| `/` | **LandingPage** | 首页，Trae.ai 推广页面 |
| `/login` | **LoginPage** | 登录页面 |
| `/register` | **RegisterPage** | 注册页面 |
| `/forgot-password` | **ForgotPasswordPage** | 忘记密码页面 |
| `/about` | **AboutPage** | 关于我们 |
| `/help` | **HelpPage** | 帮助中心 |
| `/terms` | **TermsPage** | 用户协议 |
| `/privacy` | **PrivacyPage** | 隐私政策 |

### 受保护路由（需要登录）
| 路径 | 组件 | 说明 |
|------|------|------|
| `/dashboard` | **HomePage** | 用户主页面 |
| `/resumes` | **ResumeListPage** | 简历列表 |
| `/resumes/:id` | **ResumeEditorPage** | 简历编辑器 |
| `/templates` | **TemplatesPage** | 模板库 |
| `/profile` | **ProfilePage** | 个人中心 |
| `/settings` | **SettingsPage** | 设置页面 |

### 路由配置
- 使用 React Router v6 的懒加载优化性能
- 未认证用户访问受保护路由自动跳转到登录页
- 登录后自动跳转到 `/dashboard`

## 核心功能

### 1. 用户认证
- 登录/注册/忘记密码
- 邮箱验证
- Token 管理
- 记住密码功能

### 2. 简历编辑
- 所见即所得编辑器
- 拖拽排序
- 富文本编辑
- 实时预览
- AI 辅助生成

### 3. 模板系统
- 多种简历模板
- 模板预览
- 一键应用

### 4. 导出功能
- PDF 导出
- Word 导出
- HTML 导出

## 组件开发规范

### 命名规范
- 组件文件：PascalCase（如 `Button.tsx`）
- 工具文件：camelCase（如 `cn.ts`）
- 测试文件：`*.test.tsx` 或 `*.test.ts`

### 代码规范
- 使用函数式组件 + Hooks
- Props 必须有 TypeScript 类型定义
- 优先使用 Tailwind CSS 进行样式
- 复杂逻辑提取为自定义 Hook

### 测试规范
- 新功能必须编写单元测试
- 测试覆盖率目标：80%+
- 使用 Testing Library 最佳实践

**当前测试覆盖率** ✅
- 单元测试：31 个测试文件，362 个测试用例（3 个跳过）
- 页面覆盖率：100% (14/14 页面已测试)
- E2E 测试：Playwright 完整配置
- 测试通过率：100% (362 passed | 3 skipped)

**已测试页面**：
- ✅ LoginPage
- ✅ RegisterPage
- ✅ ForgotPasswordPage
- ✅ HomePage
- ✅ ResumeEditorPage
- ✅ ResumeListPage
- ✅ TemplatesPage
- ✅ ProfilePage
- ✅ SettingsPage
- ✅ AboutPage
- ✅ HelpPage
- ✅ LandingPage
- ✅ TermsPage
- ✅ PrivacyPage

**测试覆盖率**: 100% (14/14 页面已测试) ✅

## 环境变量

创建 `.env.local` 文件：

```env
VITE_API_BASE_URL=http://localhost:8000
VITE_APP_NAME=AI Resume
```

## 部署

### Docker 部署

```bash
docker build -t ai-resume-web .
docker run -p 80:80 ai-resume-web
```

### 静态托管

构建后将 `dist/` 目录部署到任何静态托管服务：
- Vercel
- Netlify
- AWS S3 + CloudFront

## 相关项目

- [ai-resume-api](../ai-resume-api) - 后端 API 服务
- [ai-resume-shared](../ai-resume-shared) - 共享类型定义

## 贡献指南

1. Fork 本仓库
2. 创建特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'feat: add some amazing feature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 开启 Pull Request

## 许可证

MIT License

## 联系方式

- 项目主页：https://github.com/your-org/ai-resume
- 问题反馈：https://github.com/your-org/ai-resume/issues
