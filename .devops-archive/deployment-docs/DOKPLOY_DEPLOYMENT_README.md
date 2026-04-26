# AI Resume Platform - Dokploy部署完整指南

**项目**: AI智能体简历
**环境**: Production
**部署平台**: Dokploy v0.28.8
**服务器**: 113.45.64.145 (Ubuntu 24.04)
**完成时间**: 2026-04-25

---

## 📋 部署概览

本指南包含完整的Dokploy部署流程，涵盖从SSH配置到服务验证的所有步骤。

### 部署架构

```
┌─────────────────────────────────────────────────┐
│              Dokploy Platform                   │
│           (113.45.64.145:3000)                  │
└─────────────┬───────────────────────────────────┘
              │
              ├──► ai-resume-backend (Port 8001)
              │    └── FastAPI Application
              │    └── SQLite Database
              │    └── Redis Cache
              │
              ├──► ai-resume-frontend (Port 8081)
              │    └── Nginx + Static Files
              │    └── API Proxy
              │
              └──► ai-resume-redis (Port 6379)
                   └── Redis Server
```

---

## 🚀 快速开始

### 前置要求

1. **Dokploy账户**
   - 邮箱: 641600780@qq.com
   - 密码: 353980swsgbo
   - 面板: http://113.45.64.145:3000

2. **SSH访问**
   - 密钥路径: ~/.ssh/id_ed25519
   - 服务器用户: root@113.45.64.145

3. **必需资源**
   - DeepSeek API密钥
   - Gmail SMTP配置
   - 域名: happy.ndtool.cn (可选)

### 部署步骤

按照以下顺序执行部署：

1. **[步骤2: 添加SSH密钥](./step2_add_ssh_key.md)**
   - 在Dokploy中添加本机SSH公钥
   - 验证SSH连接
   - **预计时间**: 3分钟

2. **[步骤3: 配置后端服务](./step3_backend_config.md)**
   - 创建ai-resume-backend服务
   - 配置Docker Compose
   - 设置环境变量
   - **预计时间**: 10分钟

3. **[步骤4: 配置前端服务](./step4_frontend_config.md)**
   - 创建ai-resume-frontend服务
   - 配置Nginx反向代理
   - 设置API代理
   - **预计时间**: 8分钟

4. **[步骤5: 配置环境变量](./step5_env_config.md)**
   - 设置生产环境变量
   - 配置API密钥
   - 设置SMTP服务
   - **预计时间**: 5分钟

5. **[步骤6: 部署验证](./step6_deploy_verify.md)**
   - 触发服务部署
   - 运行健康检查
   - 验证所有功能
   - **预计时间**: 10分钟

**总部署时间**: 约36分钟

---

## 📚 详细指南

### 步骤指南文档

| 步骤 | 文档 | 说明 |
|------|------|------|
| 1 | 登录面板 | 访问Dokploy并登录 |
| 2 | [step2_add_ssh_key.md](./step2_add_ssh_key.md) | SSH密钥配置 |
| 3 | [step3_backend_config.md](./step3_backend_config.md) | 后端服务配置 |
| 4 | [step4_frontend_config.md](./step4_frontend_config.md) | 前端服务配置 |
| 5 | [step5_env_config.md](./step5_env_config.md) | 环境变量配置 |
| 6 | [step6_deploy_verify.md](./step6_deploy_verify.md) | 部署验证 |

### 工具脚本

| 脚本 | 说明 | 使用 |
|------|------|------|
| `health_check.sh` | 健康检查脚本 | `bash health_check.sh` |

---

## 🔑 关键配置

### 服务器信息

```
IP: 113.45.64.145
SSH: root@113.45.64.145
密钥: ~/.ssh/id_ed25519
项目目录: /var/www/ai-resume
```

### 服务端口

```
后端API: 8001
前端界面: 8081
Redis: 6379 (内部)
Dokploy: 3000
```

### 域名配置

```
前端: https://happy.ndtool.cn
API: https://api.happy.ndtool.cn
```

---

## ✅ 验证清单

### 部署前检查

- [ ] Dokploy账户可登录
- [ ] SSH密钥已生成
- [ ] 服务器可访问
- [ ] DeepSeek API密钥已获取
- [ ] Gmail SMTP已配置

### 部署后验证

- [ ] 所有容器状态为 "Running"
- [ ] 后端健康检查通过: `/health`
- [ ] 前端页面可访问: `:8081`
- [ ] API代理工作正常: `/api/health`
- [ ] Redis连接正常: `ping` → `PONG`
- [ ] 数据库文件存在
- [ ] AI服务可用
- [ ] 无错误日志

---

## 🛠️ 常用命令

### SSH连接

```bash
# 连接服务器
ssh -i ~/.ssh/id_ed25519 root@113.45.64.145

# 查看容器状态
ssh -i ~/.ssh/id_ed25519 root@113.45.64.145 "docker ps"

# 查看日志
ssh -i ~/.ssh/id_ed25519 root@113.45.64.145 "docker logs ai-resume-backend --tail 50"
```

### 健康检查

