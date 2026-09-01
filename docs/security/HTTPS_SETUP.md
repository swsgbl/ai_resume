# HTTPS 配置指南

## 使用 Nginx + Let's Encrypt

### 1. 安装 Certbot

```bash
# Ubuntu/Debian
sudo apt update
sudo apt install certbot python3-certbot-nginx

# CentOS/RHEL
sudo yum install certbot python3-certbot-nginx
```

### 2. 获取 SSL 证书

```bash
# 自动配置 Nginx
sudo certbot --nginx -d your-domain.com -d www.your-domain.com

# 或仅获取证书，手动配置 Nginx
sudo certbot certonly --nginx -d your-domain.com
```

### 3. Nginx 配置示例

```nginx
# /etc/nginx/sites-available/ai-resume

# HTTP 重定向到 HTTPS
server {
    listen 80;
    server_name your-domain.com www.your-domain.com;
    return 301 https://$server_name$request_uri;
}

# HTTPS 配置
server {
    listen 443 ssl http2;
    server_name your-domain.com www.your-domain.com;

    # SSL 证书
    ssl_certificate /etc/letsencrypt/live/your-domain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/your-domain.com/privkey.pem;

    # SSL 配置
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;

    # 安全头部
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;
    add_header X-Frame-Options "DENY" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;

    # 日志
    access_log /var/log/nginx/ai-resume-access.log;
    error_log /var/log/nginx/ai-resume-error.log;

    # 前端静态文件
    location / {
        root /path/to/ai-resume-web/dist;
        try_files $uri $uri/ /index.html;
    }

    # 后端 API 代理
    location /api/ {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # 健康检查
    location /health {
        proxy_pass http://127.0.0.1:8000;
    }
}
```

### 4. 启用配置

```bash
sudo ln -s /etc/nginx/sites-available/ai-resume /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

### 5. 自动续期

```bash
# 测试续期
sudo certbot renew --dry-run

# Certbot 会自动创建 cron job 或 systemd timer
sudo systemctl status certbot.timer
```

---

## 使用 Caddy (自动 HTTPS)

### 1. 安装 Caddy

```bash
sudo apt install -y debian-keyring debian-archive-keyring apt-transport-https
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | sudo gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | sudo tee /etc/apt/sources.list.d/caddy-stable.list
sudo apt update
sudo apt install caddy
```

### 2. Caddyfile 配置

```
# /etc/caddy/Caddyfile
your-domain.com www.your-domain.com {
    reverse_proxy /api/* 127.0.0.1:8000
    reverse_proxy /health 127.0.0.1:8000

    root * /path/to/ai-resume-web/dist
    try_files {path} /index.html

    # 安全头部 (Caddy 自动处理 HSTS)
    header {
        X-Frame-Options "DENY"
        X-Content-Type-Options "nosniff"
        X-XSS-Protection "1; mode=block"
        Referrer-Policy "strict-origin-when-cross-origin"
    }

    # 日志
    log {
        output file /var/log/caddy/ai-resume.log
        format json
    }
}
```

### 3. 启动 Caddy

```bash
sudo systemctl enable caddy
sudo systemctl start caddy
```

---

## 环境变量配置

更新 `.env` 文件：

```bash
# 生产环境设置
DEBUG=false
CORS_ORIGINS=["https://your-domain.com", "https://www.your-domain.com"]
```

---

## 验证 HTTPS

使用以下工具验证：

1. **SSL Labs**: https://www.ssllabs.com/ssltest/
2. **Security Headers**: https://securityheaders.com/
3. **命令行检查**:
   ```bash
   curl -I https://your-domain.com
   ```
