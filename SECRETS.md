# GitHub Secrets 配置指南

## 必需的 Secrets

### 1. Docker Hub 认证

用于推送 Docker 镜像。

```
DOCKER_USERNAME: your-dockerhub-username
DOCKER_PASSWORD: your-dockerhub-password-or-token
```

**创建步骤**:
1. 访问 https://hub.docker.com/
2. 注册/登录账户
3. 进入 Account Settings → Security → Access Tokens
4. 创建新的 Access Token
5. 在 GitHub 仓库设置中添加 Secrets

### 2. 生产环境 SSH 访问

用于部署到生产服务器。

```
PRODUCTION_HOST: your-production-server.com
PRODUCTION_USER: deploy
SSH_PRIVATE_KEY: -----BEGIN OPENSSH PRIVATE KEY-----
                   ...
                   -----END OPENSSH PRIVATE KEY-----
```

**创建步骤**:
1. 在生产服务器上创建 SSH 密钥
   ```bash
   ssh-keygen -t rsa -b 4096 -C "github-actions" -f ~/.ssh/github_actions
   ```
2. 将公钥添加到服务器的 `~/.ssh/authorized_keys`
3. 复制私钥内容
4. 在 GitHub 仓库设置中添加 Secret

**注意**: 确保 SSH Private Key 包含完整的 `-----BEGIN OPENSSH PRIVATE KEY-----` 和 `-----END OPENSSH PRIVATE KEY-----` 标记。

### 3. 应用环境变量

```
DATABASE_URL: mysql+aiomysql://user:password@localhost:3306/ai_resume
REDIS_URL: redis://localhost:6379
SECRET_KEY: your-secret-key-min-32-characters-long
XIAOMI_API_KEY: sk-c0uo5p7vq8h9p0fm45978gvkky3dgtbhn68uai4y2pnyt12o
```

**创建步骤**:
1. 生成随机 SECRET_KEY
   ```bash
   python -c "import secrets; print(secrets.token_urlsafe(32))"
   ```
2. 使用实际的数据库 URL
3. 使用小米 API Key（已提供）
4. 在 GitHub 仓库设置中添加 Secrets

### 4. SMTP 配置（可选）

用于发送邮件通知。

```
SMTP_HOST: smtp.gmail.com
SMTP_PORT: 587
SMTP_USER: your-email@gmail.com
SMTP_PASSWORD: your-app-password
```

**创建步骤**:
1. 在 Google 账户设置中启用 2FA
2. 创建应用专用密码
3. 添加到 GitHub Secrets

### 5. Slack Webhook（可选）

用于部署通知。

```
SLACK_WEBHOOK: https://hooks.slack.com/services/XXX/YYY/ZZZ
```

**创建步骤**:
1. 在 Slack 中创建 Incoming Webhook
2. 复制 Webhook URL
3. 添加到 GitHub Secrets

---

## 配置步骤

### 步骤 1: 进入 GitHub 仓库设置

1. 打开 GitHub 仓库
2. 点击 "Settings" 标签
3. 在左侧菜单中选择 "Secrets and variables" → "Actions"
4. 点击 "New repository secret"

### 步骤 2: 添加 Secrets

逐个添加以下 Secrets:

| Name | Value | Required |
|------|-------|----------|
| `DOCKER_USERNAME` | Docker Hub 用户名 | ✅ |
| `DOCKER_PASSWORD` | Docker Hub 密码/Token | ✅ |
| `PRODUCTION_HOST` | 生产服务器地址 | ✅ |
| `PRODUCTION_USER` | SSH 用户名 | ✅ |
| `SSH_PRIVATE_KEY` | SSH 私钥 | ✅ |
| `DATABASE_URL` | 数据库 URL | ✅ |
| `REDIS_URL` | Redis URL | ✅ |
| `SECRET_KEY` | 应用密钥 | ✅ |
| `XIAOMI_API_KEY` | 小米 API Key | ✅ |
| `SMTP_HOST` | SMTP 服务器 | ⚠️ |
| `SMTP_PORT` | SMTP 端口 | ⚠️ |
| `SMTP_USER` | SMTP 用户 | ⚠️ |
| `SMTP_PASSWORD` | SMTP 密码 | ⚠️ |
| `SLACK_WEBHOOK` | Slack Webhook | ⚠️ |

