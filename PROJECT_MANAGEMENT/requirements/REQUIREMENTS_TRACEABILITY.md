# 需求跟踪矩阵 (Requirements Traceability Matrix)

> **文档创建时间**: 2026-02-07
> **用途**: 跟踪从React到Flutter迁移的所有功能需求
> **格式**: 每个需求唯一ID，关联到开发任务和测试用例

---

## 📋 需求分类

### 1. 认证模块 (AUTH)
### 2. 简历管理 (RESUME)
### 3. 模板系统 (TEMPLATE)
### 4. AI功能 (AI)
### 5. 用户设置 (SETTINGS)
### 6. UI组件 (UI)
### 7. 平台支持 (PLATFORM)

---

## AUTH - 认证模块

| ID | 需求描述 | 优先级 | 状态 | Flutter实现 | 测试用例 | 备注 |
|----|---------|--------|------|-------------|---------|------|
| AUTH-001 | 用户登录功能 | P0 | 待开发 | `lib/presentation/pages/auth/login_page.dart` | `test/unit/auth/login_test.dart` | 邮箱+密码登录 |
| AUTH-002 | 用户注册功能 | P0 | 待开发 | `lib/presentation/pages/auth/register_page.dart` | `test/unit/auth/register_test.dart` | 含验证码验证 |
| AUTH-003 | 邮箱验证码发送 | P0 | 待开发 | `lib/data/datasources/remote/auth_api.dart` | `test/integration/auth/verify_code_test.dart` | 倒计时60秒 |
| AUTH-004 | Token自动刷新 | P0 | 待开发 | `lib/core/network/api_interceptors.dart` | `test/unit/network/token_refresh_test.dart` | 401自动刷新 |
| AUTH-005 | 自动登录 | P1 | 待开发 | `lib/presentation/providers/auth_provider.dart` | `test/integration/auth/auto_login_test.dart` | 本地Token持久化 |
| AUTH-006 | 忘记密码 | P1 | 待开发 | - | - | 待后端支持 |
| AUTH-007 | 第三方登录 | P2 | 待开发 | - | - | 微信/GitHub |
| AUTH-008 | 登出功能 | P0 | 待开发 | `lib/presentation/providers/auth_provider.dart` | `test/unit/auth/logout_test.dart` | 清除本地数据 |

---

## RESUME - 简历管理

| ID | 需求描述 | 优先级 | 状态 | Flutter实现 | 测试用例 | 备注 |
|----|---------|--------|------|-------------|---------|------|
| RESUME-001 | 简历列表展示 | P0 | 待开发 | `lib/presentation/pages/resume/resume_list_page.dart` | `test/widget/resume/list_test.dart` | 分页加载 |
| RESUME-002 | 创建新简历 | P0 | 待开发 | `lib/presentation/pages/resume/resume_editor_page.dart` | `test/integration/resume/create_test.dart` | 空白模板 |
| RESUME-003 | 编辑简历 | P0 | 待开发 | `lib/presentation/pages/resume/resume_editor_page.dart` | `test/integration/resume/edit_test.dart` | 实时保存 |
| RESUME-004 | 删除简历 | P0 | 待开发 | `lib/data/repositories/resume_repository.dart` | `test/unit/resume/delete_test.dart` | 二次确认 |
| RESUME-005 | 简历状态管理 | P0 | 待开发 | `lib/data/models/resume.dart` | - | 草稿/已发布/已归档 |
| RESUME-006 | 简历筛选 | P1 | 待开发 | `lib/presentation/pages/resume/resume_list_page.dart` | `test/widget/resume/filter_test.dart` | 按状态筛选 |
| RESUME-007 | 简历搜索 | P1 | 待开发 | `lib/presentation/pages/resume/resume_list_page.dart` | `test/widget/resume/search_test.dart` | 按标题搜索 |
| RESUME-008 | 简历复制 | P1 | 待开发 | `lib/data/repositories/resume_repository.dart` | - | 快速创建副本 |
| RESUME-009 | 简历导出PDF | P0 | 待开发 | `lib/core/utils/pdf_exporter.dart` | `test/integration/resume/export_pdf_test.dart` | |
| RESUME-010 | 简历导出Word | P1 | 待开发 | `lib/core/utils/doc_exporter.dart` | `test/integration/resume/export_doc_test.dart` | |

### 简历内容子模块

