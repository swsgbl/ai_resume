# 生产环境部署准备

## 前置条件

- [ ] 选项 A：前端测试完成 ✅
- [ ] 选项 B：GitHub Secrets 配置完成 ✅
- [ ] Docker 和 Docker Compose 已安装
- [ ] 生产服务器已准备

---

## 1. 生产环境配置

### 1.1 生产数据库（MySQL）

#### 创建 MySQL 配置

```yaml
# docker-compose.prod.yml
version: '3.8'

services:
  mysql:
    image: mysql:8.0
    container_name: ai-resume-mysql
    environment:
      MYSQL_ROOT_PASSWORD: ${MYSQL_ROOT_PASSWORD}
      MYSQL_DATABASE: ai_resume
      MYSQL_USER: airesume
      MYSQL_PASSWORD: ${MYSQL_PASSWORD}
    volumes:
      - mysql_data:/var/lib/mysql
      - ./mysql/conf.d:/etc/mysql/conf.d
    ports:
      - "3306:3306"
    restart: unless-stopped
    command:
      - --default-authentication-plugin=mysql_native_password
      - --character-set-server=utf8mb4
      - --collation-server=utf8mb4_unicode_ci
      - --max-connections=200
      - --innodb-buffer-pool-size=256M

volumes:
  mysql_data:
    driver: local
```

#### MySQL 配置文件

```ini
# mysql/conf.d/production.cnf
[mysqld]
# 字符集
character-set-server = utf8mb4
collation-server = utf8mb4_unicode_ci

# 性能优化
max_connections = 200
innodb_buffer_pool_size = 256M
innodb_log_file_size = 64M
innodb_flush_log_at_trx_commit = 2
innodb_flush_method = O_DIRECT

# 慢查询日志
slow_query_log = 1
slow_query_log_file = /var/log/mysql/slow-query.log
long_query_time = 2

# 二进制日志
log-bin = mysql-bin
binlog_format = ROW
expire_logs_days = 7
```

#### 数据库初始化脚本

```sql
-- mysql/init/01-init.sql
CREATE DATABASE IF NOT EXISTS ai_resume CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

USE ai_resume;

-- 创建用户（如果不存在）
CREATE USER IF NOT EXISTS 'airesume'@'%' IDENTIFIED BY 'airesume_password';
GRANT ALL PRIVILEGES ON ai_resume.* TO 'airesume'@'%';
FLUSH PRIVILEGES;
```

### 1.2 生产环境变量

```bash
# .env.production
# 数据库
DATABASE_URL=mysql+aiomysql://airesume:airesume_password@mysql:3306/ai_resume

# Redis
REDIS_URL=redis://redis:6379

# JWT
SECRET_KEY=<生产密钥，至少32字符>
ACCESS_TOKEN_EXPIRE_MINUTES=30

# AI 服务
XIAOMI_API_KEY=sk-c0uo5p7vq8h9p0fm45978gvkky3dgtbhn68uai4y2pnyt12o
DEFAULT_AI_PROVIDER=xiaomi

# CORS
CORS_ORIGINS=https://yourdomain.com

# 环境
DEBUG=false
LOG_LEVEL=INFO

# SMTP（可选）
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=your-email@gmail.com
SMTP_PASSWORD=your-app-password

# 其他
MYSQL_ROOT_PASSWORD=root_secure_password
MYSQL_PASSWORD=airesume_password
```

### 1.3 生产 Docker Compose

