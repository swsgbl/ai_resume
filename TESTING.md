# 测试和 CI/CD 文档

## 目录

- [测试](#测试)
  - [后端测试](#后端测试)
  - [前端测试](#前端测试)
  - [运行测试](#运行测试)
  - [覆盖率报告](#覆盖率报告)
- [CI/CD](#cicd)
  - [GitHub Actions 工作流](#github-actions-工作流)
  - [环境变量](#环境变量)
  - [部署流程](#部署流程)
- [本地开发](#本地开发)

---

## 测试

### 后端测试

#### 测试文件结构

```
backend/
├── tests/                 # 集成测试
│   ├── __init__.py
│   ├── test_api/         # API 测试
│   └── test_services/    # 服务测试
├── test_*.py             # 单元测试
│   ├── test_resumes.py   # 简历 CRUD 测试
│   ├── test_auth.py      # 认证测试
│   ├── test_database.py  # 数据库测试
│   └── test_xiaomi_final.py  # AI 功能测试
└── run_tests.py          # 测试执行脚本
```

#### 运行后端测试

```bash
cd ~/ai-resume/backend
source venv/bin/activate

# 运行所有测试
pytest tests/ test_*.py -v

# 运行特定测试
pytest test_resumes.py -v

# 运行带覆盖率的测试
pytest tests/ test_*.py --cov=app --cov-report=html --cov-report=term

# 运行快速测试（跳过慢速测试）
pytest tests/ test_*.py -v -m "not slow"

# 运行测试并生成报告
pytest tests/ test_*.py -v --html=report.html

# 使用测试脚本
python run_tests.py
```

#### 测试覆盖率

```bash
# 生成覆盖率报告
pytest tests/ test_*.py --cov=app --cov-report=html

# 查看报告
open htmlcov/index.html

# 生成 XML 报告（用于 CI/CD）
pytest tests/ test_*.py --cov=app --cov-report=xml
```

### 前端测试

#### 测试文件结构

```
ai-resume-web/
├── src/
│   ├── components/
│   │   └── *.test.tsx    # 组件测试
│   └── pages/
│       └── *.test.tsx    # 页面测试
├── tests/                # 集成测试
└── package.json          # 测试配置
```

#### 运行前端测试

```bash
cd ~/ai-resume/ai-resume-web

# 运行所有测试
npm test

# 运行带覆盖率的测试
npm run test:coverage

# 查看覆盖率报告
open coverage/index.html

# 交互式测试
npm run test:ui
```

---

## CI/CD

### GitHub Actions 工作流

#### 工作流文件

```
.github/workflows/ci-cd.yml
```

#### 工作流步骤

1. **Backend Tests**
   - 设置 Python 环境
   - 安装依赖
   - 运行 linting (ruff)
   - 运行类型检查 (mypy)
   - 运行安全扫描 (bandit, safety)
   - 运行测试 (pytest)
   - 上传覆盖率报告

2. **Frontend Tests**
   - 设置 Node.js 环境
   - 安装依赖
   - 运行 linting (ESLint)
   - 运行类型检查
   - 运行测试 (Vitest)
   - 运行安全审计 (npm audit)
   - 构建生产包
   - 上传覆盖率报告

3. **Security Scanning**
   - 运行 Trivy 漏洞扫描
   - 运行 CodeQL 分析

4. **Build & Push**
   - 构建 Docker 镜像
   - 推送到 Docker Hub
   - 使用缓存加速

5. **Deploy**
   - 通过 SSH 部署到生产环境
   - 运行冒烟测试
   - 通知 Slack

#### 触发条件

```yaml
on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]
  workflow_dispatch:  # 手动触发
```

### 环境变量

#### GitHub Secrets

在 GitHub 仓库设置中配置以下 Secrets：

```
# Docker Hub
DOCKER_USERNAME
DOCKER_PASSWORD

# 生产环境
PRODUCTION_HOST
PRODUCTION_USER
SSH_PRIVATE_KEY

# 应用配置
DATABASE_URL
REDIS_URL
SECRET_KEY
XIAOMI_API_KEY

# 通知
SLACK_WEBHOOK
```

#### 本地环境变量

创建 `.env` 文件：

```bash
cd ~/ai-resume/backend
cp .env.example .env
# 编辑 .env 文件
```

### 部署流程

#### 自动部署

1. 推送到 `main` 分支
2. GitHub Actions 自动触发
3. 运行测试和安全扫描
4. 构建 Docker 镜像
5. 推送到生产服务器
6. 运行冒烟测试
7. 通知 Slack

#### 手动部署

```bash
# 触发工作流
gh workflow run ci-cd.yml

# 查看工作流状态
gh run list
gh run view

# 下载构建产物
gh run download
```

---

## 本地开发

### 设置开发环境

#### 后端

```bash
cd ~/ai-resume/backend

# 创建虚拟环境
python -m venv venv
source venv/bin/activate

# 安装依赖
pip install -r requirements.txt
pip install pytest pytest-cov pytest-asyncio pytest-mock

# 初始化数据库
python -m app.init_db

# 启动开发服务器
python -m uvicorn app.main:app --reload
```

#### 前端

```bash
cd ~/ai-resume/ai-resume-web

# 安装依赖
npm install

# 启动开发服务器
npm run dev
```

### 代码质量检查

#### 后端

```bash
cd ~/ai-resume/backend

# 运行 linting
ruff check app/

# 运行类型检查
mypy app/

# 运行安全扫描
bandit -r app/

# 检查依赖漏洞
safety check
```

#### 前端

```bash
cd ~/ai-resume/ai-resume-web

# 运行 linting
npm run lint

# 运行类型检查
npm run type-check

# 运行安全审计
npm audit

# 修复依赖问题
npm audit fix
```

### Docker 开发

```bash
# 使用 Docker Compose
cd ~/ai-resume
docker-compose up -d

# 查看日志
docker-compose logs -f

# 停止服务
docker-compose down

# 重建镜像
docker-compose build

# 清理
docker-compose down -v
```

---

## 最佳实践

### 测试最佳实践

1. **单元测试**: 测试单个函数/方法
2. **集成测试**: 测试多个组件协作
3. **端到端测试**: 测试完整用户流程
4. **覆盖率**: 目标 >70%
5. **命名**: 使用描述性的测试名称

### CI/CD 最佳实践

1. **快速反馈**: 并行运行测试
2. **缓存依赖**: 使用 GitHub Actions 缓存
3. **安全扫描**: 每次提交都运行
4. **渐进式部署**: 先部署到测试环境
5. **监控**: 配置健康检查和告警

### 代码质量

1. **Linting**: 提交前运行
2. **类型检查**: 使用 TypeScript 和 mypy
3. **代码审查**: 所有 PR 必须审查
4. **自动化**: 尽可能自动化检查
5. **文档**: 保持文档更新

---

## 故障排查

### 测试失败

```bash
# 查看详细错误
pytest tests/ -v -s

# 只运行失败的测试
pytest --lf

# 进入调试模式
pytest --pdb

# 查看覆盖率详情
pytest --cov-report=term-missing
```

### CI/CD 失败

1. 查看 GitHub Actions 日志
2. 本地复现失败
3. 修复并提交
4. 重新触发工作流

### 部署失败

```bash
# SSH 到生产服务器
ssh user@production-host

# 查看日志
docker-compose logs -f

# 重启服务
docker-compose restart

# 回滚
docker-compose down
docker-compose pull backend:previous-tag
docker-compose up -d
```

---

## 资源

- [pytest 文档](https://docs.pytest.org/)
- [Vitest 文档](https://vitest.dev/)
- [GitHub Actions 文档](https://docs.github.com/en/actions)
- [Docker 文档](https://docs.docker.com/)