| ID | 需求描述 | 优先级 | 状态 | Flutter实现 | 测试用例 |
|----|---------|--------|------|-------------|---------|
| RESUME-101 | 基本信息编辑 | P0 | 待开发 | `lib/presentation/widgets/resume/basic_info_tab.dart` | `test/widget/resume/basic_info_test.dart` |
| RESUME-102 | 教育经历编辑 | P0 | 待开发 | `lib/presentation/widgets/resume/education_tab.dart` | `test/widget/resume/education_test.dart` |
| RESUME-103 | 工作经历编辑 | P0 | 待开发 | `lib/presentation/widgets/resume/work_tab.dart` | `test/widget/resume/work_test.dart` |
| RESUME-104 | 项目经历编辑 | P0 | 待开发 | `lib/presentation/widgets/resume/project_tab.dart` | `test/widget/resume/project_test.dart` |
| RESUME-105 | 技能特长编辑 | P0 | 待开发 | `lib/presentation/widgets/resume/skill_tab.dart` | `test/widget/resume/skill_test.dart` |
| RESUME-106 | 多项添加/删除 | P0 | 待开发 | `lib/presentation/widgets/resume/list_editor.dart` | - |
| RESUME-107 | 拖拽排序 | P1 | 待开发 | `lib/presentation/widgets/resume/draggable_list.dart` | - |

---

## TEMPLATE - 模板系统

| ID | 需求描述 | 优先级 | 状态 | Flutter实现 | 测试用例 | 备注 |
|----|---------|--------|------|-------------|---------|------|
| TMPL-001 | 模板列表展示 | P0 | 待开发 | `lib/presentation/pages/template/templates_page.dart` | `test/widget/template/list_test.dart` | 网格布局 |
| TMPL-002 | 模板分类筛选 | P0 | 待开发 | `lib/presentation/widgets/template/category_filter.dart` | `test/widget/template/filter_test.dart` | 行业分类 |
| TMPL-003 | 模板搜索 | P1 | 待开发 | `lib/presentation/widgets/template/search_bar.dart` | - | 关键词搜索 |
| TMPL-004 | 模板预览 | P0 | 待开发 | `lib/presentation/widgets/template/preview_card.dart` | - | 缩略图展示 |
| TMPL-005 | 模板应用 | P0 | 待开发 | `lib/data/repositories/template_repository.dart` | `test/integration/template/apply_test.dart` | 一键应用 |
| TMPL-006 | 模板收藏 | P1 | 待开发 | `lib/data/repositories/template_repository.dart` | - | |
| TMPL-007 | 经验水平筛选 | P1 | 待开发 | `lib/presentation/widgets/template/level_filter.dart` | - | 应届/1-3年/3-5年/5+ |
| TMPL-008 | 自定义模板 | P2 | 待开发 | - | - | 用户创建模板 |

---

## AI - AI功能

| ID | 需求描述 | 优先级 | 状态 | Flutter实现 | 测试用例 | 备注 |
|----|---------|--------|------|-------------|---------|------|
| AI-001 | AI生成简历 | P0 | 待开发 | `lib/data/datasources/remote/ai_api.dart` | `test/integration/ai/generate_test.dart` | 根据基本信息生成 |
| AI-002 | AI优化内容 | P0 | 待开发 | `lib/data/datasources/remote/ai_api.dart` | `test/integration/ai/optimize_test.dart` | 润色描述 |
| AI-003 | 多AI提供商 | P0 | 待开发 | `lib/core/config/ai_config.dart` | - | OpenAI/DeepSeek/小米 |
| AI-004 | 模型选择 | P1 | 待开发 | `lib/presentation/pages/settings/ai_settings_page.dart` | - | GPT-3.5/GPT-4等 |
| AI-005 | API Key配置 | P0 | 待开发 | `lib/presentation/providers/settings_provider.dart` | - | 本地加密存储 |
| AI-006 | 流式输出 | P1 | 待开发 | `lib/core/network/stream_client.dart` | - | SSE支持 |
| AI-007 | 使用统计 | P2 | 待开发 | `lib/data/repositories/usage_repository.dart` | - | Token消耗统计 |

---

## SETTINGS - 用户设置

| ID | 需求描述 | 优先级 | 状态 | Flutter实现 | 测试用例 | 备注 |
|----|---------|--------|------|-------------|---------|------|
| SET-001 | 服务器配置 | P0 | 待开发 | `lib/presentation/pages/settings/server_settings_page.dart` | - | 自定义API地址 |
| SET-002 | AI配置 | P0 | 待开发 | `lib/presentation/pages/settings/ai_settings_page.dart` | - | 见AI模块 |
| SET-003 | 主题切换 | P2 | 待开发 | `lib/presentation/providers/theme_provider.dart` | - | 深色/浅色模式 |
| SET-004 | 语言切换 | P2 | 待开发 | `lib/l10n/` | - | 中/英 |
| SET-005 | 缓存清理 | P1 | 待开发 | `lib/core/storage/cache_manager.dart` | - | 清除本地缓存 |
| SET-006 | 关于页面 | P2 | 待开发 | `lib/presentation/pages/settings/about_page.dart` | - | 版本信息 |

