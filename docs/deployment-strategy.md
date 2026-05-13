# AI Resume 部署策略

## 当前部署状态（2026-05-13）

### 云端服务器（113.45.64.145）

**运行中的服务：**
- **后端 API**：systemd 服务，127.0.0.1:8001 ✅
  - 服务名：ai-resume-backend.service
  - 健康检查：http://localhost:8001/health
  - 状态：active (running) 16h

- **前端静态文件**：nginx，0.0.0.0:8081 ✅
  - 状态：正常响应 HTTP 200

- **Redis**：Docker 容器
  - 容器名：compose-parse-cross-platform-bus-wckbss-redis-1
  - 端口：6379

- **Dokploy**：Docker 容器
  - 版本：v0.28.8
  - 端口：3000

### Dokploy 配置

**项目：**
- ID: hKHDNMV9pJ9GDVhXMJUSX
- 名称：AI智能体简历
- 环境：production (knUE3WmJdtKEkJqX8rff0)

**Compose 配置（当前状态 - 有错误）：**
- ID: PK1tXceTeXlm7WZAc8Vy-
- 名称：ai-resume
- 状态：error ❌
- 问题：
  1. 端口冲突（尝试使用 3000，被 Dokploy 占用）
  2. composeFile 不完整（缺少后端服务）
  3. 镜像配置过时

## 部署策略

### 阶段1：修复 Dokploy Compose 配置（立即）

**目标：**修复 Dokploy 中的 docker-compose.yml 配置

**操作：**
1. 更新 composeFile 内容：
   ```yaml
   services:
     backend:
       build:
         context: ./backend
         dockerfile: Dockerfile.lite
       ports:
         - "8002:8000"  # 使用 8002 避免与当前 systemd 8001 冲突
       environment:
         - USE_SQLITE=true
         - DATABASE_URL=sqlite+aiosqlite:///./data/ai_resume.db
         - REDIS_URL=redis://redis:6379/0
         - DEBUG=false
         - ENVIRONMENT=production
       volumes:
         - backend_data:/app/data
       restart: unless-stopped
       depends_on:
         - redis

     frontend:
       build:
         context: .
         dockerfile: ai-resume-web/Dockerfile
       ports:
         - "8082:80"  # 使用 8082 避免与当前 nginx 8081 冲突
       restart: unless-stopped

     redis:
       image: redis:7-alpine
       command: redis-server --appendonly yes
       volumes:
         - redis_data:/data
       restart: unless-stopped

   volumes:
     backend_data:
     redis_data:
   ```

2. 更新 Dokploy 数据库 compose 表
3. 触发部署测试

### 阶段2：域名和 SSL 配置（Phase 4 要求）

**当前域名：**
- 主域名：happy.ndtool.cn
- 需要配置子域名：
  - api.happy.ndtool.cn → 后端
  - happy.ndtool.cn → 前端

**SSL 证书：**
- 使用 Let's Encrypt（Dokploy 自动配置）

### 阶段3：CI/CD 集成（Phase 4 要求）

**Git 仓库：**
- GitCode: https://gitcode.com/hongfu/AI-
- 分支：main

**CI/CD 流程：**
1. Push 到 main 分支
2. Dokploy webhook 触发
3. 构建新镜像
4. 部署到 production

### 阶段4：切换到 Dokploy 容器部署（可选）

**切换时机：**
- Dokploy 部署验证稳定
- 业务低峰期
- 完整备份后

**切换步骤：**
1. 停止 systemd 后端服务
2. 停止 nginx 前端服务
3. 切换 Dokploy compose 端口到生产端口（8001, 8081）
4. 验证服务健康

## 部署检查清单

### 当前服务验证 ✅
- [x] 后端健康检查：http://113.45.64.145:8001/health
- [x] 前端访问：http://113.45.64.145:8081
- [x] Redis 连接正常

### Dokploy 配置待完成 ⏳
- [ ] 修复 compose 配置
- [ ] 配置域名 api.happy.ndtool.cn
- [ ] 配置域名 happy.ndtool.cn
- [ ] 启用 SSL 证书
- [ ] 配置 webhook 自动部署
- [ ] 测试部署流程

### 监控和日志
- [ ] 配置日志收集
- [ ] 设置健康检查告警
- [ ] 配置备份策略

## 紧急回滚方案

如果 Dokploy 部署出现问题：
1. 立即启动 systemd 后端：`systemctl start ai-resume-backend.service`
2. 立即启动 nginx 前端：`systemctl start nginx`
3. 检查服务日志：`journalctl -u ai-resume-backend.service -f`
4. 验证服务健康

## 下一步行动

1. **立即执行**：修复 Dokploy compose 配置
2. **本会话内**：配置域名和 SSL
3. **后续**：完善 CI/CD 流程
