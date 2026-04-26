# 步骤5: 配置环境变量

## 环境变量概览

AI Resume Platform 需要配置以下环境变量：

### 应用配置
- `SECRET_KEY`: Flask密钥（生产环境必须随机生成）
- `DEBUG`: 调试模式（生产环境设为False）
- `HOST`: 监听地址（0.0.0.0）
- `PORT`: 监听端口（8000）
- `USE_SQLITE`: 使用SQLite数据库（True）

### AI服务配置
- `DEFAULT_AI_PROVIDER`: 默认AI提供商（deepseek）
- `DEEPSEEK_API_KEY`: DeepSeek API密钥
- `DEEPSEEK_MODEL`: 模型名称（deepseek-chat）
- `DEEPSEEK_BASE_URL`: API基础URL

### 缓存配置
- `REDIS_URL`: Redis连接URL

### 邮件配置
- `SMTP_HOST`: SMTP服务器地址
- `SMTP_PORT`: SMTP端口（587）
- `SMTP_USER`: SMTP用户名
- `SMTP_PASSWORD`: SMTP密码

## 在Dokploy中配置环境变量

### 方法1: 通过服务配置界面

1. 进入 **"ai-resume-backend"** 服务
2. 点击 **"Environment Variables"** 标签
3. 点击 **"Add Variable"** 添加每个变量
4. 点击 **"Save"** 保存

### 方法2: 通过.env文件

1. 在Dokploy项目中创建 `.env.production` 文件
2. 填写环境变量配置
3. 在Docker Compose中引用: `${VARIABLE_NAME}`

### 环境变量配置模板

```bash
# ============================================
# AI Resume Platform - Production Environment
# ============================================

# 应用配置
SECRET_KEY=change-this-to-a-random-50-char-string-in-production
DEBUG=False
HOST=0.0.0.0
PORT=8000

# 数据库配置
USE_SQLITE=True
# DATABASE_URL=postgresql://user:pass@host:5432/dbname  # 如需PostgreSQL

# 缓存配置
REDIS_URL=redis://ai-resume-redis:6379/0

# ============================================
# AI服务配置
# ============================================

DEFAULT_AI_PROVIDER=deepseek
DEEPSEEK_API_KEY=your-deepseek-api-key-here
DEEPSEEK_MODEL=deepseek-chat
DEEPSEEK_BASE_URL=https://api.deepseek.com

# 备用AI服务（可选）
# OPENAI_API_KEY=your-openai-api-key
# OPENAI_MODEL=gpt-4
# OPENAI_BASE_URL=https://api.openai.com/v1

# ============================================
# 邮件服务配置 (SMTP)
# ============================================

SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=your-email@gmail.com
SMTP_PASSWORD=your-app-specific-password

# 邮件发件人信息
SMTP_FROM=noreply@happy.ndtool.cn
SMTP_FROM_NAME=AI Resume Platform

# ============================================
# 安全配置
# ============================================

# JWT配置
JWT_SECRET_KEY=change-this-to-another-random-string
JWT_ALGORITHM=HS256
JWT_EXPIRE_MINUTES=60

# CORS配置（允许的前端域名）
CORS_ORIGINS=http://localhost:3000,http://113.45.64.145:8081,https://happy.ndtool.cn

# ============================================
# 日志配置
# ============================================

LOG_LEVEL=INFO
LOG_FORMAT=json

# ============================================
# 限流配置
# ============================================

RATE_LIMIT_ENABLED=True
RATE_LIMIT_PER_MINUTE=60
```

## 敏感信息处理

### 生成SECRET_KEY

```bash
# 方法1: 使用Python
python3 -c "import secrets; print(secrets.token_urlsafe(50))"

# 方法2: 使用OpenSSL
openssl rand -hex 32

# 方法3: 使用uuidgen
uuidgen | sha256sum | head -c 50
```

### 生成JWT_SECRET_KEY

```bash
python3 -c "import secrets; print(secrets.token_urlsafe(32))"
```

### 获取DeepSeek API密钥

1. 访问: https://platform.deepseek.com/
2. 注册/登录账号
3. 进入 **API Keys** 页面
4. 创建新的API密钥
5. 复制密钥到环境变量