```bash
# 运行健康检查
bash /home/hongfu/ai-resume/health_check.sh

# 手动检查后端
curl http://113.45.64.145:8001/health

# 手动检查前端
curl -I http://113.45.64.145:8081

# 检查API代理
curl http://113.45.64.145:8081/api/health
```

### 服务管理

```bash
# 重启后端
ssh -i ~/.ssh/id_ed25519 root@113.45.64.145 "docker restart ai-resume-backend"

# 重启前端
ssh -i ~/.ssh/id_ed25519 root@113.45.64.145 "docker restart ai-resume-frontend"

# 查看资源使用
ssh -i ~/.ssh/id_ed25519 root@113.45.64.145 "docker stats"
```

---

## 🐛 故障排查

### 常见问题

**问题1: 容器无法启动**
```bash
# 查看详细日志
docker logs ai-resume-backend

# 检查端口占用
netstat -tlnp | grep 8001

# 验证环境变量
docker inspect ai-resume-backend | grep -A 20 Env
```

**问题2: API调用失败**
```bash
# 测试网络连接
docker exec ai-resume-frontend ping ai-resume-backend

# 检查DNS解析
docker exec ai-resume-frontend nslookup ai-resume-backend

# 验证API端点
curl http://113.45.64.145:8001/api/health
```

**问题3: 健康检查失败**
```bash
# 进入容器检查
docker exec -it ai-resume-backend bash

# 在容器内测试
curl http://localhost:8000/health
python -c "import sqlite3; print('DB OK')"
```

---

## 📊 监控指标

### 关键指标

- **容器状态**: 所有容器应为 `Up`
- **内存使用**: 后端 < 1GB，前端 < 100MB
- **CPU使用**: 正常负载 < 20%
- **响应时间**: 健康检查 < 500ms
- **错误率**: 0%

### 监控命令

```bash
# 实时监控
watch -n 2 'ssh -i ~/.ssh/id_ed25519 root@113.45.64.145 "docker ps | grep ai-resume"'

# 资源监控
ssh -i ~/.ssh/id_ed25519 root@113.45.64.145 "docker stats --no-stream | grep ai-resume"

# 日志监控
ssh -i ~/.ssh/id_ed25519 root@113.45.64.145 "docker-compose -f /var/www/ai-resume/docker-compose.yml logs -f"
```

---

## 🔒 安全配置

### 安全最佳实践

1. **密钥管理**
   - ✅ 使用强随机SECRET_KEY
   - ✅ 定期轮换API密钥
   - ✅ 不要提交.env文件到Git

2. **网络安全**
   - ✅ 启用HTTPS (SSL证书)
   - ✅ 配置防火墙规则
   - ✅ 限制API访问频率

3. **访问控制**
   - ✅ 使用SSH密钥认证
   - ✅ 禁用root远程登录（可选）
   - ✅ 配置CORS白名单

### 密钥生成

```bash
# 生成SECRET_KEY
python3 -c "import secrets; print(secrets.token_urlsafe(50))"

# 生成JWT密钥
python3 -c "import secrets; print(secrets.token_urlsafe(32))"
```

---

## 🚀 CI/CD集成

### GitHub Actions配置

```yaml
name: Deploy to Dokploy

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - name: Deploy to production
        run: |
          ssh -i ${{ secrets.SSH_KEY }} root@113.45.64.145 << 'ENDSSH'
          cd /var/www/ai-resume
          git pull origin main
          docker-compose up -d --build
          ENDSSH
```

### Webhook配置

1. 在Dokploy中配置Webhook URL
2. 在GitHub仓库中添加Webhook
3. 推送到main分支时自动部署

---

## 📈 性能优化

### 后端优化

- 启用Redis缓存
- 使用连接池
- 异步任务处理
- 数据库查询优化

### 前端优化

- 启用Gzip压缩
- 静态资源缓存
- 代码分割
- CDN加速

### 网络优化

- Keep-Alive连接
- HTTP/2支持
- 负载均衡（未来）

---

## 📞 支持与联系

### 技术支持

- **DevOps Engineer**: agent-29126157-6833-4f1e-94bd-6493bd95d3f2
- **Paperclip平台**: http://127.0.0.1:3100
- **项目仓库**: ai-resume

### 相关链接

- [Dokploy文档](https://docs.dokploy.com)
- [Docker文档](https://docs.docker.com)
- [FastAPI文档](https://fastapi.tiangolo.com)
- [Nginx文档](https://nginx.org/en/docs/)

---

## 📝 变更日志

### v1.0.0 (2026-04-25)

- ✅ 初始部署指南
- ✅ SSH密钥配置
- ✅ 后端服务配置
- ✅ 前端服务配置
- ✅ 环境变量配置
- ✅ 部署验证脚本
- ✅ 健康检查工具

---

**部署状态**: ✅ 所有步骤已完成
**最后更新**: 2026-04-25
**文档版本**: 1.0.0

---

**快速验证命令**:

```bash
# 一键健康检查
bash /home/hongfu/ai-resume/health_check.sh

# 快速状态检查
curl -s http://113.45.64.145:8001/health && echo "✓ 后端正常"
curl -s http://113.45.64.145:8081 > /dev/null && echo "✓ 前端正常"
```

🎉 **部署完成！**
