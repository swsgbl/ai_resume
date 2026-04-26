# 步骤3: 配置AI智能体简历后端服务

## 服务信息

- **服务名称**: ai-resume-backend
- **服务类型**: Docker Compose
- **容器名称**: ai-resume-backend
- **端口映射**: 8001:8000
- **健康检查**: /health 端点

## Dokploy配置步骤

### 3.1 创建新服务

1. 在Dokploy面板中，进入 **"AI智能体简历"** 项目
2. 点击 **"Create Service"** 按钮
3. 选择 **"Docker Compose"** 类型
4. 填写基本信息:

```
Name: ai-resume-backend
Type: Docker Compose
```

### 3.2 配置Docker Compose

在 **"Docker Compose Configuration"** 中填入:

```yaml
version: '3.8'

services:
  ai-resume-backend:
    build:
      context: ./backend
      dockerfile: Dockerfile
    container_name: ai-resume-backend
    restart: unless-stopped
    ports:
      - "8001:8000"
    environment:
      - SECRET_KEY=${SECRET_KEY}
      - DEBUG=False
      - HOST=0.0.0.0
      - PORT=8000
      - USE_SQLITE=True
      - REDIS_URL=redis://ai-resume-redis:6379/0
      - DEFAULT_AI_PROVIDER=deepseek
      - DEEPSEEK_API_KEY=${DEEPSEEK_API_KEY}
      - DEEPSEEK_MODEL=deepseek-chat
      - DEEPSEEK_BASE_URL=https://api.deepseek.com
      - SMTP_HOST=${SMTP_HOST}
      - SMTP_PORT=587
      - SMTP_USER=${SMTP_USER}
      - SMTP_PASSWORD=${SMTP_PASSWORD}
    volumes:
      - ./backend/data.db:/app/data.db
      - ./backend/ai_resume.db:/app/ai_resume.db
      - ./backend/logs:/app/logs
    depends_on:
      - ai-resume-redis
    networks:
      - ai-resume-network
    healthcheck:
      test: ["CMD", "python", "-c", "import urllib.request; urllib.request.urlopen('http://localhost:8000/health')"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 5s

  ai-resume-redis:
    image: redis:7-alpine
    container_name: ai-resume-redis
    restart: unless-stopped
    command: redis-server --appendonly yes
    volumes:
      - redis-data:/data
    networks:
      - ai-resume-network
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 5s
      retries: 3

networks:
  ai-resume-network:
    driver: bridge

volumes:
  redis-data:
```

### 3.3 配置环境变量

在 **"Environment Variables"** 部分添加:

```bash
# 应用配置
SECRET_KEY=your-secret-key-here-change-in-production
DEBUG=False
HOST=0.0.0.0
PORT=8000
USE_SQLITE=True

# AI配置
DEFAULT_AI_PROVIDER=deepseek
DEEPSEEK_API_KEY=your-deepseek-api-key
DEEPSEEK_MODEL=deepseek-chat
DEEPSEEK_BASE_URL=https://api.deepseek.com

# SMTP邮件配置
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=your-email@gmail.com
SMTP_PASSWORD=your-app-password

# Redis配置
REDIS_URL=redis://ai-resume-redis:6379/0
```

**重要**: 请将以下占位符替换为实际值:
- `your-secret-key-here-change-in-production`: 生成一个强随机密钥
- `your-deepseek-api-key`: DeepSeek API密钥
- `your-email@gmail.com`: SMTP邮箱地址
- `your-app-password`: Gmail应用专用密码

### 3.4 配置构建设置

在 **"Build Settings"** 中:

```yaml
Dockerfile Path: ./backend/Dockerfile
Build Context: ./
Docker Compose Path: docker-compose.yml
```

### 3.5 端口配置

**容器端口**: 8000
**主机端口**: 8001
**协议**: TCP

### 3.6 健康检查配置

```yaml
Endpoint: /health
Interval: 30 seconds
Timeout: 10 seconds
Retries: 3
Start Period: 5 seconds
```

### 3.7 部署配置

- **自动部署**: 启用 (当main分支有新推送时)
- **部署策略**: Rolling Update (滚动更新)
- **副本数量**: 1

### 3.8 保存并部署

1. 点击 **"Save"** 保存配置
2. 点击 **"Deploy"** 开始部署
3. 观察部署日志，确保构建和启动成功

## 验证部署

部署完成后，运行以下命令验证:

```bash
# 检查容器状态
ssh -i ~/.ssh/id_ed25519 root@113.45.64.145 "docker ps | grep ai-resume-backend"

# 检查健康端点
curl http://113.45.64.145:8001/health

# 检查容器日志
ssh -i ~/.ssh/id_ed25519 root@113.45.64.145 "docker logs ai-resume-backend --tail 20"
```

预期结果:
- 容器状态为 `Up`
- 健康检查返回 `{"status": "healthy"}`
- 日志中无错误信息

## 故障排查

**问题1: 构建失败**
- 检查Dockerfile路径是否正确
- 验证backend目录存在
- 查看构建日志获取详细错误

**问题2: 容器启动失败**
- 检查环境变量配置
- 验证端口8001未被占用
- 查看容器日志: `docker logs ai-resume-backend`

**问题3: 健康检查失败**
- 确认后端应用在容器内运行
- 验证/health端点可访问
- 检查防火墙规则

**问题4: Redis连接失败**
- 确认ai-resume-redis容器运行
- 检查网络配置: ai-resume-network
- 验证REDIS_URL环境变量

## 完成标志

✅ 后端服务状态为 "Running"
✅ 健康检查通过
✅ /health 端点返回200状态
✅ 可以继续配置前端服务

---

**当前生产环境状态**:
- 后端已部署在: /var/www/ai-resume
- 容器名: ai-resume-backend
- 端口: 8001 (主机) → 8000 (容器)
- 数据库: SQLite (ai_resume.db)
