# 部署快速指南

> **更新日期**: 2026-04-02
> **版本**: v3.0 (包含监控告警、自动备份、Dokploy 部署)

## 开发环境

### 启动开发服务器

```bash
# 后端
cd ~/ai-resume/backend
source venv/bin/activate
source .env
python -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8000

# 前端 (支持 HMR 和代码分割)
cd ~/ai-resume/ai-resume-web
npm run dev
```

### 构建前端

```bash
cd ~/ai-resume/ai-resume-web

# 开发构建
npm run build

# 生产构建 (包含代码分割优化)
NODE_ENV=production npm run build

# 预览构建结果
npm run preview
```

**构建输出说明** (优化后):
- `index.js`: 主入口 (~78KB) - 减少 87%
- `vendor-react.js`: React 核心库 (~163KB)
- `vendor-editor.js`: 富文本编辑器 (~371KB, 按需加载)
- `vendor-state.js`: 状态管理 (~47KB)
- `vendor-dnd.js`: 拖拽库 (~45KB, 按需加载)
- 页面 chunks: 各路由页面独立打包

## Docker 部署

### 启动服务

```bash
cd ~/ai-resume

# 启动所有服务（开发环境）
docker-compose up -d

# 启动所有服务（生产环境）
docker-compose --profile production up -d

# 查看日志
docker-compose logs -f

# 停止服务
docker-compose down

# 停止并删除数据
docker-compose down -v
```

### 服务访问

| 服务 | 地址 | 说明 |
|------|------|------|
| 后端 API | http://localhost:8000 | FastAPI 服务 |
| API 文档 | http://localhost:8000/docs | Swagger UI |
| 前端 | http://localhost:3000 | React 应用 |
| Nginx | http://localhost:80 | 生产环境反向代理 |

## 安全配置

### 环境变量

```bash
# .env (生产环境必填)
DEBUG=false
SECRET_KEY=your-32-char-random-key-here
CORS_ORIGINS=https://yourdomain.com,https://www.yourdomain.com

# 数据库
DATABASE_URL=mysql://airesume:password@db:3306/ai_resume

# Redis (速率限制)
REDIS_URL=redis://redis:6379/0
```

### 安全头部 (自动配置)

应用自动添加以下安全头部：

| 头部 | 值 | 作用 |
|------|-----|------|
| X-Content-Type-Options | nosniff | 防止 MIME 嗅探 |
| X-Frame-Options | DENY | 防止点击劫持 |
| X-XSS-Protection | 1; mode=block | XSS 过滤器 |
| Referrer-Policy | strict-origin-when-cross-origin | 引用保护 |
| Permissions-Policy | 限制敏感 API | 权限控制 |
| Strict-Transport-Security | max-age=31536000 | 强制 HTTPS |
| Content-Security-Policy | 严格策略 | XSS 防护 |

### 速率限制

| 操作 | 限制 |
|------|------|
| 注册 | 5/hour |
| 登录 | 20/minute |
| 密码重置 | 3/hour |
| AI 生成 | 10/hour |

## 数据库操作

### SQLite（默认开发）

```bash
# 进入后端容器
docker-compose exec backend bash

# 备份数据库
cp data/ai_resume.db /app/backup/ai_resume_$(date +%Y%m%d).db
```

### MySQL（生产环境）

```bash
# 启动 MySQL
docker-compose --profile production up -d db

# 备份数据库
docker-compose exec db mysqldump -u airesume -pairesume_password ai_resume > backup.sql

# 恢复数据库
docker-compose exec -T db mysql -u airesume -pairesume_password ai_resume < backup.sql
```

## 日志查看

```bash
# 查看所有日志
docker-compose logs

# 查看特定服务日志
docker-compose logs backend
docker-compose logs frontend
docker-compose logs nginx

# 查看实时日志
docker-compose logs -f backend

# 查看最近 100 行
docker-compose logs --tail=100 backend
```

## 更新部署

```bash
# 拉取最新代码
git pull

# 重新构建镜像
docker-compose build

# 重启服务
docker-compose up -d

# 清理旧镜像
docker image prune -f
```

## 故障排查

### 服务无法启动

```bash
# 查看服务状态
docker-compose ps

# 查看日志
docker-compose logs

# 重启服务
docker-compose restart backend
```

### 数据库连接失败

