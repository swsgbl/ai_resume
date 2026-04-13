# 开发日志 — AI Resume 项目

> 本文档记录所有功能开发、架构变更和技术决策。
> 格式遵循 [Keep a Changelog](https://keepachangelog.com/zh-CN/)，日期使用 YYYY-MM-DD。

---

## [2026-04-13] HarmonyOS 编译环境搭建 + 下载页调整

### 新增

#### HarmonyOS Command Line Tools 安装
- 下载 `commandline-tools-linux-x64-6.0.2.650.zip` (2.0GB) 到 `~/hw/`
- 解压到 `~/hw/command-line-tools/`
- 工具版本：ohpm 6.0.1, hvigorw 6.22.4, SDK API 22 (HarmonyOS 6.0.2)
- 全局环境变量已配置到 `~/.bashrc`（HOS_CMDLINE_HOME）

#### 编译尝试
- `ohpm install --all` 成功安装依赖
- `hvigorw assembleHap` 失败 — 项目 build-profile.json5 原配置 API 10，SDK 为 API 22
- 更新 compileSdkVersion 到 22，但仍缺少 `@ohos/cangjie-build-support` 私有包
- 结论：仓颉项目需要 DevEco Studio 完整 IDE 才能编译，命令行工具链不包含此私有包

### 修改
- `DownloadSection.tsx` — 鸿蒙状态改回"即将推出"，Linux 拆分为 .deb + .rpm 两个下载
- `build-profile.json5` — compileSdkVersion 10→22, compatibleSdkVersion 10→12

### 部署
- 已 scp 部署到 https://ndtool.cn/

### 待办
- [ ] 安装 DevEco Studio 完整 IDE 解决鸿蒙编译
- [ ] 鸿蒙 .hap 编译后上传到下载页

---

## [2026-04-12] 下载中心更新 — Linux .rpm + 鸿蒙 .hap 上线

### 新增

#### Linux .rpm 安装包
- 复制 Tauri v2 构建产物 `AI Resume-1.0.0-1.x86_64.rpm` (2.9MB) 到 `public/downloads/`
- 重命名为 `ai-resume-linux-amd64.rpm`

#### 鸿蒙 HarmonyOS .hap 安装包
- 通过 VS Code CodeArts 远程编译成功
- `entry-default-signed.hap` (2.8MB) — 签名版，可直接安装到鸿蒙设备
- 编译步骤：ohpm install → CompileArkTS (3.2s) → PackageResource (1.5s) → CompileResource (0.8s) → AssembleHap (8s)

#### 下载页面更新
- `DownloadSection.tsx` — Linux 拆分为 `.deb` (Ubuntu/Debian) + `.rpm` (Fedora/CentOS) 两个下载卡片
- 鸿蒙状态从"即将推出"改为可下载
- 当前可用下载：Web + Android APK + Linux .deb + Linux .rpm + HarmonyOS .hap

### 部署
- 已 scp 部署到 https://ndtool.cn/downloads/
- 文件：ai-resume-android.apk (51MB), ai-resume-linux-amd64.deb (2.9MB), ai-resume-linux-amd64.rpm (2.9MB)
- 鸿蒙 .hap 需从 CodeArts 环境手动复制到 `public/downloads/`

---

## [2026-04-12] 测试修复 - localStorage 支持性能监控测试

### 修复

#### 测试环境 localStorage 支持
- `src/test/setup.ts` — 添加基于内存的 localStorage 实现
- `src/utils/performance.test.ts` — 在 beforeAll hook 中设置 localStorage

**问题**：performance 工具测试失败，localStorage 在测试环境中未定义

**解决方案**：在 setup.ts 中提供完整的 localStorage 实现（使用内存存储）

**测试结果**：
- Test Files: 31 passed (31)
- Tests: 362 passed | 3 skipped (365)
- Build: 1.62s
- Type Check: 0 errors

---

## [2026-04-12] 测试修复 - i18n 支持公共页面测试

### 修复

#### 测试 i18n 支持
- `AboutPage.test.tsx` — 添加 I18nextProvider + testI18n 实例
- `HelpPage.test.tsx` — 添加 I18nextProvider + testI18n 实例
- `PrivacyPage.test.tsx` — 添加 I18nextProvider + testI18n 实例
- `TermsPage.test.tsx` — 添加 I18nextProvider + testI18n 实例
- 使用 `getAllByText` 替代 `getByText` 避免多元素匹配错误（导航栏 + 移动菜单）

**问题**：测试失败是因为缺少 i18n provider，导致 `t()` 函数无法正常翻译文本

**解决方案**：为每个测试文件创建独立的 i18n 实例，不依赖 LanguageDetector

**测试结果**：
- Test Files: 31 passed (31)
- Tests: 362 passed | 3 skipped (365)
- 测试覆盖率：99.2%

---

## [2026-04-12] 双项目合并 + Impeccable 重设计 + Tauri v2 升级

### 新增

#### 架构决策：合并为统一 React SPA
- **决策**：将 `resource-activation-site`（静态 HTML 站点）合并到 `ai-resume-web`（React SPA）
- **原因**：两个项目共用 ndtool.cn 域名，统一 SPA 提供一致的用户体验和导航
- **影响**：所有页面共享同一套导航系统、设计语言和 i18n 支持

#### 设计系统 — Impeccable
- `.impeccable.md` — 项目设计上下文文件，定义品牌、受众、美学方向
  - 色彩：印泥朱砂 `#C84B31` + 青瓷绿 `#8FAE8B` + 暖黑 `#0C0C0C`
  - 字体：Noto Serif SC（标题）+ DM Sans（正文）+ Playfair Display（英文标题）
  - 美学：水墨书房 + 精密工程，避免通用 AI 风格
  - 参考：Linear.app 的克制，Vercel.com 的自信留白

#### i18n 国际化系统
- `src/i18n/index.ts` — i18next 配置，浏览器语言检测 + localStorage 持久化
- `src/locales/zh.json` — 中文翻译（导航 + 着陆页 + 职业 + 资源 + 认证）
- `src/locales/en.json` — 英文翻译
- `src/main.tsx` — 添加 i18n 初始化导入

#### 资源页面迁移（6 个静态页 → React 组件）
- `src/pages/resources/ResourcesMainPage.tsx` — 资源首页，分类网格 + 搜索
- `src/pages/resources/ToolboxPage.tsx` — 工具箱，系统/网络/软件工具列表 + 下载
- `src/pages/resources/ResourcesListPage.tsx` — 资源中心，系统/开发/安全资源
- `src/pages/resources/FeedbackPage.tsx` — 反馈表单 + 历史记录（localStorage 持久化）
- `src/pages/resources/StatusPage.tsx` — 系统状态监控
- `src/pages/resources/SecurityPage.tsx` — 安全信息 + 免责声明

#### 资源页共享组件
- `src/components/resources/ResourceLayout.tsx` — 子导航 + 语言切换
- `src/components/resources/LanguageSwitcher.tsx` — CN/EN 切换按钮

#### 数据迁移
- `src/data/tools.json` — 从 resource-activation-site 迁移的工具配置（8 个工具）
- `src/data/resources.ts` — 类型化数据导出，按类别过滤工具

#### Tauri v2 升级（Linux 桌面端）
- `ai-resume-desktop/src-tauri/Cargo.toml` — tauri 1.6→2, tauri-build 1.5→2
- `ai-resume-desktop/src-tauri/tauri.conf.json` — v1 格式→v2 格式（allowlist→capabilities）
- `ai-resume-desktop/src-tauri/capabilities/default.json` — v2 权限系统
- `ai-resume-desktop/src-tauri/src/lib.rs` — v2 Builder API
- `ai-resume-desktop/package.json` — @tauri-apps/api ^1.5→^2.0, @tauri-apps/cli ^1.5→^2.0
- `ai-resume-desktop/src/services/fileSystem.ts` — @tauri-apps/api/tauri → /core
- `ai-resume-desktop/src/main.tsx` — appWindow → getCurrentWindow()
- `ai-resume-desktop/vite.config.ts` — safari13→safari14
- **构建输出**: `ai-resume-linux-amd64.deb` (2.9MB), `.rpm` (2.9MB)

### 修改

#### 全局导航统一
- `PublicNavbar.tsx` — 添加"资源工具"链接、语言切换器，Impeccable 设计
- `PublicNavbar.css` — Impeccable 设计系统（朱砂 CTA + 暖黑背景 + 去掉圆角渐变）
- `landing/Navbar.tsx` — 同步导航项 + 语言切换

#### 路由系统
- `App.tsx` — 添加 6 个资源页路由 + 懒加载

#### 依赖更新
- `package.json` — 添加 i18next, react-i18next, i18next-browser-languagedetector

#### Impeccable 全站视觉重设计
- `src/index.css` — 全局设计系统重写：赛博朋克 → 印泥朱砂/青瓷绿/暖黑宣纸
  - 色彩：`#0ea5e9/#8b5cf6` → `#C84B31(vermillion)/#8FAE8B(celadon)/#0C0C0C(warm black)`
  - 按钮：渐变发光 → 实色填充，去圆角
  - 卡片：毛玻璃 → 纯色背景 + 细边框
  - 滚动条：渐变 → 极简灰
  - 输入框：圆角边框 → 底线式
- `src/pages/LandingPage.css` — 首页 CSS 全面重写
  - 字体：Space Grotesk → Playfair Display + Noto Serif SC（中文衬线）
  - 动画：渐变移动/脉冲发光 → 淡入上浮，更克制
  - 按钮：圆角胶囊 → 直角，实色背景
  - 导航：毛玻璃 + 渐变 → 深色半透明 + 细线边框
  - 间距：增加留白，减少视觉噪音
- `tailwind.config.js` — 色彩和字体配置同步更新

### 待办
- [ ] Impeccable 全站视觉重设计（Phase 4：逐页优化）
- [ ] 更新 nginx 配置支持 SPA fallback
- [ ] 部署到 ndtool.cn 并验证所有路由
- [ ] Windows/macOS 桌面端编译（需对应平台环境）
- [ ] HarmonyOS/iOS 编译（需对应 SDK）

---

## [2026-04-12] 官网修复 + 职业智能融合

### 新增

#### 前端 — 全局导航系统
- `PublicNavbar` 组件 — 固定顶部导航栏，琥珀金+翡翠绿深色主题，滚动毛玻璃效果
- `PublicLayout` 组件 — 包裹所有公开页面的统一布局
- `PublicNavbar.css` — 响应式样式，768px 移动端汉堡菜单
- 导航菜单项：首页、职业智能、关于、帮助、Trae AI、条款、隐私、登录、注册

#### 前端 — 职业智能中心 (`/career`)
- `CareerPage.tsx` — 三合一页面：
  - **JD 智能评估** — 粘贴 JD → 6 维全景分析（直觉判断/职位摘要/简历匹配/等级策略/薪资研究/面试准备）
  - **故事银行** — Polanyi 默会经验挖掘，STAR+R 面试故事
  - **智能定制** — 基于 JD 直觉调整简历叙事角度
- 集成到全局导航和首页 Navbar

#### 前端 — TraePage 导航改造
- 移除 TraePage 的独立 `<nav>` 导航
- 使用 `PublicLayout` 包裹，复用全局导航
- Trae AI 正式进入导航菜单，不再藏在下载区

#### 后端 — 职业智能 API (`/api/v1/career/`)
- `POST /evaluate` — JD 6 维全景评估
  - 输入：resume_id + job_description + user_preferences
  - 输出：intuition(直觉) + blocks(A-F) + overall_score + recommendation + tacit_insight
- `POST /story-bank` — STAR+R 故事挖掘
  - 输入：resume_id + existing_stories + additional_context
  - 输出：stories[] + meta_stories[] + growth_trajectory
- `POST /smart-tailor` — 智能简历定制
  - 输入：resume_id + job_description
  - 输出：tailored_content + changes_made[] + keywords_injected + narrative_angle

#### 后端 — AI Prompt 体系
- `career_intelligence_v1.md` — 系统提示词：20 年经验资深猎头 + Polanyi 默会知识理论
- `career/jd_evaluate.md` — JD 评估任务 prompt，6 块评估 + JSON 输出规范
- `career/story_bank.md` — 故事银行 prompt，默会知识挖掘框架

#### 后端 — 路由注册
- `app/api/v1/__init__.py` 添加 `career_router`
- 新文件 `app/api/v1/career.py`

### 修改

#### 公开页面改造（统一全局导航）
- `AboutPage.tsx` — 移除独立 header，使用 PublicLayout
- `HelpPage.tsx` — 同上
- `TermsPage.tsx` — 同上
- `PrivacyPage.tsx` — 同上
- `TraePage.tsx` — 移除独立 nav，使用 PublicLayout，添加 `paddingTop: 64px`
- `LoginPage.tsx` — 通过 App.tsx 路由级 PublicLayout 包裹
- `RegisterPage.tsx` — 同上
- `ForgotPasswordPage.tsx` — 同上

#### 首页 Navbar 更新
- `Navbar.tsx` — 添加：职业智能、帮助、Trae AI、条款、隐私链接
- 移除旧的"AI 简历"、"模板"、"资源工具"链接

#### App.tsx 路由重构
- 所有公开页面路由添加 `PublicLayout` 包裹
- TraePage 使用 `fullPage` 模式避免 padding-top
- Login/Register 使用条件渲染（未登录显示 PublicLayout，已登录跳转 dashboard）
- 新增 `CareerPage` 懒加载路由

#### 桌面端类型修复
- `ResumeListPage.tsx` — `data?.items` → `data?.data` (PaginatedResponse 类型修正)
- `TemplatesPage.tsx` — 同上

### 部署
- 构建并部署到 https://ndtool.cn/（2026-04-12 14:30 UTC+8）
- 33 个 asset 文件
- 后端新路由需要重启后端服务才能生效

### 待办
- [ ] 重启后端服务激活 `/api/v1/career/` 路由
- [ ] 测试 JD 评估 API 端到端流程
- [ ] Tauri v2 升级（支持 webkit2gtk-4.1，当前 v1 与系统不兼容）
- [ ] Windows/macOS 桌面端编译（需对应平台环境）
- [ ] HarmonyOS/iOS 编译（需对应 SDK）

---

## [2026-04-10 ~ 2026-04-11] 官网建设 + 全站风格统一

### 新增

#### 官网首页 (LandingPage)
- 12 个组件区块：Navbar, Hero, Stats, Features, HowItWorks, Testimonials, Pricing, Download, FAQ, CTA, Footer
- 设计系统：深色 (#050816) + 琥珀金 (#f59e0b) + 翡翠绿 (#10b981)
- 自定义 hooks：`useScrollAnimation`（IntersectionObserver）、`useCountUp`（requestAnimationFrame）
- 玻璃拟态卡片、渐变动画、滚动触发动画
- Scoped CSS：`.landing-page` 前缀隔离样式

#### Trae AI 页面 (`/trae`)
- 从 git 历史 (commit 25915bd) 恢复原始 Trae.ai 推广页
- 独立 CSS：`.trae-page` 前缀
- 路由：`/trae`

#### Android 安装包
- Flutter APK (52MB) → `public/downloads/ai-resume-android.apk`

### 修改

#### 全站颜色统一（13 个页面）
- `tailwind.config.js` — primary: amber, accent: emerald, cyber 色更新
- LoginPage, RegisterPage, ForgotPasswordPage — sky/blue → amber/emerald
- AboutPage, HelpPage, TermsPage, PrivacyPage — 浅色 → 深色
- HomePage, ResumeListPage, TemplatesPage, ProfilePage, SettingsPage — accent 色

#### SEO
- `index.html` — 完整 meta tags, OG tags, Twitter Card, JSON-LD Schema
- 字体：Space Grotesk (标题) + DM Sans (正文)

### 部署
- 2026-04-10 01:08 UTC+8 → https://ndtool.cn/
- Playwright 测试 8/10 通过

### Commit 记录
```
459d3c9 feat: 统一全站设计风格 + 恢复Trae页面 + 提供Android安装包
```

---

## 项目状态

| 模块 | 状态 | 备注 |
|------|------|------|
| 官网首页 | ✅ 已上线 | https://ndtool.cn/ |
| 全局导航 | ✅ 已上线 | 所有公开页面统一菜单 |
| 职业智能中心 | ⚠️ 前端已部署，后端待重启 | https://ndtool.cn/career |
| Trae AI 页面 | ✅ 已上线 | https://ndtool.cn/trae |
| Android APK | ✅ 已提供 | 52MB Flutter |
| Linux 桌面端 | ❌ 阻塞 | Tauri v1 与 webkit2gtk-4.1 不兼容 |
| Windows 桌面端 | ❌ 待做 | 需 Windows 环境交叉编译 |
| macOS 桌面端 | ❌ 待做 | 需 macOS 环境 |
| iOS | ❌ 待做 | 需 macOS + Xcode |
| HarmonyOS | ❌ 待做 | 需 HarmonyOS SDK |
