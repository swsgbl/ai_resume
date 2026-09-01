# Docker 部署指南 - AI Resume Platform

本文档提供 AI Resume Platform 的 Docker 容器化部署完整指南。

## 📋 目录

- [系统要求](#系统要求)
- [快速开始](#快速开始)
- [配置说明](#配置说明)
- [服务架构](#服务架构)
- [部署流程](#部署流程)
- [常用命令](#常用命令)
- [监控与日志](#监控与日志)
- [备份与恢复](#备份与恢复)
- [故障排查](#故障排查)
- [生产环境配置](#生产环境配置)

## 系统要求

### 最低配置

- **操作系统**: Linux (Ubuntu 20.04+ 推荐), macOS, 或 Windows (WSL2)
- **CPU**: 2 核心及以上
- **内存**: 4GB 及以上
- **磁盘**: 20GB 可用空间
- **网络**: 稳定的互联网连接

### 软件要求

- **Docker**: 20.10.0 及以上
- **Docker Compose**: 1.29.0 及以上

### 安装 Docker

#### Ubuntu/Debian
```bash
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER
```

#### macOS
下载并安装 [Docker Desktop for Mac](https://www.docker.com/products/docker-desktop)

#### Windows
下载并安装 [Docker Desktop for Windows](https://www.docker.com/products/docker-desktop)

## 快速开始

### 1. 克隆代码仓库

```bash
git clone https://github.com/18606559294/AI-.git
cd AI-
```

### 2. 配置环境变量

```bash
# 复制生产环境配置模板
cp .env.production .env

# 编辑配置文件，填入实际的配置值
nano .env
```

### 3. 一键部署

```bash
# 赋予执行权限
chmod +x docker-deploy.sh docker-migrate.sh docker-rollback.sh

# 运行部署脚本
./docker-deploy.sh
```

部署脚本会自动完成以下操作：
- ✅ 检查 Docker 环境
- ✅ 构建所有 Docker 镜像
- ✅ 启动所有服务（PostgreSQL, Redis, Backend, Web, Nginx）
- ✅ 初始化数据库
- ✅ 导入简历模板
- ✅ 健康检查

### 4. 验证部署

```bash
# 检查所有服务状态
docker-compose ps

# 检查服务健康状态
curl http://localhost:8000/health  # Backend
curl http://localhost:8081/health  # Web
curl http://localhost/health       # Nginx
```

### 5. 访问应用

- **Web 前端**: http://localhost:8081
- **API 文档**: http://localhost:8000/docs
- **Nginx 代理**: http://localhost

## 配置说明

### 环境变量详解

在 `.env` 文件中配置以下关键变量：

#### 数据库配置

```env
# 使用 SQLite (开发环境)
USE_SQLITE=true
DATABASE_URL=sqlite+aiosqlite:///./ai_resume.db

# 使用 PostgreSQL (生产环境)
USE_SQLITE=false
POSTGRES_DB=ai_resume
POSTGRES_USER=ai_resume_user
POSTGRES_PASSWORD=<强密码>
DATABASE_URL=postgresql+asyncpg://ai_resume_user:<密码>@postgres:5432/ai_resume
```

#### 安全配置

```env
# 生成强密钥 (64位随机字符串)
SECRET_KEY=<64位随机字符串>
JWT_SECRET=<64位随机字符串>
```

生成强密钥：
```bash
python3 -c "import secrets; print(secrets.token_urlsafe(64))"
```

#### AI API 密钥

```env
OPENAI_API_KEY=sk-...
DEEPSEEK_API_KEY=...
XIAOMI_API_KEY=...
```

#### CORS 配置

```env
ALLOWED_ORIGINS=https://yourdomain.com,https://www.yourdomain.com
```

### 多环境配置

创建不同的环境配置文件：

```bash
.env              # 开发环境 (默认)
.env.staging      # 测试环境
.env.production   # 生产环境
```

切换环境：
```bash
# 使用特定环境配置
cp .env.staging .env
docker-compose up -d
```

## 服务架构

### 服务组件

```
┌─────────────────────────────────────────────────────────┐
│                    Nginx (端口 80/443)                   │
│                   反向代理 & SSL 终止                     │
└────────────────────┬────────────────────────────────────┘
                     │
         ┌───────────┴───────────┐
         │                       │
┌────────▼────────┐     ┌────────▼────────┐
│  Web (端口 8081) │     │  Backend (8000) │
│  Nginx + React  │     │   FastAPI       │
└─────────────────┘     └──────┬──────────┘
                               │
                    ┌──────────┴──────────┐
                    │                     │
           ┌────────▼────────┐   ┌────────▼────────┐
           │  PostgreSQL    │   │  Redis          │
           │  (端口 5432)   │   │  (端口 6379)    │
           └────────────────┘   └─────────────────┘
```

### 服务依赖关系

- **Web** 依赖于 Backend
- **Backend** 依赖于 PostgreSQL 和 Redis
- **Nginx** 依赖于 Web 和 Backend

### 网络架构

所有服务通过 Docker 内置网络 `ai-resume-network` 互联，实现服务间通信。

## 部署流程

### 标准部署

```bash
# 1. 拉取最新代码
git pull origin main

# 2. 重新构建镜像
docker-compose build

# 3. 启动服务
docker-compose up -d

# 4. 运行数据库迁移
./docker-migrate.sh up

# 5. 验证服务
curl http://localhost:8000/health
```

### 滚动更新（零停机）

```bash
# 1. 构建新镜像
docker-compose build backend web

# 2. 逐个更新服务
docker-compose up -d --no-deps --build backend
sleep 30  # 等待新版本就绪
docker-compose up -d --no-deps --build web

# 3. 运行迁移（如果有）
./docker-migrate.sh up
```

### 回滚版本

```bash
# 1. 创建备份
./docker-rollback.sh backup

# 2. 回滚到指定版本
./docker-rollback.sh rollback v1.0.0

# 3. 验证服务
docker-compose ps
```

## 常用命令

### 服务管理

```bash
# 启动所有服务
docker-compose up -d

# 停止所有服务
docker-compose down

# 重启所有服务
docker-compose restart

# 重启特定服务
docker-compose restart backend

# 查看服务状态
docker-compose ps

# 查看服务日志
docker-compose logs -f
docker-compose logs -f backend
```

### 数据库管理

```bash
# 运行迁移
./docker-migrate.sh up

# 回滚迁移
./docker-migrate.sh down

# 查看当前迁移版本
./docker-migrate.sh current

# 查看迁移历史
./docker-migrate.sh history

# 创建新迁移
./docker-migrate.sh revision "Add user email field"

# 重置数据库（危险操作）
./docker-migrate.sh reset
```

### 备份与恢复

```bash
# 创建备份
./docker-rollback.sh backup

# 列出可用镜像
./docker-rollback.sh images

# 回滚到指定版本
./docker-rollback.sh rollback v1.0.0

# 回滚数据库
./docker-rollback.sh db-downgrade

# 恢复服务
./docker-rollback.sh restore
```

### 进入容器

```bash
# 进入 Backend 容器
docker-compose exec backend bash

# 进入 PostgreSQL 容器
docker-compose exec postgres psql -U ai_resume_user -d ai_resume

# 进入 Redis 容器
docker-compose exec redis redis-cli
```

### 查看资源使用

```bash
# 查看容器资源使用情况
docker stats

# 查看磁盘使用
docker system df

# 清理未使用的资源
docker system prune -a
```

## 监控与日志

### 日志管理

```bash
# 查看所有服务日志
docker-compose logs -f

# 查看最近 100 行日志
docker-compose logs --tail=100

# 查看特定服务日志
docker-compose logs -f backend

# 导出日志到文件
docker-compose logs > logs.txt
```

### 健康检查

所有服务都配置了健康检查：

```bash
# Backend 健康检查
curl http://localhost:8000/health

# Web 健康检查
curl http://localhost:8081/health

# Nginx 健康检查
curl http://localhost/health
```

### 监控指标

#### Backend API 监控
- 响应时间
- 错误率
- 请求吞吐量
- 数据库连接数

#### 数据库监控
- 连接数
- 查询性能
- 慢查询日志
- 磁盘使用量

#### Redis 监控
- 内存使用
- 命中率
- 连接数
- 过期键数量

## 备份与恢复

### 自动备份配置

创建定时任务（crontab）：

```bash
# 编辑 crontab
crontab -e

# 添加每天凌晨 2 点备份
0 2 * * * cd /path/to/ai-resume && ./docker-rollback.sh backup
```

### 手动备份

```bash
# 完整备份（数据库 + 文件）
./docker-rollback.sh backup
```

备份内容：
- ✅ PostgreSQL 数据库
- ✅ Redis 数据
- ✅ 上传的文件
- ✅ 导出的简历
- ✅ 当前环境配置

### 恢复数据

```bash
# 从最新备份恢复
./docker-rollback.sh restore
```

## 故障排查

### 服务无法启动

**问题**: 服务启动失败

**解决方案**:
```bash
# 1. 查看服务状态
docker-compose ps

# 2. 查看错误日志
docker-compose logs backend

# 3. 检查端口占用
sudo netstat -tlnp | grep -E '8000|8081|5432|6379'

# 4. 检查磁盘空间
df -h
```

### 数据库连接失败

**问题**: Backend 无法连接到 PostgreSQL

**解决方案**:
```bash
# 1. 检查 PostgreSQL 是否运行
docker-compose ps postgres

# 2. 查看 PostgreSQL 日志
docker-compose logs postgres

# 3. 测试数据库连接
docker-compose exec postgres psql -U ai_resume_user -d ai_resume

# 4. 检查环境变量
cat .env | grep DATABASE_URL
```

### 前端无法访问后端 API

**问题**: Web 前端无法调用 Backend API

**解决方案**:
```bash
# 1. 检查 Backend 是否运行
curl http://localhost:8000/health

# 2. 检查 CORS 配置
cat .env | grep ALLOWED_ORIGINS

# 3. 查看 Web 容器日志
docker-compose logs web

# 4. 检查 Nginx 配置
docker-compose exec nginx nginx -t
```

### 内存不足

**问题**: 容器因内存不足被杀死

**解决方案**:
```bash
# 1. 查看容器资源使用
docker stats

# 2. 增加系统 swap 空间
sudo fallocate -l 4G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile

# 3. 限制容器内存使用
# 在 docker-compose.yml 中添加：
# mem_limit: 2g
# memswap_limit: 2g
```

### 磁盘空间不足

**问题**: Docker 占用过多磁盘空间

**解决方案**:
```bash
# 1. 清理未使用的镜像
docker image prune -a

# 2. 清理未使用的容器
docker container prune

# 3. 清理未使用的卷
docker volume prune

# 4. 查看磁盘使用
docker system df
```

## 生产环境配置

### SSL/HTTPS 配置

#### 使用 Let's Encrypt 自动获取证书

```bash
# 1. 安装 Certbot
sudo apt-get install certbot

# 2. 获取证书
sudo certbot certonly --standalone -d yourdomain.com

# 3. 证书路径
SSL_CERT_PATH=/etc/letsencrypt/live/yourdomain.com/fullchain.pem
SSL_KEY_PATH=/etc/letsencrypt/live/yourdomain.com/privkey.pem

# 4. 更新 .env 文件
```

#### Nginx SSL 配置

在 `deploy/nginx/nginx.conf` 中配置：

```nginx
server {
    listen 443 ssl http2;
    server_name yourdomain.com;

    ssl_certificate /etc/nginx/ssl/cert.pem;
    ssl_certificate_key /etc/nginx/ssl/key.pem;

    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;

    # ... 其他配置
}
```

### 性能优化

#### Nginx 配置优化

```nginx
# 启用 Gzip 压缩
gzip on;
gzip_vary on;
gzip_min_length 1024;
gzip_types text/plain text/css application/json application/javascript;

# 缓存静态资源
location /assets/ {
    expires 1y;
    add_header Cache-Control "public, immutable";
}

# 连接超时设置
proxy_connect_timeout 300;
proxy_send_timeout 300;
proxy_read_timeout 300;
```

#### Backend 优化

```python
# 在 backend/app/main.py 中
from fastapi.middleware.gzip import GZipMiddleware

app.add_middleware(GZipMiddleware, minimum_size=1000)

# 增加工作进程数
# 使用多 worker: uvicorn app.main:app --host 0.0.0.0 --port 8000 --workers 4
```

#### 数据库优化

```sql
-- 创建索引
CREATE INDEX idx_user_email ON users(email);
CREATE INDEX idx_resume_user_id ON resumes(user_id);

-- 定期清理
VACUUM ANALYZE;
```

### 安全加固

1. **防火墙配置**
```bash
# 仅开放必要端口
sudo ufw allow 22/tcp    # SSH
sudo ufw allow 80/tcp    # HTTP
sudo ufw allow 443/tcp   # HTTPS
sudo ufw enable
```

2. **定期更新**
```bash
# 更新系统
sudo apt-get update && sudo apt-get upgrade

# 更新 Docker 镜像
docker-compose pull
docker-compose up -d
```

3. **监控日志**
```bash
# 设置日志轮转
# /etc/logrotate.d/docker-compose
/path/to/ai-resume/logs/*.log {
    daily
    rotate 30
    compress
    missingok
    notifempty
    create 0644 www-data www-data
}
```

### 高可用部署

对于生产环境，建议：

1. **负载均衡**: 使用 Nginx 或 HAProxy
2. **多实例部署**: 部署多个 Backend 实例
3. **数据库集群**: 使用 PostgreSQL 主从复制
4. **Redis 集群**: 使用 Redis Sentinel 或 Cluster
5. **监控告警**: 使用 Prometheus + Grafana

## 附录

### 端口映射

| 服务    | 内部端口 | 外部端口 | 说明           |
|---------|---------|----------|----------------|
| Nginx   | 80      | 80       | HTTP 代理      |
| Nginx   | 443     | 443      | HTTPS 代理     |
| Web     | 80      | 8081     | 前端服务       |
| Backend | 8000    | 8000     | 后端 API       |
| PostgreSQL | 5432 | 5432     | 数据库         |
| Redis   | 6379    | 6379     | 缓存           |

### 数据持久化

| Volume          | 路径              | 说明           |
|-----------------|-------------------|----------------|
| postgres-data   | /var/lib/postgresql/data | PostgreSQL 数据 |
| redis-data      | /data             | Redis 数据     |
| backend-uploads | /app/uploads      | 上传文件       |
| backend-exports | /app/exports      | 导出文件       |
| backend-logs    | /app/logs         | 应用日志       |

### 相关链接

- [Docker 官方文档](https://docs.docker.com/)
- [Docker Compose 文档](https://docs.docker.com/compose/)
- [PostgreSQL 文档](https://www.postgresql.org/docs/)
- [Redis 文档](https://redis.io/documentation)
- [FastAPI 文档](https://fastapi.tiangolo.com/)

---

**最后更新**: 2026-03-26
**维护者**: AI Resume Platform Team
**版本**: 1.0.0