### 配置Gmail SMTP

1. 启用两步验证: https://myaccount.google.com/security
2. 生成应用专用密码:
   - 访问: https://myaccount.google.com/apppasswords
   - 选择"邮件" → "其他（自定义名称）"
   - 输入"AI Resume Platform"
   - 点击"生成"
   - 复制16位密码（去除空格）

## 环境变量最佳实践

### 1. 安全原则

- ✅ 使用强随机密钥（至少50字符）
- ✅ 永远不要提交.env文件到Git
- ✅ 使用.env.example作为模板
- ✅ 生产环境使用不同的密钥

### 2. 配置管理

```
项目目录结构:
ai-resume/
├── .env                    # 本地开发（不提交）
├── .env.example           # 环境变量模板（提交）
├── .env.production        # 生产环境（不提交）
└── .gitignore             # 包含.env*
```

在 `.gitignore` 中添加:
```
.env
.env.local
.env.*.local
```

### 3. 敏感信息替换

在Dokploy部署前，需要替换以下占位符:

| 占位符 | 替换为 | 生成方式 |
|--------|--------|----------|
| `change-this-to-a-random-50-char-string` | SECRET_KEY | `python3 -c "import secrets; print(secrets.token_urlsafe(50))"` |
| `your-deepseek-api-key-here` | DeepSeek API Key | 从 https://platform.deepseek.com/ 获取 |
| `your-email@gmail.com` | SMTP邮箱 | 你的Gmail地址 |
| `your-app-specific-password` | 应用密码 | Gmail应用专用密码 |

## 验证环境变量

部署前验证配置:

```bash
# 1. 检查环境变量文件
cat .env.production

# 2. 验证必需变量已设置
grep -E "SECRET_KEY|DEEPSEEK_API_KEY|SMTP_USER" .env.production

# 3. 检查没有空值
grep "= $" .env.production

# 4. 验证JSON格式（如果使用）
cat .env.production | jq .
```

## 前端环境变量

前端应用的环境变量需要在**构建时**注入:

### frontend/.env.production

```bash
# API配置
VITE_API_BASE_URL=http://113.45.64.145:8001
VITE_API_BASE_URL_SSL=https://api.happy.ndtool.cn

# 应用配置
VITE_APP_TITLE=AI智能体简历
VITE_APP_VERSION=1.0.0
VITE_APP_DESCRIPTION=AI-powered resume builder

# 功能开关
VITE_ENABLE_ANALYTICS=false
VITE_ENABLE_DEBUG=false
```

## 故障排查

**问题1: 环境变量未生效**
- 重启容器: `docker-compose restart`
- 检查环境变量在Dokploy中正确保存
- 验证没有语法错误（多余的空格、引号）

**问题2: SECRET_KEY错误**
- 确保生成足够长的随机密钥（50+字符）
- 验证密钥中没有特殊字符导致解析错误
- 检查密钥在所有环境中一致

**问题3: API调用失败**
- 验证DEEPSEEK_API_KEY正确
- 检查DEEPSEEK_BASE_URL可访问
- 测试API: `curl https://api.deepseek.com/v1/models`

**问题4: SMTP发送失败**
- 确认Gmail应用专用密码正确（16位，无空格）
- 检查SMTP端口587未被防火墙阻止
- 验证"允许不够安全的应用"已启用（或使用应用密码）

## 完成标志

✅ 所有必需环境变量已配置
✅ 敏感信息已正确替换
✅ 配置文件已保存
✅ 可以继续触发部署

---

**环境变量检查清单**:

- [ ] SECRET_KEY已生成（50+字符随机字符串）
- [ ] DEEPSEEK_API_KEY已设置
- [ ] SMTP配置完整
- [ ] JWT_SECRET_KEY已生成
- [ ] CORS_ORIGINS包含前端域名
- [ ] 生产环境DEBUG=False
- [ ] REDIS_URL正确指向Redis服务

---

**配置文件位置**:
- 后端环境变量: Dokploy服务配置 → Environment Variables
- 前端环境变量: frontend/.env.production（构建时注入）
- Docker Compose: docker-compose.yml中引用 `${VAR_NAME}`
