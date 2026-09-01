# Docker 快速参考卡片 - AI Resume Platform

## 🚀 一键部署

```bash
./docker-deploy.sh
```

## 📋 常用命令

### 服务管理

```bash
# 启动所有服务
docker-compose up -d

# 停止所有服务
docker-compose down

# 重启服务
docker-compose restart

# 查看服务状态
docker-compose ps

# 查看日志
docker-compose logs -f
docker-compose logs -f backend
```

### 数据库迁移

```bash
# 运行迁移
./docker-migrate.sh up

# 回滚迁移
./docker-migrate.sh down

# 查看当前版本
./docker-migrate.sh current

# 创建新迁移
./docker-migrate.sh revision "描述"
```

### 备份与恢复

```bash
# 创建备份
./docker-rollback.sh backup

# 回滚到指定版本
./docker-rollback.sh rollback v1.0.0

# 恢复服务
./docker-rollback.sh restore
```

## 🔍 健康检查

```bash
# Backend
curl http://localhost:8000/health

# Web
curl http://localhost:8081/health

# Nginx
curl http://localhost/health
```

## 💻 进入容器

```bash
# Backend
docker-compose exec backend bash

# PostgreSQL
docker-compose exec postgres psql -U ai_resume_user -d ai_resume

# Redis
docker-compose exec redis redis-cli
```

## 📊 监控

```bash
# 资源使用
docker stats

# 磁盘使用
docker system df

# 容器详细信息
docker inspect <container_id>
```

## 🧹 清理

```bash
# 清理未使用的镜像
docker image prune -a

# 清理未使用的容器
docker container prune

# 清理未使用的卷
docker volume prune

# 完全清理
docker system prune -a
```

## 📝 访问地址

- **Web 前端**: http://localhost:8081
- **API 文档**: http://localhost:8000/docs
- **Nginx 代理**: http://localhost

## 🔧 故障排查

```bash
# 查看服务日志
docker-compose logs -f <service_name>

# 重启特定服务
docker-compose restart <service_name>

# 检查端口占用
sudo netstat -tlnp | grep <port>

# 检查磁盘空间
df -h
```

## 📦 镜像构建

```bash
# 构建所有镜像
docker-compose build

# 构建特定服务镜像
docker-compose build backend

# 强制重新构建（无缓存）
docker-compose build --no-cache
```

## 🌐 网络相关

```bash
# 查看网络
docker network ls

# 查看服务网络详情
docker network inspect ai-resume_ai-resume-network

# 测试服务间连接
docker-compose exec backend ping postgres
docker-compose exec backend ping redis
```

## 🔐 安全相关

```bash
# 生成随机密钥
python3 -c "import secrets; print(secrets.token_urlsafe(64))"

# 查看环境变量
cat .env

# 检查容器权限
docker-compose exec backend whoami
```

## 📈 性能调优

```bash
# 增加工作进程数
docker-compose exec backend uvicorn app.main:app --workers 4

# 查看数据库连接
docker-compose exec postgres psql -U ai_resume_user -d ai_resume -c "SELECT count(*) FROM pg_stat_activity;"
```

## 🔄 更新与维护

```bash
# 拉取最新代码
git pull origin main

# 重新构建并部署
docker-compose build && docker-compose up -d

# 运行迁移
./docker-migrate.sh up

# 验证服务
curl http://localhost:8000/health
```

## 📞 获取帮助

```bash
# 查看部署文档
cat DOCKER_DEPLOYMENT.md

# 查看脚本帮助
./docker-deploy.sh --help
./docker-migrate.sh --help
./docker-rollback.sh --help
```

## ⚡ 快捷键提示

- `Ctrl+C`: 停止前台运行的容器
- `Ctrl+P, Ctrl+Q`: 从容器中分离而不停止它
- `docker-compose logs -f --tail=100`: 查看最近 100 行日志并持续跟踪

## 🎯 常见任务

### 添加新的 AI Provider

1. 编辑 `.env` 文件，添加新的 API 密钥
2. 在 Backend 代码中实现新的 AI 服务
3. 重新构建并部署：
   ```bash
   docker-compose build backend
   docker-compose up -d backend
   ```

### 更新前端

```bash
# 修改前端代码后
docker-compose build web
docker-compose up -d web
```

### 扩容 Backend

编辑 `docker-compose.yml`，增加 Backend 实例数量：
```yaml
backend:
  deploy:
    replicas: 3
```

然后：
```bash
docker-compose up -d --scale backend=3
```

---

**提示**: 将此文件添加到书签或打印出来，方便快速查找常用命令。
