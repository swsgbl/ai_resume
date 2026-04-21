# AI Resume 项目配置

## 部署策略

**禁止本地部署。** 所有部署和运维操作必须通过云端服务器执行。

### 环境分工

| 环境 | 用途 | 说明 |
|------|------|------|
| 本地 `/home/hongfu/ai-resume` | 开发 | 写代码、测试、调试 |
| 云端 `113.45.64.145` | 部署+运维 | 生产环境 |

### 云端服务器信息

- **IP**: 113.45.64.145
- **SSH**: `ssh -i ~/.ssh/id_ed25519 root@113.45.64.145`
- **项目目录**: `/var/www/ai-resume/`
- **后端 API**: http://113.45.64.145:8001
- **前端**: http://113.45.64.145:8081
- **域名**: https://happy.ndtool.cn

### 部署命令

```bash
# 完整部署（同步代码+重建容器+验证）
./deploy-cloud.sh full

# 仅同步代码（不重建容器）
./deploy-cloud.sh sync

# 重启云端容器
./deploy-cloud.sh restart

# 查看云端状态
./deploy-cloud.sh status

# 查看日志
./deploy-cloud.sh logs [backend|redis|frontend]

# 验证部署
./deploy-cloud.sh verify
```

### 本地开发规则

1. **禁止** `docker compose up` — 本地不做容器部署
2. **禁止** 在本地启动 backend/frontend 服务占用端口
3. 本地开发可用 `python -m pytest` 跑测试
4. 代码完成后运行 `./deploy-cloud.sh full` 部署到云端
5. 小改动可用 `./deploy-cloud.sh sync` 快速同步

### 云端 Docker 架构

```
ai-resume-backend  → 8001:8000 (FastAPI)
ai-resume-redis    → 6379 (内部)
ai-resume-frontend → 8081:80  (Nginx 静态文件)
```
