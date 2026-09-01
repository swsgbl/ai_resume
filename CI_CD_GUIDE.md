# CI/CD 流程搭建指南

本文档描述 AI Resume Platform 的 CI/CD 流程配置和使用说明。

---

## 概述

CI/CD 流程分为两个主要部分：

1. **CI (持续集成)** - `.github/workflows/ci.yml`
   - 代码质量检查 (ESLint, Black, Flake8)
   - 单元测试 (Vitest, Pytest)
   - E2E 测试 (Playwright)
   - 安全扫描 (CodeQL, Trivy)
   - Docker 构建验证

2. **CD (持续部署)** - `.github/workflows/cd.yml`
   - Docker 镜像构建和推送
   - 自动部署到 Staging 环境
   - 手动触发部署到 Production
   - 创建 GitHub Release
   - 自动回滚机制

---

## 触发条件

### CI 流程

| 触发方式 | 说明 |
|---------|------|
| Push 到 main/develop | 自动运行完整 CI |
| Pull Request | 自动运行检查和测试 |
| 手动触发 | GitHub Actions 页面 |

### CD 流程

| 触发方式 | 环境 |
|---------|------|
| Push Tag (v*) | Production |
| 手动触发 | Staging / Production |

---

## 工作流详解

### CI 工作流

```
┌─────────────────────────────────────────────────────────────────┐
│                        CI Pipeline                              │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐         │
│  │  前端检查     │  │  后端检查     │  │  安全扫描     │         │
│  │  - ESLint    │  │  - Black     │  │  - CodeQL    │         │
│  │  - TSC       │  │  - Flake8    │  │  - Trivy     │         │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘         │
│         │                 │                 │                  │
│         ▼                 ▼                 ▼                  │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐         │
│  │  前端测试     │  │  后端测试     │  │  Docker构建  │         │
│  │  - Vitest    │  │  - Pytest    │  │  - 镜像验证  │         │
│  │  - Playwright│  │  - Coverage  │  │  - 安全扫描  │         │
│  └──────────────┘  └──────────────┘  └──────────────┘         │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### CD 工作流

```
┌─────────────────────────────────────────────────────────────────┐
│                        CD Pipeline                              │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌──────────────┐                                              │
│  │  构建镜像     │                                              │
│  │  - Frontend  │                                              │
│  │  - Backend   │                                              │
│  └──────┬───────┘                                              │
│         │                                                      │
│         ▼                                                      │
│  ┌──────────────┐                                              │
│  │  推送镜像     │                                              │
│  │  - ghcr.io   │                                              │
│  └──────┬───────┘                                              │
│         │                                                      │
│         ├─────────────┐                                        │
│         ▼             ▼                                        │
│  ┌──────────────┐ ┌──────────────┐                            │
│  │ Staging 部署 │ │Production部署 │                            │
│  │ (自动)       │ │ (手动/Tag)    │                            │
│  └──────────────┘ └──────┬───────┘                            │
│                          │                                      │
│                          ▼                                      │
│                   ┌──────────────┐                             │
│                   │ 健康检查      │                             │
│                   │ 冒烟测试      │                             │
│                   └──────┬───────┘                             │
│                          │                                      │
│                    ┌─────┴─────┐                               │
│                    ▼           ▼                               │
│              ┌─────────┐ ┌─────────┐                           │
│              │ 成功    │ │失败回滚 │                           │
│              └─────────┘ └─────────┘                           │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## GitHub Secrets 配置

在 GitHub 仓库设置中添加以下 Secrets：

| Secret 名称 | 说明 | 示例 |
|-------------|------|------|
| `KUBECONFIG_STAGING` | Staging 环境的 kubeconfig (base64) | `...` |
| `KUBECONFIG_PROD` | Production 环境的 kubeconfig (base64) | `...` |
| `SLACK_WEBHOOK` | Slack 通知 Webhook URL | `https://hooks.slack.com/...` |
| `SENTRY_AUTH_TOKEN` | Sentry 认证 Token | `...` |
| `CODECOV_TOKEN` | Codecov 上传 Token | `...` |

