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
# 同步后端代码到服务器
rsync -avz --exclude='venv' --exclude='__pycache__' --exclude='*.pyc' --exclude='data' --exclude='*.db' \
  -e "ssh -i ~/.ssh/id_ed25519" backend/ root@113.45.64.145:/var/www/ai-resume/backend/

# 同步前端 dist 到服务器
rsync -avz --delete -e "ssh -i ~/.ssh/id_ed25519" ai-resume-web/dist/ root@113.45.64.145:/var/www/ai-resume/frontend/dist/

# 重启后端服务
ssh -i ~/.ssh/id_ed25519 root@113.45.64.145 "systemctl restart ai-resume-backend"

# 重启 nginx
ssh -i ~/.ssh/id_ed25519 root@113.45.64.145 "systemctl restart nginx"

# 查看后端状态
ssh -i ~/.ssh/id_ed25519 root@113.45.64.145 "systemctl status ai-resume-backend"

# 查看后端日志
ssh -i ~/.ssh/id_ed25519 root@113.45.64.145 "journalctl -u ai-resume-backend -f"

# 验证部署
ssh -i ~/.ssh/id_ed25519 root@113.45.64.145 "curl -s http://localhost:8001/health && curl -sI http://localhost:8081/ | head -3"
```

### 本地开发规则

1. **禁止** `docker compose up` — 本地不做容器部署
2. **禁止** 在本地启动 backend/frontend 服务占用端口
3. 本地开发可用 `python -m pytest` 跑测试
4. 同步后端代码后需 `systemctl restart ai-resume-backend`
5. 同步前端 dist 后 nginx 自动生效（静态文件）
6. **禁止** rsync 同步 venv 目录（服务器独立管理 venv）

### 云端直接部署架构（systemd + nginx）

```
后端: systemd (ai-resume-backend.service)
  → /var/www/ai-resume/backend/venv/bin/python -m uvicorn app.main:app --host 127.0.0.1 --port 8001

前端: nginx (ai-resume site)
  → 监听 8081，静态文件 /var/www/ai-resume/frontend/dist/
  → /api/v1/ 反向代理到 127.0.0.1:8001

Redis: systemd (redis-server.service)
  → 127.0.0.1:6379

配置文件:
  → systemd: /etc/systemd/system/ai-resume-backend.service
  → nginx: /etc/nginx/sites-available/ai-resume
  → 环境变量: /var/www/ai-resume/.env
```
