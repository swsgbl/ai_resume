# AI简历平台 - 服务器部署指南

## 服务器信息

| 项目 | 配置 |
|------|------|
| 服务器 | 腾讯云轻量应用服务器 |
| 区域 | 华南-广州 |
| 配置 | 2核 | 2GiB | 40GiB |
| 带宽 | 2Mbps | 100GB流量 |
| IP | 113.45.64.145 |
| 系统 | Ubuntu 24.04 LTS |

## 部署步骤

### 1. 连接服务器

```bash
ssh root@113.45.64.145
```

### 2. 上传部署脚本

在本地执行：

```bash
# 进入项目目录
cd D:\ai_resume

# 使用 scp 上传脚本 (Windows 可用 WinSCP 或其他工具)
scp deploy/setup_server.sh root@113.45.64.145:/root/
scp deploy/deploy_app.sh root@113.45.64.145:/root/
```

### 3. 运行环境安装脚本

在服务器上执行：

```bash
chmod +x /root/setup_server.sh
sudo /root/setup_server.sh
```

### 4. 上传项目代码

```bash
# 方式1: 使用 git (推荐)
mkdir -p /var/www/ai-resume
cd /var/www/ai-resume
git clone <你的仓库地址> backend
git clone <你的仓库地址> frontend

# 方式2: 使用 scp 上传
scp -r AI-/ai-resume-platform/backend root@113.45.64.145:/var/www/ai-resume/
scp -r ai-resume-web root@113.45.64.145:/var/www/ai-resume/frontend
```

### 5. 运行应用部署脚本

```bash
chmod +x /root/deploy_app.sh
sudo /root/deploy_app.sh
```

### 6. 配置后端环境变量

编辑 `/var/www/ai-resume/backend/.env`：

```bash
SECRET_KEY=$(openssl rand -hex 32)
DEBUG=False
USE_SQLITE=True
DEFAULT_AI_PROVIDER=deepseek
DEEPSEEK_API_KEY=你的DeepSeek_API_Key
```

### 7. 配置 SSL 证书 (可选)

使用 Let's Encrypt 免费 SSL：

```bash
apt install -y certbot python3-certbot-nginx
certbot --nginx -d your-domain.com
```

## 优化建议 (针对2GB内存)

### 已应用优化

1. **交换空间**: 创建2GB swap防止内存溢出
2. **Nginx优化**:
   - Gzip 压缩 (节省带宽)
   - 静态资源缓存 (1年)
   - 禁用访问日志 (减少IO)
3. **后端配置**:
   - 单worker (避免内存不足)
   - SQLite数据库 (轻量级)

### 进一步优化 (可选)

1. **使用CDN**: 将前端静态资源放到腾讯云COS
2. **禁用Redis**: 2GB内存建议不用Redis
3. **限制日志大小**: 配置logrotate

## 服务管理

```bash
# 查看后端状态
supervisorctl status ai-resume-backend

# 重启后端
supervisorctl restart ai-resume-backend

# 重启Nginx
systemctl restart nginx

# 查看日志
tail -f /var/www/ai-resume/logs/backend.log
```

## 访问地址

- 前端: http://113.45.64.145
- API: http://113.45.64.145/api/v1/
- 文档: http://113.45.64.145/docs
