# 统一登录与资料绑定系统 - 部署指南

## 📦 快速开始

### 1. 环境配置

#### 后端配置 (.env)

```bash
# 基础配置
DEBUG=True
SECRET_KEY=your-secret-key-change-this-in-production
API_BASE_URL=http://localhost:8000
FRONTEND_URL=http://localhost:5173

# 数据库（开发用SQLite，生产用PostgreSQL）
DATABASE_URL=sqlite:///./ai_resume.db

# Redis（可选，用于生产环境验证码存储）
REDIS_URL=redis://localhost:6379/0

# JWT Token配置
ACCESS_TOKEN_EXPIRE_MINUTES=30
REFRESH_TOKEN_EXPIRE_DAYS=7

# OAuth配置 - Google（可选）
# 获取方式：https://console.cloud.google.com/apis/credentials
GOOGLE_CLIENT_ID=your-google-client-id
GOOGLE_CLIENT_SECRET=your-google-client-secret

# OAuth配置 - GitHub（可选）
# 获取方式：https://github.com/settings/developers
GITHUB_CLIENT_ID=your-github-client-id
GITHUB_CLIENT_SECRET=your-github-client-secret

# 微信登录（开发环境模拟，生产需要企业资质）
WECHAT_APP_ID=
WECHAT_APP_SECRET=

# 邮件服务配置（QQ邮箱示例）
SMTP_HOST=smtp.qq.com
SMTP_PORT=587
SMTP_USER=your@qq.com
SMTP_PASSWORD=your-qq-smtp-password
SMTP_FROM=your@qq.com
SMTP_FROM_NAME=AI简历平台
```

#### 前端配置 (.env)

```bash
# API地址
VITE_API_URL=http://localhost:8000

# 其他配置
VITE_APP_NAME=AI Resume
VITE_APP_VERSION=1.0.0
```

### 2. 安装依赖

#### 后端依赖

```bash
cd backend
pip install -r requirements.txt

# 需要添加的新依赖
pip install httpx
```

如果 `requirements.txt` 不包含以下包，请手动添加：

```txt
httpx>=0.24.0
redis>=4.5.0
```

#### 前端依赖

前端已经包含所有必需依赖，无需额外安装。

### 3. 数据库初始化

```bash
cd backend

# 创建所有表
python -c "from app.core.database import init_db; import asyncio; asyncio.run(init_db())"
```

### 4. 启动服务

#### 启动后端

```bash
cd backend
python -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

#### 启动前端

```bash
cd ai-resume-web
pnpm dev
```

### 5. 访问应用

- 前端地址：http://localhost:5173
- 后端API：http://localhost:8000
- API文档：http://localhost:8000/docs

---

## 🔧 配置说明

### 免费邮箱服务配置

#### QQ邮箱（推荐）

1. 登录QQ邮箱：https://mail.qq.com
2. 设置 -> 账户 -> SMTP服务
3. 开启"POP3/SMTP服务"
4. 生成授权码（不是QQ密码！）
5. 配置到 `.env`：

```bash
SMTP_HOST=smtp.qq.com
SMTP_PORT=587
SMTP_USER=your@qq.com
SMTP_PASSWORD=your-authorization-code
SMTP_FROM=your@qq.com
```

#### 163邮箱

```bash
SMTP_HOST=smtp.163.com
SMTP_PORT=465
SMTP_USER=your@163.com
SMTP_PASSWORD=your-authorization-code
SMTP_FROM=your@163.com
```

#### Gmail

```bash
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=your@gmail.com
SMTP_PASSWORD=your-app-password
SMTP_FROM=your@gmail.com
```

### OAuth配置（可选）

#### Google OAuth

1. 访问：https://console.cloud.google.com/apis/credentials
2. 创建新项目或选择现有项目
3. 创建OAuth 2.0客户端ID
4. 授权重定向URI：`http://localhost:8000/api/v1/oauth/callback/google`
5. 复制客户端ID和密钥到 `.env`

#### GitHub OAuth

1. 访问：https://github.com/settings/developers
2. 点击"New OAuth App"
3. 设置：
   - Application name: AI Resume
   - Homepage URL: `http://localhost:5173`
   - Authorization callback URL: `http://localhost:8000/api/v1/oauth/callback/github`
4. 复制Client ID和Client Secret到 `.env`

### 微信登录说明

**开发环境**：使用模拟实现，无需真实微信授权

**生产环境**：
1. 需要企业资质（微信开放平台）
2. 申请网站应用
3. 配置AppID和AppSecret

