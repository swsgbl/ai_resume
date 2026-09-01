---
version: "2.0"
name: "AI Resume Design System"
description: "AI 简历智能生成平台设计系统 — 印泥朱砂 + 青瓷绿 + 暖黑宣纸。基于 Vercel/Linear/Stripe/Notion 最佳实践优化，包含完整的色彩、排版、间距、阴影和组件状态规范。"

colors:
  # Primary - Vermillion (印泥朱砂)
  primary-400: "#D4593F"
  primary-500: "#C84B31"
  primary-600: "#A63D28"
  primary-700: "#843220"

  # Accent - Celadon (青瓷绿)
  accent-400: "#A3C49E"
  accent-500: "#8FAE8B"
  accent-600: "#7A9A76"

  # Surface Ladder (4级系统)
  surface-0: "#0C0C0C"  # Canvas
  surface-1: "#161616"  # Default card
  surface-2: "#1E1E1E"  # Important card
  surface-3: "#252525"  # Elevated
  surface-4: "#2A2A2A"  # Modal

  # Text
  text: "#E8E4DE"
  text-secondary: "#8A8580"
  text-muted: "#5A5652"

  # Border
  border: "#252525"
  border-hover: "#5A5652"

  # Semantic
  success-500: "#8FAE8B"
  warning-500: "#D4A041"
  error-500: "#C84B31"
  info-500: "#7A9A76"

typography:
  # Display Tier
  display-xl:
    fontSize: "clamp(48px, 5vw, 80px)"
    fontWeight: 600
    lineHeight: 1.05
    letterSpacing: "-0.03em"
  display-lg:
    fontSize: "clamp(36px, 4vw, 56px)"
    fontWeight: 600
    lineHeight: 1.10
    letterSpacing: "-0.02em"
  display-md:
    fontSize: "clamp(28px, 3vw, 40px)"
    fontWeight: 600
    lineHeight: 1.15
    letterSpacing: "-0.01em"

  # Heading Tier
  heading-xl:
    fontSize: 28px
    fontWeight: 600
    lineHeight: 1.20
    letterSpacing: "-0.006em"
  heading-lg:
    fontSize: 24px
    fontWeight: 500
    lineHeight: 1.25
    letterSpacing: "-0.004em"
  heading-md:
    fontSize: 20px
    fontWeight: 500
    lineHeight: 1.40
    letterSpacing: "-0.002em"

  # Body Tier
  body-lg:
    fontSize: 18px
    fontWeight: 400
    lineHeight: 1.50
    letterSpacing: "-0.001em"
  body-md:
    fontSize: 16px
    fontWeight: 400
    lineHeight: 1.50
    letterSpacing: 0
  body-sm:
    fontSize: 14px
    fontWeight: 400
    lineHeight: 1.50
    letterSpacing: 0

  # Utility Tier
  caption:
    fontSize: 12px
    fontWeight: 400
    lineHeight: 1.40
    letterSpacing: 0
  button:
    fontSize: 14px
    fontWeight: 500
    lineHeight: 1.20
    letterSpacing: 0

spacing:
  base: 4px  # 4px 基准网格
  scale:
    - 2px    # 0.5
    - 4px    # 1
    - 6px    # 1.5
    - 8px    # 2
    - 12px   # 3
    - 16px   # 4
    - 20px   # 5
    - 24px   # 6
    - 32px   # 8
    - 40px   # 10
    - 48px   # 12
    - 64px   # 16
    - 96px   # 24 (section-lg)

rounded:
  xs: 4px
  sm: 6px
  md: 8px
  lg: 12px
  xl: 16px
  full: 9999px

shadows:
  level-0: none  # Flat
  level-1: "0 0 0 1px #252525"  # Hairline
  level-2: "0 0 0 1px #252525, 0 4px 8px -4px rgba(0,0,0,0.3)"  # Subtle
  level-3: "0 0 0 1px #252525, 0 8px 16px -8px rgba(0,0,0,0.4)"  # Medium
  level-4: "0 0 0 1px #252525, 0 16px 32px -16px rgba(0,0,0,0.5)"  # Elevated
  level-5: "0 0 0 1px #252525, 0 24px 48px -24px rgba(0,0,0,0.6)"  # Modal

