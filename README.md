# AI 简历智能生成平台

<div align="center">

![AI Resume Logo](docs/logo.png)

**AI 驱动的智能简历生成平台**

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![TypeScript](https://img.shields.io/badge/TypeScript-5.3-blue)](https://www.typescriptlang.org/)
[![React](https://img.shields.io/badge/React-18.2-blue)](https://reactjs.org/)
[![Python](https://img.shields.io/badge/Python-3.11-green)](https://www.python.org/)
[![FastAPI](https://img.shields.io/badge/FastAPI-0.109-green)](https://fastapi.tiangolo.com/)

[在线演示](#) • [快速开始](#快速开始) • [文档](#文档) • [贡献](#贡献)

</div>

---

## 项目简介

AI 简历智能生成平台是一个全栈 Web 应用，利用前沿 AI 技术帮助用户快速创建专业简历。支持多种 AI 模型，提供丰富的模板库，支持多种格式导出。

### 核心功能

- **🤖 AI 智能生成** - 支持多种 AI 模型（OpenAI GPT-4、DeepSeek、小米 MiMo）
- **📝 简历编辑** - 所见即所得的简历编辑器，实时预览
- **🎨 精美模板** - 50+ 专业设计的简历模板
- **📤 多格式导出** - 支持 PDF、Word、HTML 格式导出
- **🔐 安全认证** - JWT 认证、邮箱验证、微信登录
- **📱 响应式设计** - 完美适配桌面和移动设备

---

## 技术栈

### 前端
- **框架**: React 18 + TypeScript
- **构建**: Vite 5
- **样式**: TailwindCSS
- **路由**: React Router v6
- **状态管理**: Zustand
- **数据请求**: TanStack Query
- **测试**: Playwright

### 后端
- **框架**: FastAPI (Python 3.11)
- **数据库**: SQLite (开发) / MySQL (生产)
- **ORM**: SQLAlchemy 2.0 (异步)
- **认证**: JWT + OAuth2
- **AI 集成**: OpenAI / DeepSeek / 小米 MiMo
- **文档生成**: WeasyPrint

### 桌面版
- **框架**: Tauri + Rust
- **复用**: 所有前端代码

---

## 项目结构

```
ai_resume/
├── backend/                # FastAPI 后端
│   ├── app/
│   │   ├── api/v1/        # API 路由
│   │   ├── core/          # 核心配置
│   │   ├── models/        # 数据模型
│   │   ├── schemas/       # Pydantic 模式
│   │   └── services/      # 业务逻辑
│   ├── tests/             # 后端测试
│   └── requirements.txt   # Python 依赖
│
├── ai-resume-web/         # React 前端
│   ├── src/
│   │   ├── components/    # UI 组件
│   │   ├── pages/         # 页面组件
│   │   ├── store/         # 状态管理
│   │   └── main.tsx       # 应用入口
│   ├── tests/             # E2E 测试
│   └── package.json       # 前端依赖
│
├── ai-resume-desktop/     # Tauri 桌面版
│   ├── src/               # 前端代码 (同 web)
│   └── src-tauri/         # Rust 后端
│
├── ai-resume-shared/      # 共享代码
│   └── src/
│       ├── types/         # TypeScript 类型
│       ├── api/           # API 客户端
│       └── utils/         # 工具函数
│
├── docker-compose.yml     # Docker 编排
├── DEPLOYMENT.md          # 部署文档
└── README.md              # 本文件
```

---

## 快速开始

### 方式一：Docker 部署（推荐）

```bash
# 1. 克隆项目
git clone https://github.com/your-repo/ai_resume.git
cd ai_resume

# 2. 配置环境变量（可选）
cp backend/.env.example backend/.env
# 编辑 backend/.env 填入必要的配置

# 3. 启动服务
docker-compose up -d

# 4. 访问应用
# 前端: http://localhost
# 后端: http://localhost:8000
# API 文档: http://localhost:8000/docs
```

### 方式二：本地开发

#### 1. 启动后端

```bash
cd backend

# 创建虚拟环境
python -m venv venv
source venv/bin/activate  # Linux/Mac
# venv\Scripts\activate   # Windows

# 安装依赖
pip install -r requirements.txt

# 配置环境变量
cp .env.example .env

# 启动服务
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

#### 2. 启动前端

```bash
cd ai-resume-web

# 安装依赖
npm install

# 启动开发服务器
npm run dev
```

访问 http://localhost:3000

---

## 环境配置

### 后端环境变量 (backend/.env)

```bash
# 应用配置
DEBUG=true
SECRET_KEY=your-super-secret-key-change-in-production

# 数据库 (默认使用 SQLite)
USE_SQLITE=true
DATABASE_URL=sqlite+aiosqlite:///./ai_resume.db

# AI 模型配置
OPENAI_API_KEY=sk-your-openai-api-key
DEEPSEEK_API_KEY=sk-your-deepseek-api-key
XIAOMI_API_KEY=your-xiaomi-api-key
DEFAULT_AI_PROVIDER=openai
```

### 前端环境变量 (ai-resume-web/.env.development)

```bash
# API 地址
VITE_API_BASE_URL=http://127.0.0.1:8000/api/v1

# 调试模式
VITE_DEBUG=true
```

---

## 构建部署

### 前端构建

```bash
cd ai-resume-web
npm run build

# 输出: dist/ 目录
```

### 桌面版构建

```bash
cd ai-resume-desktop
npm run tauri:build

# 输出: src-tauri/target/release/
```

---

## 测试

### E2E 测试

```bash
cd ai-resume-web

# 运行所有测试
npx playwright test

# 运行带 UI 的测试
npx playwright test --ui

# 运行 headed 模式
npx playwright test --headed
```

---

## 部署指南

详细的部署文档请参考 [DEPLOYMENT.md](DEPLOYMENT.md)

### 生产环境检查清单

- [ ] 修改 `SECRET_KEY` 为强随机值
- [ ] 设置 `DEBUG=false`
- [ ] 配置 MySQL 数据库
- [ ] 配置正确的 CORS 源
- [ ] 启用 HTTPS
- [ ] 配置 AI API Keys
- [ ] 设置日志轮转
- [ ] 配置备份策略

---

## 贡献指南

欢迎贡献！请遵循以下步骤：

1. Fork 本仓库
2. 创建特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'feat: Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 开启 Pull Request

### 开发规范

- 遵循 [Conventional Commits](https://www.conventionalcommits.org/) 规范
- 代码需通过类型检查 (`tsc --noEmit`)
- 新功能需添加测试
- 遵循现有代码风格

---

## 常见问题

<details>
<summary>如何更换 AI 模型？</summary>

在设置页面中可以选择不同的 AI 提供商，或在后端 `.env` 文件中修改 `DEFAULT_AI_PROVIDER`。
</details>

<details>
<summary>支持哪些导出格式？</summary>

目前支持 PDF、Word (docx) 和 HTML 格式导出。
</details>

<details>
<summary>如何部署到生产环境？</summary>

请参考 [DEPLOYMENT.md](DEPLOYMENT.md) 获取详细的部署指南。
</details>

<details>
<summary>如何从 SQLite 迁移到 MySQL？</summary>

请参考 [MYSQL_MIGRATION_GUIDE.md](MYSQL_MIGRATION_GUIDE.md) 或使用一键迁移脚本:

```bash
./scripts/migrate-to-mysql.sh
```
</details>

---

## 路线图

- [x] 基础简历编辑功能
- [x] AI 智能生成
- [x] 多模板支持
- [x] 多格式导出
- [x] 邮箱验证
- [x] 微信登录
- [ ] 简历解析 (从 PDF/Word 导入)
- [ ] 在线协作编辑
- [ ] 简历 AI 分析和建议
- [ ] 更多 AI 提供商

---

## 许可证

本项目采用 MIT 许可证 - 详见 [LICENSE](LICENSE) 文件

---

## 联系方式

- 项目主页: [https://github.com/your-repo/ai_resume](https://github.com/your-repo/ai_resume)
- 问题反馈: [Issues](https://github.com/your-repo/ai_resume/issues)
- 邮箱: support@example.com

---

<div align="center">

**如果这个项目对你有帮助，请给一个 ⭐️ Star**

Made with ❤️ by AI Resume Team

</div>