---

## UI - UI组件库

| ID | 需求描述 | 优先级 | 状态 | Flutter实现 | 测试用例 | 备注 |
|----|---------|--------|------|-------------|---------|------|
| UI-001 | 按钮组件 | P0 | 待开发 | `lib/presentation/widgets/common/app_button.dart` | `test/widget/ui/button_test.dart` | 多种样式 |
| UI-002 | 输入框组件 | P0 | 待开发 | `lib/presentation/widgets/common/app_input.dart` | `test/widget/ui/input_test.dart` | 含验证 |
| UI-003 | 卡片组件 | P0 | 待开发 | `lib/presentation/widgets/common/app_card.dart` | `test/widget/ui/card_test.dart` | 玻璃态效果 |
| UI-004 | 徽章组件 | P1 | 待开发 | `lib/presentation/widgets/common/app_badge.dart` | - | 状态标签 |
| UI-005 | 导航栏 | P0 | 待开发 | `lib/presentation/widgets/layout/app_nav_bar.dart` | - | 响应式 |
| UI-006 | 底部导航 | P0 | 待开发 | `lib/presentation/widgets/layout/bottom_nav_bar.dart` | - | 移动端 |
| UI-007 | 侧边栏 | P1 | 待开发 | `lib/presentation/widgets/layout/app_drawer.dart` | - | 桌面端 |
| UI-008 | 对话框 | P0 | 待开发 | `lib/presentation/widgets/common/app_dialog.dart` | - | 确认/提示 |
| UI-009 | 加载指示器 | P0 | 待开发 | `lib/presentation/widgets/common/loading_spinner.dart` | - | |
| UI-010 | 空状态组件 | P1 | 待开发 | `lib/presentation/widgets/common/empty_state.dart` | - | |

### 赛博朋克风格组件

| ID | 需求描述 | 优先级 | 状态 | Flutter实现 | 备注 |
|----|---------|--------|------|-------------|------|
| UI-CYBER-001 | 霓虹按钮 | P0 | 待开发 | `lib/presentation/widgets/cyber/neon_button.dart` | 发光效果 |
| UI-CYBER-002 | 玻璃卡片 | P0 | 待开发 | `lib/presentation/widgets/cyber/glass_card.dart` | 磨砂玻璃 |
| UI-CYBER-003 | 渐变文字 | P0 | 待开发 | `lib/presentation/widgets/cyber/gradient_text.dart` | |
| UI-CYBER-004 | 背景球体 | P1 | 待开发 | `lib/presentation/widgets/cyber/orb_background.dart` | 动画效果 |
| UI-CYBER-005 | 霓虹边框 | P1 | 待开发 | `lib/presentation/widgets/cyber/neon_border.dart` | |
| UI-CYBER-006 | 网格背景 | P1 | 待开发 | `lib/presentation/widgets/cyber/grid_background.dart` | |

---

## PLATFORM - 平台支持

| ID | 需求描述 | 优先级 | 状态 | Flutter实现 | 测试用例 | 备注 |
|----|---------|--------|------|-------------|---------|------|
| PLAT-001 | Web平台支持 | P0 | 待开发 | - | `test/integration/platform/web_test.dart` | HTML渲染 |
| PLAT-002 | Windows桌面 | P0 | 待开发 | - | `test/integration/platform/windows_test.dart` | |
| PLAT-003 | macOS桌面 | P1 | 待开发 | - | `test/integration/platform/macos_test.dart` | |
| PLAT-004 | Linux桌面 | P2 | 待开发 | - | - | |
| PLAT-005 | Android移动端 | P0 | 待开发 | - | `test/integration/platform/android_test.dart` | |
| PLAT-006 | iOS移动端 | P0 | 待开发 | - | `test/integration/platform/ios_test.dart` | |
| PLAT-007 | 响应式布局 | P0 | 待开发 | `lib/presentation/widgets/responsive/builder.dart` | - | 自适应屏幕 |
| PLAT-008 | 平台特性适配 | P1 | 待开发 | - | - | 文件选择/分享等 |

---

## 📊 状态统计

| 状态 | 数量 | 百分比 |
|------|------|--------|
| 待开发 | 70+ | 100% |
| 开发中 | 0 | 0% |
| 已完成 | 0 | 0% |
| 已测试 | 0 | 0% |
| 已发布 | 0 | 0% |

---

## 🔄 更新日志

| 日期 | 更新内容 | 更新人 |
|------|---------|--------|
| 2026-02-07 | 初始需求矩阵创建 | Claude(AI) |

---

*本文档为项目需求跟踪的核心文档，每次需求变更必须同步更新此文档*