### 步骤 3: 验证配置

1. 推送代码到 GitHub
2. 查看 Actions 标签
3. 检查工作流是否成功运行

---

## 环境变量说明

### 必需变量

**DATABASE_URL**
```
格式: mysql+aiomysql://user:password@host:port/database
示例: mysql+aiomysql://airesume:password@localhost:3306/ai_resume
```

**REDIS_URL**
```
格式: redis://host:port
示例: redis://localhost:6379
```

**SECRET_KEY**
```
要求: 至少 32 个字符的随机字符串
生成: python -c "import secrets; print(secrets.token_urlsafe(32))"
```

**XIAOMI_API_KEY**
```
提供: sk-c0uo5p7vq8h9p0fm45978gvkky3dgtbhn68uai4y2pnyt12o
```

### 可选变量

**SMTP_***
- 用于发送邮件通知
- 建议使用 Gmail App Password

**SLACK_WEBHOOK**
- 用于部署通知
- 可在 Slack Apps 中创建

---

## 本地开发配置

### 1. 创建 .env 文件

```bash
cd ~/ai-resume/backend
cp .env.example .env
```

### 2. 编辑 .env 文件

```bash
DATABASE_URL=sqlite+aiosqlite:///./data/ai_resume.db
REDIS_URL=redis://localhost:6379
SECRET_KEY=local-development-secret-key-32-chars
XIAOMI_API_KEY=sk-c0uo5p7vq8h9p0fm45978gvkky3dgtbhn68uai4y2pnyt12o
DEBUG=true
```

### 3. 启动开发服务器

```bash
make dev
```

---

## 故障排查

### 问题 1: Docker Hub 推送失败

**原因**: Docker Hub 凭据错误

**解决**:
1. 检查 DOCKER_USERNAME 和 DOCKER_PASSWORD 是否正确
2. 重新生成 Docker Hub Access Token
3. 更新 GitHub Secrets

### 问题 2: SSH 连接失败

**原因**: SSH 密钥配置错误

**解决**:
1. 确保 SSH_PRIVATE_KEY 包含完整的密钥
2. 检查服务器上的 `~/.ssh/authorized_keys`
3. 测试 SSH 连接: `ssh -i private-key user@host`

### 问题 3: 数据库连接失败

**原因**: DATABASE_URL 格式错误

**解决**:
1. 检查 URL 格式: `mysql+aiomysql://user:password@host:port/database`
2. 确认数据库用户名和密码
3. 确认数据库服务正在运行

### 问题 4: 工作流失败

**原因**: Secrets 未配置或配置错误

**解决**:
1. 检查所有必需的 Secrets 是否已配置
2. 查看 Actions 日志获取详细错误
3. 本地复现问题

---

## 安全最佳实践

1. **不要提交 .env 文件** → 添加到 .gitignore
2. **使用强密钥** → SECRET_KEY 至少 32 个字符
3. **定期轮换密钥** → 每季度更新一次
4. **限制访问权限** → 只授权必要的 Secrets
5. **监控使用情况** → 定期检查 Actions 日志

---

## 完成检查清单

- [ ] Docker Hub 账户已创建
- [ ] Docker Hub Access Token 已创建
- [ ] DOCKER_USERNAME 已添加
- [ ] DOCKER_PASSWORD 已添加
- [ ] 生产服务器 SSH 密钥已创建
- [ ] SSH_PRIVATE_KEY 已添加
- [ ] PRODUCTION_HOST 已添加
- [ ] PRODUCTION_USER 已添加
- [ ] DATABASE_URL 已添加
- [ ] REDIS_URL 已添加
- [ ] SECRET_KEY 已添加
- [ ] XIAOMI_API_KEY 已添加
- [ ] （可选）SMTP 配置已添加
- [ ] （可选）SLACK_WEBHOOK 已添加
- [ ] 工作流已成功运行
- [ ] 部署测试成功

---

**下一步**: 选项 C - 准备生产部署
