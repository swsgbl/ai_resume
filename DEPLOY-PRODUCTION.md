# 选项 D：直接上线部署

## 部署步骤

### 1. 准备工作

#### 1.1 检查服务器环境

```bash
# 检查 Docker
docker --version
docker-compose --version

# 检查磁盘空间
df -h

# 检查内存
free -h

# 检查端口占用
netstat -tlnp | grep -E ':(80|443|3000|8000|3306|6379)'
```

#### 1.2 克隆代码（如果还没有）

```bash
# 克隆代码
git clone https://github.com/your-username/ai-resume.git
cd ai-resume

# 或者如果是本地服务器，使用 rsync
rsync -avz /path/to/local/ai-resume/ user@server:/path/to/ai-resume/
```

---

### 2. 配置环境

#### 2.1 创建生产环境变量

```bash
# 复制环境变量模板
cp .env.example .env.production

# 编辑生产环境变量
nano .env.production
```

```bash
# .env.production
DATABASE_URL=mysql+aiomysql://airesume:AIRESUME_SECURE_PASSWORD@mysql:3306/ai_resume
REDIS_URL=redis://redis:6379
SECRET_KEY=$(python3 -c "import secrets; print(secrets.token_urlsafe(32))")
XIAOMI_API_KEY=sk-c0uo5p7vq8h9p0fm45978gvkky3dgtbhn68uai4y2pnyt12o
DEFAULT_AI_PROVIDER=xiaomi
CORS_ORIGINS=https://yourdomain.com
DEBUG=false
LOG_LEVEL=INFO

# MySQL 配置
MYSQL_ROOT_PASSWORD=ROOT_SECURE_PASSWORD
MYSQL_PASSWORD=AIRESUME_SECURE_PASSWORD
```

#### 2.2 配置 SSL 证书

```bash
# 创建 SSL 目录
mkdir -p nginx/ssl

# 获取 Let's Encrypt 证书（如果已配置域名）
sudo certbot certonly --standalone \
    -d yourdomain.com \
    -d www.yourdomain.com \
    --email your-email@example.com \
    --agree-tos \
    --non-interactive

# 复制证书
sudo cp /etc/letsencrypt/live/yourdomain.com/fullchain.pem nginx/ssl/
sudo cp /etc/letsencrypt/live/yourdomain.com/privkey.pem nginx/ssl/
sudo chmod 600 nginx/ssl/privkey.pem
```

**注意**: 如果没有域名，可以先使用自签名证书：

```bash
# 生成自签名证书
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout nginx/ssl/privkey.pem \
    -out nginx/ssl/fullchain.pem \
    -subj "/C=CN/ST=Beijing/L=Beijing/O=AI Resume/CN=localhost"
```

---

### 3. 部署应用

#### 3.1 使用部署脚本（推荐）

```bash
# 给脚本添加执行权限（如果还没有）
chmod +x scripts/*.sh

# 运行部署脚本
./scripts/deploy.sh
```

#### 3.2 手动部署

```bash
# 拉取最新代码
git pull origin main

# 构建镜像
docker-compose -f docker-compose.prod.yml build

# 启动服务
docker-compose -f docker-compose.prod.yml up -d

# 查看日志
docker-compose -f docker-compose.prod.yml logs -f
```

---

### 4. 验证部署

#### 4.1 健康检查

```bash
# 检查所有服务状态
docker-compose -f docker-compose.prod.yml ps

# 检查后端健康
curl http://localhost:8000/health

# 检查前端
curl http://localhost:3000

# 检查 Nginx
curl http://localhost:80
```

#### 4.2 运行监控脚本

```bash
# 运行监控脚本
./scripts/monitor.sh
```

#### 4.3 访问应用

打开浏览器访问：
- 前端: http://yourdomain.com 或 http://your-server-ip
- API 文档: http://yourdomain.com/api/docs
- 健康检查: http://yourdomain.com/health

---

### 5. 配置自动备份

#### 5.1 配置数据库自动备份

```bash
# 编辑 crontab
crontab -e

# 添加以下行（每天凌晨 2 点备份）
0 2 * * * /path/to/ai-resume/scripts/backup-db.sh >> /var/log/ai-resume/backup.log 2>&1
```

#### 5.2 验证备份

```bash
# 手动运行一次备份
./scripts/backup-db.sh

# 查看备份文件
ls -lh /backups/mysql/
```

---

### 6. 配置监控

#### 6.1 定期监控

```bash
# 编辑 crontab
crontab -e

# 添加以下行（每小时检查一次）
0 * * * * /path/to/ai-resume/scripts/monitor.sh >> /var/log/ai-resume/monitor.log 2>&1
```

#### 6.2 配置告警（可选）

可以使用 Prometheus + Grafana 或其他监控工具。

---

## 常用命令

### 查看日志

```bash
# 查看所有日志
docker-compose -f docker-compose.prod.yml logs

# 查看特定服务日志
docker-compose -f docker-compose.prod.yml logs backend
docker-compose -f docker-compose.prod.yml logs frontend
docker-compose -f docker-compose.prod.yml logs nginx

# 实时查看日志
docker-compose -f docker-compose.prod.yml logs -f backend
```

### 管理服务