```yaml
# docker-compose.prod.yml
version: '3.8'

services:
  backend:
    build:
      context: ./backend
      dockerfile: Dockerfile
    container_name: ai-resume-backend
    ports:
      - "8000:8000"
    env_file:
      - .env.production
    environment:
      - DATABASE_URL=mysql+aiomysql://airesume:airesume_password@mysql:3306/ai_resume
      - REDIS_URL=redis://redis:6379
    depends_on:
      - mysql
      - redis
    volumes:
      - backend_data:/app/data
      - ./logs/backend:/app/logs
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
    networks:
      - ai-resume-network

  frontend:
    build:
      context: ./ai-resume-web
      dockerfile: Dockerfile
    container_name: ai-resume-frontend
    ports:
      - "3000:80"
    depends_on:
      - backend
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "wget", "--no-verbose", "--tries=1", "--spider", "http://localhost/"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
    networks:
      - ai-resume-network

  mysql:
    image: mysql:8.0
    container_name: ai-resume-mysql
    env_file:
      - .env.production
    volumes:
      - mysql_data:/var/lib/mysql
      - ./mysql/conf.d:/etc/mysql/conf.d
      - ./mysql/init:/docker-entrypoint-initdb.d
    ports:
      - "3306:3306"
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "localhost"]
      interval: 10s
      timeout: 5s
      retries: 5
      start_period: 30s
    networks:
      - ai-resume-network

  redis:
    image: redis:7-alpine
    container_name: ai-resume-redis
    command: redis-server --appendonly yes --requirepass ${REDIS_PASSWORD:-redispass}
    volumes:
      - redis_data:/data
    ports:
      - "6379:6379"
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 3s
      retries: 3
    networks:
      - ai-resume-network

  nginx:
    image: nginx:alpine
    container_name: ai-resume-nginx
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx/nginx.prod.conf:/etc/nginx/nginx.conf:ro
      - ./nginx/ssl:/etc/nginx/ssl:ro
      - ./logs/nginx:/var/log/nginx
    depends_on:
      - backend
      - frontend
    restart: unless-stopped
    networks:
      - ai-resume-network

volumes:
  backend_data:
  mysql_data:
  redis_data:

networks:
  ai-resume-network:
    driver: bridge
```

---

## 2. Nginx 配置

### 2.1 生产 Nginx 配置

```nginx
# nginx/nginx.prod.conf
user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log warn;
pid /var/run/nginx.pid;

events {
    worker_connections 2048;
    use epoll;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                    '$status $body_bytes_sent "$http_referer" '
                    '"$http_user_agent" "$http_x_forwarded_for" '
                    '$request_time $upstream_response_time';

    access_log /var/log/nginx/access.log main;

    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;
    client_max_body_size 10M;

    # Gzip 压缩
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_comp_level 6;
    gzip_types text/plain text/css text/xml text/javascript
               application/json application/javascript application/xml+rss
               application/rss+xml font/truetype font/opentype
               application/vnd.ms-fontobject image/svg+xml;

    # Rate Limiting
    limit_req_zone $binary_remote_addr zone=api:10m rate=10r/s;
    limit_conn_zone $binary_remote_addr zone=conn:10m;

    # Upstream
    upstream backend {
        server backend:8000;
        keepalive 64;
    }

    # HTTP Server (重定向到 HTTPS)
    server {
        listen 80;
        server_name yourdomain.com www.yourdomain.com;

        # Let's Encrypt ACME Challenge
        location /.well-known/acme-challenge/ {
            root /var/www/certbot;
        }

        location / {
            return 301 https://$server_name$request_uri;
        }
    }

    # HTTPS Server
    server {
        listen 443 ssl http2;
        server_name yourdomain.com www.yourdomain.com;

        # SSL 证书
        ssl_certificate /etc/nginx/ssl/fullchain.pem;
        ssl_certificate_key /etc/nginx/ssl/privkey.pem;

        # SSL 配置
        ssl_protocols TLSv1.2 TLSv1.3;
        ssl_ciphers 'ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384';
        ssl_prefer_server_ciphers off;
        ssl_session_cache shared:SSL:10m;
        ssl_session_timeout 1d;
        ssl_session_tickets off;

        # HSTS
        add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;

        # 前端静态文件
        location / {
            root /usr/share/nginx/html;
            try_files $uri $uri/ /index.html;
            add_header Cache-Control "public, max-age=3600";
        }

        # API 代理
        location /api/ {
            limit_req zone=api burst=20 nodelay;
            limit_conn conn 10;

            proxy_pass http://backend;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_set_header Connection "";
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "upgrade";

            proxy_connect_timeout 60s;
            proxy_send_timeout 60s;
            proxy_read_timeout 60s;
        }

        # 健康检查
        location /health {
            proxy_pass http://backend/health;
            access_log off;
        }

        # 安全头部
        add_header X-Frame-Options "SAMEORIGIN" always;
        add_header X-Content-Type-Options "nosniff" always;
        add_header X-XSS-Protection "1; mode=block" always;
        add_header Referrer-Policy "strict-origin-when-cross-origin" always;
    }
}
```

---

## 3. SSL/TLS 配置

### 3.1 使用 Let's Encrypt

#### 安装 Certbot

```bash
# Ubuntu/Debian
sudo apt-get update
sudo apt-get install -y certbot

# CentOS/RHEL
sudo yum install -y certbot
```

#### 获取 SSL 证书