```bash
# 检查数据库状态
docker-compose ps db

# 查看 MySQL 日志
docker-compose logs db

# 进入数据库容器
docker-compose exec db bash
```

### 前端构建问题

```bash
# 清理缓存重新构建
cd ai-resume-web
rm -rf node_modules dist
npm install
npm run build
```

## 性能优化

### 资源限制

```yaml
services:
  backend:
    deploy:
      resources:
        limits:
          cpus: '2'
          memory: 2G
        reservations:
          cpus: '1'
          memory: 1G
```

### 日志轮转

```yaml
services:
  backend:
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"
```

## 备份策略

### 自动备份

```bash
# 添加到 crontab
0 2 * * * cd /path/to/ai-resume && ./scripts/backup.sh
```

### 手动备份

```bash
# 完整备份
./scripts/backup-all.sh
```

## 监控

### 健康检查

```bash
# 后端健康检查
curl http://localhost:8000/health

# 前端健康检查
curl http://localhost:3000
```

### 监控工具

- **Grafana** - 可视化监控 (http://localhost:3001)
- **Prometheus** - 指标收集 (http://localhost:9090)
- **Alertmanager** - 告警管理 (http://localhost:9093)
- **Loki** - 日志聚合 (http://localhost:3100)

### 启动监控服务

```bash
# 启动所有监控组件
docker-compose -f docker-compose.prod.yml \
  -f docker-compose.monitoring.yml \
  --profile monitoring up -d

# 查看监控服务状态
docker-compose -f docker-compose.monitoring.yml ps
```

### 访问监控界面

| 服务 | 地址 | 凭据 |
|------|------|------|
| Grafana | http://localhost:3001 | admin/admin |
| Prometheus | http://localhost:9090 | - |
| Alertmanager | http://localhost:9093 | - |

### 健康检查脚本

```bash
# 运行完整健康检查
./scripts/health-check.sh

# 配置告警通知
export ALERT_WEBHOOK="https://hooks.slack.com/..."
./scripts/health-check.sh
```

### 自动备份

```bash
# 手动备份
./scripts/backup.sh

# 配置定时备份
crontab -e
# 添加: 0 2 * * * cd /home/hongfu/ai-resume && ./scripts/backup.sh

# 测试备份功能
./scripts/backup-test.sh
```

### Dokploy 一键部署

```bash
# Dokploy 会自动读取 dokploy.config.json
# 在 Dokploy 控制台点击 "Deploy" 即可

# 或通过 API 触发部署
curl -X POST "$DOKPLOY_URL/api/deploy" \
  -H "Authorization: Bearer $DOKPLOY_API_KEY" \
  -H "Content-Type: application/json"
```

## HTTPS 配置

### 使用 Let's Encrypt

```bash
# 获取证书
sudo certbot certonly --standalone -d yourdomain.com

# Nginx 配置 (已包含)
# 见 nginx/nginx.conf
```

### 防火墙配置

```bash
# 只开放必要端口
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw enable
```

## 故障恢复

### 数据丢失

```bash
# 从备份恢复
docker-compose exec db mysql -u airesume -pairesume_password ai_resume < backup.sql
```

### 服务崩溃

```bash
# 自动重启（已配置）
restart: unless-stopped

# 手动重启
docker-compose restart
```

## 部署检查清单

生产环境部署前确认：

### 基础配置
- [ ] `DEBUG=false` 已设置
- [ ] `SECRET_KEY` 已生成且安全存储
- [ ] `CORS_ORIGINS` 仅包含生产域名
- [ ] HTTPS 证书已配置
- [ ] 防火墙规则已配置

### 数据库
- [ ] 数据库备份策略已启用
- [ ] 备份测试通过 (`./scripts/backup-test.sh`)
- [ ] 数据库连接池配置正确

### 监控告警
- [ ] Prometheus 和 Grafana 已启动
- [ ] 告警规则已加载
- [ ] Slack/Email 通知已配置
- [ ] 健康检查脚本可执行

### 性能优化
- [ ] 速率限制已启用
- [ ] 日志轮转已配置
- [ ] 健康检查端点可访问
- [ ] 容器资源限制已设置

### CI/CD
- [ ] GitHub Secrets 已配置
- [ ] Dokploy API 密钥已设置
- [ ] 部署脚本测试通过