---

## 🚀 生产环境部署

### 1. 使用PostgreSQL

```bash
# .env
DATABASE_URL=postgresql+asyncpg://user:password@localhost/ai_resume
```

### 2. 使用Redis

```bash
# 安装Redis
sudo apt install redis-server  # Ubuntu/Debian
brew install redis             # macOS

# 启动Redis
sudo systemctl start redis
```

### 3. 使用Nginx反向代理

```nginx
# /etc/nginx/sites-available/ai-resume

# 后端API
server {
    listen 80;
    server_name api.yourdomain.com;

    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}

# 前端
server {
    listen 80;
    server_name www.yourdomain.com;

    root /path/to/ai-resume-web/dist;
    index index.html;

    location / {
        try_files $uri $uri/ /index.html;
    }
}
```

### 4. 使用Systemd服务

```ini
# /etc/systemd/system/ai-resume-backend.service

[Unit]
Description=AI Resume Backend
After=network.target

[Service]
User=www-data
WorkingDirectory=/path/to/backend
Environment="PATH=/path/to/backend/venv/bin"
ExecStart=/path/to/backend/venv/bin/uvicorn app.main:app --host 0.0.0.0 --port 8000
Restart=always

[Install]
WantedBy=multi-user.target
```

启动服务：

```bash
sudo systemctl daemon-reload
sudo systemctl enable ai-resume-backend
sudo systemctl start ai-resume-backend
```

---

## 📋 功能测试清单

### 基础登录

- [ ] 邮箱密码登录
- [ ] 注册并发送验证码邮件
- [ ] 验证邮箱
- [ ] 忘记密码（邮箱重置）

### 手机号登录

- [ ] 手机号密码登录
- [ ] 使用邮箱验证码验证手机号

### OAuth登录

- [ ] Google授权登录
- [ ] GitHub授权登录
- [ ] 微信扫码登录（模拟）

### 账号管理

- [ ] 绑定邮箱
- [ ] 绑定手机号
- [ ] 解绑账号（至少保留一种）
- [ ] 查看所有已绑定账号

---

## 🔒 安全建议

### 生产环境必须

1. **修改SECRET_KEY**
   ```bash
   python -c "import secrets; print(secrets.token_urlsafe(32))"
   ```

2. **使用HTTPS**
   - 配置SSL证书（Let's Encrypt免费）

3. **启用CORS保护**
   - 在 `backend/app/core/config.py` 中配置允许的域名

4. **定期更新依赖**
   ```bash
   pip list --outdated
   pip install --upgrade package-name
   ```

5. **启用日志记录**
   - 监控异常登录尝试
   - 记录敏感操作

---

## 💡 常见问题

### Q: 验证码邮件发送失败？

A: 检查SMTP配置：
1. 确认授权码正确（不是邮箱密码）
2. 检查SMTP端口和主机
3. 查看后端日志错误信息

### Q: OAuth回调失败？

A: 检查：
1. 回调URL是否正确配置
2. OAuth应用配置的回调URL是否匹配
3. `.env` 中的配置是否正确

### Q: 手机号无法登录？

A: 手机号登录使用邮箱验证码：
1. 先绑定邮箱
2. 使用邮箱验证码验证手机号
3. 手机号+密码登录

### Q: Redis连接失败？

A: Redis可选，系统会自动降级到内存存储：
1. 检查Redis是否运行
2. 检查 `.env` 中的 `REDIS_URL`
3. 如果只是开发测试，可以不启动Redis

---

## 📞 技术支持

- 查看API文档：http://localhost:8000/docs
- 查看完整源码：`UNIFIED_LOGIN_SYSTEM.md`
- 查看部署指南：`UNIFIED_LOGIN_DEPLOYMENT.md`（本文件）

---

## ✨ 系统特色

### 完全免费方案

✅ **邮箱服务**：使用QQ/163/Gmail免费邮箱
✅ **验证码**：邮箱验证码（5分钟有效期）
✅ **OAuth**：Google/GitHub个人开发者账号（免费）
✅ **手机验证**：使用邮箱验证码替代短信（0成本）

### 无需企业资质

✅ 个人邮箱即可部署
✅ 个人OAuth应用即可
✅ 无需短信服务商
✅ 无需微信开放平台（开发环境）

### 开箱即用

✅ 一键启动
✅ 自动降级（Redis失败→内存存储）
✅ 详细API文档
✅ 完整示例代码

---

**🎉 恭喜！你已拥有完整的统一登录与资料绑定系统！**