```bash
# 停止服务
docker-compose -f docker-compose.prod.yml stop

# 启动服务
docker-compose -f docker-compose.prod.yml start

# 重启服务
docker-compose -f docker-compose.prod.yml restart

# 停止并删除容器
docker-compose -f docker-compose.prod.yml down

# 停止并删除容器和数据卷
docker-compose -f docker-compose.prod.yml down -v
```

### 更新部署

```bash
# 使用部署脚本（推荐）
./scripts/deploy.sh

# 或者手动更新
git pull origin main
docker-compose -f docker-compose.prod.yml build
docker-compose -f docker-compose.prod.yml up -d
```

### 数据库操作

```bash
# 进入 MySQL 容器
docker-compose -f docker-compose.prod.yml exec mysql bash

# 登录 MySQL
mysql -u airesume -p ai_resume

# 导出数据库
docker-compose -f docker-compose.prod.yml exec -T mysql mysqldump \
    -u airesume -p ai_resume > backup.sql

# 导入数据库
docker-compose -f docker-compose.prod.yml exec -T mysql mysql \
    -u airesume -p ai_resume < backup.sql
```

---

## 故障排查

### 问题 1: 容器无法启动

```bash
# 查看容器状态
docker-compose -f docker-compose.prod.yml ps

# 查看容器日志
docker-compose -f docker-compose.prod.yml logs <service-name>

# 重启容器
docker-compose -f docker-compose.prod.yml restart <service-name>
```

### 问题 2: 数据库连接失败

```bash
# 检查 MySQL 容器状态
docker-compose -f docker-compose.prod.yml ps mysql

# 查看 MySQL 日志
docker-compose -f docker-compose.prod.yml logs mysql

# 进入 MySQL 容器
docker-compose -f docker-compose.prod.yml exec mysql bash

# 测试 MySQL 连接
mysql -u airesume -p ai_resume -e "SELECT 1"
```

### 问题 3: Nginx 502 错误

```bash
# 检查后端服务状态
docker-compose -f docker-compose.prod.yml ps backend

# 查看后端日志
docker-compose -f docker-compose.prod.yml logs backend

# 检查 Nginx 配置
docker-compose -f docker-compose.prod.yml exec nginx nginx -t

# 重启 Nginx
docker-compose -f docker-compose.prod.yml restart nginx
```

### 问题 4: SSL 证书错误

```bash
# 检查证书文件
ls -l nginx/ssl/

# 验证证书
openssl x509 -in nginx/ssl/fullchain.pem -text -noout

# 重新生成证书
sudo certbot renew

# 重启 Nginx
docker-compose -f docker-compose.prod.yml restart nginx
```

---

## 性能优化

### 1. 数据库优化

```sql
-- 登录 MySQL
mysql -u airesume -p ai_resume

-- 创建索引（如果需要）
CREATE INDEX idx_resumes_user_id ON resumes(user_id);
CREATE INDEX idx_resumes_status ON resumes(status);

-- 分析表
ANALYZE TABLE resumes;
```

### 2. Redis 缓存

```bash
# 配置 Redis 持久化（已在 docker-compose.prod.yml 中配置）
# 开启 AOF
# 配置最大内存
```

### 3. Nginx 优化

已在 `nginx/nginx.prod.conf` 中配置：
- Gzip 压缩
- Keep-alive 连接
- Rate Limiting
- Upstream 连接池

---

## 安全加固

### 1. 防火墙配置

```bash
# Ubuntu/Debian
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw enable

# CentOS/RHEL
sudo firewall-cmd --permanent --add-service=ssh
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --permanent --add-service=https
sudo firewall-cmd --reload
```

### 2. SSH 安全

```bash
# 编辑 SSH 配置
sudo nano /etc/ssh/sshd_config

# 禁用 root 登录
PermitRootLogin no

# 禁用密码登录（仅允许密钥）
PasswordAuthentication no

# 更改默认端口
Port 2222

# 重启 SSH
sudo systemctl restart sshd
```

### 3. 定期更新

```bash
# 更新系统
sudo apt update && sudo apt upgrade -y

# 更新 Docker
sudo apt install --only-upgrade docker-ce docker-ce-cli containerd.io
```

---

## 完成检查清单

### 部署前
- [ ] 服务器环境检查完成
- [ ] 代码克隆完成
- [ ] 生产环境变量配置完成
- [ ] SSL 证书配置完成

### 部署中
- [ ] Docker 镜像构建完成
- [ ] 所有服务启动成功
- [ ] 健康检查通过

### 部署后
- [ ] 应用访问正常
- [ ] 数据库连接正常
- [ ] 日志记录正常
- [ ] 备份配置完成
- [ ] 监控配置完成
- [ ] 防火墙配置完成
- [ ] SSL 证书正常

---

## 成功上线标志

- ✅ 所有服务正常运行
- ✅ 健康检查全部通过
- ✅ 前端可以正常访问
- ✅ API 接口正常响应
- ✅ 数据库连接正常
- ✅ 日志记录正常
- ✅ 备份已配置
- ✅ 监控已配置

---

## 恭喜！🎉

AI Resume Platform 已成功上线！

**访问地址**:
- 前端: https://yourdomain.com
- API 文档: https://yourdomain.com/api/docs
- 健康检查: https://yourdomain.com/health

**后续维护**:
- 定期检查日志
- 定期备份数据
- 定期更新系统
- 监控服务状态

---

**项目完成度**: 100% ✅

**感谢使用 AI Resume Platform！**