### 生成 kubeconfig

```bash
# 生成 base64 编码的 kubeconfig
cat ~/.kube/config | base64 -w 0
```

---

## 本地开发

### 使用 Docker Compose 启动开发环境

```bash
# 启动所有服务
docker-compose -f docker-compose.ci.yml up -d

# 查看日志
docker-compose -f docker-compose.ci.yml logs -f

# 停止服务
docker-compose -f docker-compose.ci.yml down
```

### 本地运行 CI 检查

```bash
# 前端检查
cd ai-resume-web
npm run lint
npm run test:unit
npm run test

# 后端检查
cd backend
black --check app/
flake8 app/
pytest tests/ -v
```

---

## 部署流程

### Staging 部署

Staging 环境在以下情况自动部署：

1. 代码合并到 `main` 分支
2. CI 检查全部通过
3. Docker 镜像成功构建并推送

### Production 部署

Production 部署需要手动触发或通过 Tag：

#### 方式 1: 创建 Git Tag

```bash
# 创建版本 Tag
git tag -a v1.0.0 -m "Release version 1.0.0"
git push origin v1.0.0
```

#### 方式 2: GitHub Actions 手动触发

1. 进入 GitHub 仓库的 Actions 页面
2. 选择 "AI Resume Platform - CD" 工作流
3. 点击 "Run workflow"
4. 选择 `production` 环境
5. 点击 "Run workflow"

---

## 回滚机制

如果部署失败，系统会自动回滚：

```bash
# 手动回滚 (如果需要)
kubectl rollout undo deployment/ai-resume-web -n ai-resume-prod
kubectl rollout undo deployment/ai-resume-backend -n ai-resume-prod

# 查看回滚历史
kubectl rollout history deployment/ai-resume-web -n ai-resume-prod
```

---

## 监控和日志

### 查看部署状态

```bash
# Staging 环境
kubectl get pods -n ai-resume-staging
kubectl logs -f deployment/ai-resume-backend -n ai-resume-staging

# Production 环境
kubectl get pods -n ai-resume-prod
kubectl logs -f deployment/ai-resume-backend -n ai-resume-prod
```

### 健康检查

```bash
# 后端健康检查
curl https://staging.ai-resume.example.com/health
curl https://ai-resume.example.com/health
```

---

## 故障排查

### CI 失败

1. 查看 Actions 日志确定失败步骤
2. 本地复现问题
3. 修复后推送新 commit

### CD 失败

1. 检查 Docker 镜像是否成功推送
2. 检查 Kubernetes 集群连接
3. 检查 Secrets 配置是否正确
4. 查看 kubectl 执行日志

### 部署后问题

1. 检查 pod 日志
2. 检查健康检查端点
3. 必要时执行手动回滚

---

## 最佳实践

1. **分支策略**
   - `develop` - 开发分支
   - `main` - 预发布分支
   - `feature/*` - 功能分支

2. **Commit 规范**
   ```
   feat: 添加新功能
   fix: 修复 Bug
   docs: 更新文档
   test: 添加测试
   chore: 构建/工具链更新
   ```

3. **版本规范** (语义化版本)
   ```
   v1.0.0 - 主版本.次版本.补丁版本
   ```

4. **发布前检查清单**
   - [ ] 所有 CI 检查通过
   - [ ] 代码覆盖率 > 80%
   - [ ] 安全扫描无高危问题
   - [ ] E2E 测试通过
   - [ ] 更新 CHANGELOG

---

## 附录

### 相关文档

- [TECHNICAL_AUDIT_REPORT.md](./TECHNICAL_AUDIT_REPORT.md) - 技术审计报告
- [DEPLOYMENT.md](./DEPLOYMENT.md) - 部署指南

### 工具链接

- [GitHub Actions](https://github.com/features/actions)
- [Docker Hub](https://hub.docker.com/)
- [Kubernetes 文档](https://kubernetes.io/docs/)
- [Playwright](https://playwright.dev/)