components:
  button-primary:
    background: "{colors.primary-500}"
    color: "#ffffff"
    typography: "{typography.button}"
    rounded: "{rounded.md}"
    padding: "10px 18px"
    minHeight: 44px
    minWidth: 44px
    shadow: "{shadows.level-1}"
  button-primary-hover:
    background: "{colors.primary-600}"
    shadow: "{shadows.level-2}"
  button-primary-active:
    background: "{colors.primary-700}"
    transform: "scale(0.98)"
  button-primary-disabled:
    background: "{colors.border}"
    color: "{colors.text-muted}"
    cursor: not-allowed
  button-primary-focus:
    boxShadow: "0 0 0 2px {colors.surface-0}, 0 0 0 4px {colors.primary-500}"

  button-secondary:
    background: transparent
    color: "{colors.text}"
    border: "1px solid {colors.border}"
    typography: "{typography.button}"
    rounded: "{rounded.md}"
    padding: "10px 18px"
    minHeight: 44px
    minWidth: 44px
  button-secondary-hover:
    borderColor: "{colors.border-hover}"
    background: "rgba(255,255,255,0.03)"
    shadow: "{shadows.level-1}"

  button-ghost:
    background: transparent
    color: "{colors.text-secondary}"
    typography: "{typography.button}"
    rounded: "{rounded.md}"
    padding: "10px 18px"
    minHeight: 44px
    minWidth: 44px
  button-ghost-hover:
    color: "{colors.text}"
    background: "rgba(255,255,255,0.05)"

  input-default:
    background: "{colors.surface-1}"
    color: "{colors.text}"
    border: "none"
    borderBottom: "1px solid {colors.border}"
    typography: "{typography.body-md}"
    rounded: 0
    padding: "8px 16px"
    minHeight: 44px
  input-focus:
    borderBottomColor: "{colors.primary-500}"
    boxShadow: "0 1px 0 0 {colors.primary-500}, 0 0 0 3px rgba(200,75,49,0.15)"
  input-error:
    borderBottomColor: "{colors.error-500}"
  input-success:
    borderBottomColor: "{colors.success-500}"

  card-default:
    background: "{colors.surface-1}"
    border: "1px solid {colors.border}"
    rounded: "{rounded.lg}"
    padding: "24px"
    shadow: "{shadows.level-1}"
  card-elevated:
    background: "{colors.surface-2}"
    border: "1px solid {colors.border-hover}"
    rounded: "{rounded.lg}"
    padding: "24px"
    shadow: "{shadows.level-2}"

---

## 概述

AI Resume 设计系统基于"印泥朱砂 + 青瓷绿 + 暖黑宣纸"的东方美学理念，融合现代 SaaS 产品的最佳实践。系统参考了 Vercel 的极简主义、Linear 的层级深度、Stripe 的优雅渐变和 Notion 的多彩卡片，形成了一套完整、一致、可扩展的设计规范。

### 核心特征

- **暗色主题优先**: 采用 #0C0C0C 作为基础 Canvas，营造沉浸式体验
- **4px 基准网格**: 所有间距基于 4px 倍数，确保视觉节奏一致
- **4级表面层级**: 通过亮度和阴影变化建立清晰的层级关系
- **完整的状态系统**: 每个组件都包含 default/hover/active/focus/disabled 状态
- **WCAG AAA 合规**: 所有交互元素最小 44×44px，确保可访问性

---

## 色彩系统

### 品牌色

| Token | 值 | 用途 |
|-------|-----|------|
| `primary-500` | #C84B31 | 主要 CTA、品牌标识 |
| `primary-600` | #A63D28 | 悬停状态 |
| `primary-700` | #843220 | 按下/禁用状态 |

### 辅助色

| Token | 值 | 用途 |
|-------|-----|------|
| `accent-500` | #8FAE8B | 成功状态、次要操作 |
| `accent-600` | #7A9A76 | 悬停状态 |

### 表面层级

| Token | 值 | 用途 |
|-------|-----|------|
| `surface-0` | #0C0C0C | 页面背景 (Canvas) |
| `surface-1` | #161616 | 默认卡片 |
| `surface-2` | #1E1E1E | 重要卡片 |
| `surface-3` | #252525 | 悬浮层 |
| `surface-4` | #2A2A2A | 模态框 |

### 语义色

| Token | 值 | 用途 |
|-------|-----|------|
| `success-500` | #8FAE8B | 成功状态 |
| `warning-500` | #D4A041 | 警告状态 |
| `error-500` | #C84B31 | 错误状态 |
| `info-500` | #7A9A76 | 信息提示 |

---

## 排版系统

### 字体族

- **Sans**: DM Sans, Noto Sans SC, Inter, system-ui
- **Serif**: Playfair Display, Noto Serif SC, Georgia
- **Mono**: JetBrains Mono, monospace

### Display Tier (大标题)

