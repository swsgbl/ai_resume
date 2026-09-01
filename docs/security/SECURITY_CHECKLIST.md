# 安全加固检查清单 (Phase 4.1)

## ✅ 已实现的安全功能

### 1. 安全头部 (Security Headers)
**文件**: `backend/app/middleware/security.py`

| 头部 | 状态 | 说明 |
|------|------|------|
| X-Content-Type-Options | ✅ | 防止 MIME 类型嗅探 |
| X-Frame-Options | ✅ | 防止点击劫持 (DENY) |
| X-XSS-Protection | ✅ | 启用 XSS 过滤器 |
| Referrer-Policy | ✅ | 控制引用信息泄露 |
| Permissions-Policy | ✅ | 限制浏览器权限 |
| Strict-Transport-Security | ✅ | 生产环境启用 HSTS |
| Content-Security-Policy | ✅ | 开发/生产环境分别配置 |

### 2. CORS 策略
**文件**: `backend/app/main.py`

```python
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS,  # 可配置
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
```

**生产环境配置** (`.env`):
```bash
# 只允许特定域名
CORS_ORIGINS=["https://your-domain.com", "https://www.your-domain.com"]
```

### 3. 速率限制 (Rate Limiting)
**文件**: `backend/app/core/rate_limit.py`

| 端点类型 | 限制 | 说明 |
|----------|------|------|
| 注册 | 5/hour | 严格限制 |
| 登录 | 20/minute | 防止暴力破解 |
| 密码重置 | 3/hour | 防止滥用 |
| 验证码发送 | 10/hour | 防止短信轰炸 |
| AI 生成 | 10/hour | 成本控制 |
| AI 优化 | 30/hour | 成本控制 |
| 通用 GET | 300/hour | 宽松限制 |

**存储**: Redis (生产) / 内存 (开发)

### 4. 输入验证
**文件**: `backend/app/utils/security.py`

- ✅ SQL 注入检测
- ✅ XSS 模式检测
- ✅ HTML 实体转义
- ✅ 文件上传白名单
- ✅ 文件大小限制 (10MB)
- ✅ 密码强度验证

### 5. 认证安全
**文件**: `backend/app/core/security.py`

- ✅ JWT 访问令牌 (可配置过期时间)
- ✅ JWT 刷新令牌
- ✅ bcrypt 密码哈希 (自动截断 72 字节限制)
- ✅ 基于角色的访问控制 (RBAC)

---

## ⚠️ 需要配置的项目

### 1. HTTPS 配置
**状态**: 文档已创建 (`docs/security/HTTPS_SETUP.md`)

**选项**:
- Nginx + Let's Encrypt
- Caddy (自动 HTTPS)

**操作**: 按照文档配置反向代理

### 2. 生产环境 CORS 配置
**文件**: `.env` 或 `backend/app/core/config.py`

```bash
# 开发环境
CORS_ORIGINS=["http://localhost:3000", "http://localhost:5173"]

# 生产环境 - 替换为实际域名
CORS_ORIGINS=["https://your-domain.com", "https://www.your-domain.com"]
```

### 3. Redis 配置 (用于速率限制)
**文件**: `.env`

```bash
# 开发环境可选，生产环境推荐
REDIS_URL=redis://localhost:6379/0
```

### 4. 密钥配置
**文件**: `.env`

```bash
# 生产环境必须使用强随机密钥
SECRET_KEY=your-super-secret-key-change-in-production

# 生成方法:
python -c "import secrets; print(secrets.token_urlsafe(32))"
```

---

## 🔒 安全检查命令

### 本地安全扫描

```bash
# Python 依赖安全检查
cd backend
pip install safety bandit
safety check
bandit -r app/

# NPM 审计
cd ai-resume-web
npm audit
```

### Docker 镜像扫描

```bash
# 使用 Trivy
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
    aquasec/trivy image ai-resume-backend:latest

# GitHub Actions 已配置自动扫描
```

---

## 📋 部署前检查清单

- [ ] 更新 `SECRET_KEY` 为强随机值
- [ ] 配置 `CORS_ORIGINS` 为生产域名
- [ ] 设置 `DEBUG=false`
- [ ] 配置 HTTPS (Nginx/Caddy)
- [ ] 配置 Redis (用于速率限制)
- [ ] 配置数据库密码
- [ ] 配置 AI API 密钥 (OpenAI, DeepSeek)
- [ ] 运行安全扫描 (`safety check`, `bandit`, `npm audit`)
- [ ] 验证安全头部 (curl -I https://your-domain.com)
- [ ] 测试速率限制
- [ ] 测试 CORS 策略
- [ ] 配置日志监控
- [ ] 设置备份策略

---

## 🛡️ 安全最佳实践

### 密码策略
- 最少 8 位字符
- 包含大小写字母、数字、特殊字符
- bcrypt 哈希存储

### 会话管理
- 访问令牌: 15-30 分钟 (可配置)
- 刷新令牌: 7 天 (可配置)
- 支持撤销令牌

### API 安全
- 所有 API 端点需要认证 (除登录/注册)
- 敏感操作需要二次验证
- 速率限制防止滥用

### 数据保护
- 敏感字段加密存储
- 日志脱敏处理
- 定期备份

---

## 🔗 相关文件

- `backend/app/core/security.py` - JWT 认证
- `backend/app/middleware/security.py` - 安全头部
- `backend/app/utils/security.py` - 输入验证
- `backend/app/core/rate_limit.py` - 速率限制
- `backend/app/main.py` - CORS 配置
- `docs/security/HTTPS_SETUP.md` - HTTPS 配置指南