```bash
# 创建证书目录
sudo mkdir -p /etc/nginx/ssl

# 获取证书（HTTP 验证）
sudo certbot certonly --standalone \
    -d yourdomain.com \
    -d www.yourdomain.com \
    --email your-email@example.com \
    --agree-tos \
    --non-interactive

# 证书位置
# /etc/letsencrypt/live/yourdomain.com/fullchain.pem
# /etc/letsencrypt/live/yourdomain.com/privkey.pem
```

#### 复制证书到 Nginx 目录

```bash
sudo cp /etc/letsencrypt/live/yourdomain.com/fullchain.pem /etc/nginx/ssl/
sudo cp /etc/letsencrypt/live/yourdomain.com/privkey.pem /etc/nginx/ssl/
sudo chmod 600 /etc/nginx/ssl/privkey.pem
```

#### 自动续期

```bash
# 添加 cron 任务
sudo crontab -e

# 每月 1 日凌晨 2 点续期
0 2 1 * * certbot renew --quiet && cp /etc/letsencrypt/live/yourdomain.com/*.pem /etc/nginx/ssl/ && docker-compose -f /path/to/docker-compose.prod.yml restart nginx
```

---

## 4. 监控和日志

### 4.1 日志配置

```yaml
# docker-compose.prod.yml
services:
  backend:
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "7"

  frontend:
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "7"

  nginx:
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "7"
```

### 4.2 监控脚本

```bash
#!/bin/bash
# scripts/monitor.sh

# 健康检查
check_health() {
    echo "Checking health..."
    curl -f http://localhost:8000/health || echo "Backend unhealthy"
    curl -f http://localhost:3000 || echo "Frontend unhealthy"
}

# 检查磁盘使用
check_disk() {
    echo "Disk usage:"
    df -h
}

# 检查内存使用
check_memory() {
    echo "Memory usage:"
    free -h
}

# 主函数
main() {
    check_health
    check_disk
    check_memory
}

main
```

---

## 5. 备份策略

### 5.1 数据库备份

```bash
#!/bin/bash
# scripts/backup-db.sh

DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/backups/mysql"
MYSQL_CONTAINER="ai-resume-mysql"

# 创建备份目录
mkdir -p $BACKUP_DIR

# 备份数据库
docker exec $MYSQL_CONTAINER mysqldump \
    -u airesume \
    -pairesume_password \
    --single-transaction \
    --quick \
    --lock-tables=false \
    ai_resume > $BACKUP_DIR/ai_resume_$DATE.sql

# 压缩备份
gzip $BACKUP_DIR/ai_resume_$DATE.sql

# 删除 7 天前的备份
find $BACKUP_DIR -name "ai_resume_*.sql.gz" -mtime +7 -delete

echo "Backup completed: ai_resume_$DATE.sql.gz"
```

### 5.2 自动备份（Cron）

```bash
# 添加到 crontab
0 2 * * * /path/to/ai-resume/scripts/backup-db.sh
```

---

## 6. 部署脚本

```bash
#!/bin/bash
# scripts/deploy.sh

set -e

echo "================================"
echo "AI Resume Platform - Deploy"
echo "================================"

# 拉取最新代码
echo "Pulling latest code..."
git pull origin main

# 构建镜像
echo "Building images..."
docker-compose -f docker-compose.prod.yml build

# 停止旧容器
echo "Stopping old containers..."
docker-compose -f docker-compose.prod.yml down

# 启动新容器
echo "Starting new containers..."
docker-compose -f docker-compose.prod.yml up -d

# 等待服务启动
echo "Waiting for services to start..."
sleep 30

# 健康检查
echo "Running health checks..."
curl -f http://localhost:8000/health || exit 1
curl -f http://localhost:3000 || exit 1

echo "================================"
echo "Deployment completed successfully!"
echo "================================"
```

---

## 完成检查清单

### 环境配置
- [ ] MySQL 配置完成
- [ ] 生产环境变量配置完成
- [ ] Docker Compose 配置完成

### SSL/TLS
- [ ] Certbot 已安装
- [ ] SSL 证书已获取
- [ ] Nginx SSL 配置完成
- [ ] 自动续期已配置

### 监控和日志
- [ ] 日志轮转配置完成
- [ ] 监控脚本创建完成
- [ ] 健康检查配置完成

### 备份
- [ ] 数据库备份脚本完成
- [ ] 自动备份已配置
- [ ] 备份验证完成

### 部署
- [ ] 部署脚本完成
- [ ] 回滚策略制定完成
- [ ] 部署测试通过

---

**下一步**: 选项 D - 直接上线部署