| Token | 大小 | 字重 | 行高 | 字距 |
|-------|------|------|------|------|
| `display-xl` | 48-80px | 600 | 1.05 | -0.03em |
| `display-lg` | 36-56px | 600 | 1.10 | -0.02em |
| `display-md` | 28-40px | 600 | 1.15 | -0.01em |

### Heading Tier (标题)

| Token | 大小 | 字重 | 行高 | 字距 |
|-------|------|------|------|------|
| `heading-xl` | 28px | 600 | 1.20 | -0.006em |
| `heading-lg` | 24px | 500 | 1.25 | -0.004em |
| `heading-md` | 20px | 500 | 1.40 | -0.002em |

### Body Tier (正文)

| Token | 大小 | 字重 | 行高 | 字距 |
|-------|------|------|------|------|
| `body-lg` | 18px | 400 | 1.50 | -0.001em |
| `body-md` | 16px | 400 | 1.50 | 0 |
| `body-sm` | 14px | 400 | 1.50 | 0 |

---

## 间距系统

基于 4px 网格，所有间距值为 4px 的倍数：

| Token | 值 | 用途 |
|-------|-----|------|
| `1` | 4px | 最小间距 |
| `2` | 8px | 紧凑间距 |
| `3` | 12px | 小间距 |
| `4` | 16px | 默认间距 |
| `6` | 24px | 中等间距 |
| `8` | 32px | 大间距 |
| `12` | 48px | Section 间距 |
| `16` | 64px | 大 Section 间距 |
| `24` | 96px | 超大 Section 间距 |

---

## 阴影系统

| 级别 | 值 | 用途 |
|------|-----|------|
| `0` | none | 扁平 |
| `1` | `0 0 0 1px #252525` | 发丝边框 |
| `2` | `0 0 0 1px #252525, 0 4px 8px -4px rgba(0,0,0,0.3)` | 微弱提升 |
| `3` | `0 0 0 1px #252525, 0 8px 16px -8px rgba(0,0,0,0.4)` | 中等提升 |
| `4` | `0 0 0 1px #252525, 0 16px 32px -16px rgba(0,0,0,0.5)` | 显著提升 |
| `5` | `0 0 0 1px #252525, 0 24px 48px -24px rgba(0,0,0,0.6)` | 模态层级 |

---

## 组件状态规范

### 按钮

每个按钮包含以下状态：
- `default` - 默认状态
- `hover` - 鼠标悬停
- `active` - 按下状态
- `focus` - 键盘聚焦
- `disabled` - 禁用状态

### 表单输入

- `default` - 默认状态
- `hover` - 鼠标悬停
- `focus` - 输入聚焦
- `error` - 错误状态
- `success` - 成功状态
- `disabled` - 禁用状态

---

## 响应式断点

Mobile First 策略：

| Token | 宽度 | 设备 |
|-------|------|------|
| `xs` | 375px | 小屏手机 |
| `sm` | 480px | 大屏手机 |
| `md` | 768px | 平板竖屏 |
| `lg` | 1024px | 平板横屏 |
| `xl` | 1280px | 桌面 |
| `2xl` | 1440px | 大屏桌面 |
| `3xl` | 1920px | 超宽屏 |

---

## 可访问性

### Touch Target

- 所有交互元素最小 44×44px
- 舒适触摸目标 48×48px

### 键盘导航

- 所有交互元素支持键盘访问
- Focus ring 使用 2-4px 描边
- Focus visible 仅在键盘导航时显示

### 颜色对比

- 所有文本与背景对比度 ≥ 4.5:1 (WCAG AA)
- 重要文本对比度 ≥ 7:1 (WCAG AAA)

---

## Do's and Don'ts

### Do

- 使用 4px 倍数作为间距基准
- 为所有交互元素提供完整的状态
- 确保所有按钮 ≥44×44px
- 使用表面层级建立深度
- 为表单输入提供清晰的错误反馈

### Don't

- 不要使用非 4px 倍数的间距
- 不要跳过表面层级 (直接从 surface-0 到 surface-3)
- 不要让交互元素小于 44×44px
- 不要仅依赖颜色传达状态信息
- 不要忽略 disabled 状态的视觉反馈

---

## 更新日志

### v2.0 (2025-05-20)

- ✨ 新增 4级表面层级系统
- ✨ 新增 5级阴影系统
- ✨ 新增完整组件状态规范
- ✨ 新增语义颜色系统
- ✨ 新增 4px 间距基准网格
- ✨ 新增负字距规范
- ✨ 新增 Touch Target 标准
- 🐛 修复按钮 disabled 状态缺失
- 🐛 修复表单输入状态不完整
- 📚 创建完整的设计文档

### v1.0

- 初始设计系统
- 基础色彩和排版规范
