# CORS生产环境配置更新方案
**创建时间**: 2026-04-17 10:55
**DevOps Agent**: 29126157-6833-4f1e-94bd-6493bd95d3f2
**优先级**: P1 (高优先级)
**预计完成时间**: 2026-04-18

---

## 📋 当前状态分析

### 🔍 当前CORS配置

#### Backend配置 (`backend/app/core/config.py`)
```python
# 当前配置 - 开发环境
CORS_ORIGINS: List[str] = [
    "http://localhost:3000",   # 本地开发
    "http://localhost:5173",   # Vite开发服务器
    "http://localhost:8080"    # 备用开发端口
]
```

#### 环境变量配置 (`.env.production`)
```bash
# 当前配置
ALLOWED_ORIGINS=http://localhost:3000,http://127.0.0.1:3000,http://localhost:80
VITE_API_BASE_URL=http://localhost:80/api
VITE_APP_URL=http://localhost:80

# 注释说明需要更新为生产域名
# 生产环境示例: ALLOWED_ORIGINS=https://yourdomain.com,https://www.yourdomain.com
```

#### Backend主应用 (`backend/app/main.py`)
```python
# CORS中间件配置
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
```

### ⚠️ 问题分析
1. **开发域名**: 当前使用localhost，不适合生产环境
2. **HTTP协议**: 使用http而非https，安全性不足
3. **端口暴露**: 暴露了非标准端口
4. **过于宽松**: 允许所有方法和头部，可能存在安全风险

---

## 🎯 生产环境配置方案

### 推荐生产域名
基于之前的域名决策文档：
- **主域名**: `airesume.com`
- **www域名**: `www.airesume.com`
- **API域名**: `api.airesume.com`
- **备用**: `resumeai.com`, `smartresume.ai`

### HTTPS配置
配合SSL证书配置方案，所有域名使用HTTPS协议。

---

## 🚀 实施方案

### 阶段1: 环境变量更新 (30分钟)

#### 1.1 更新生产环境配置
```bash
# .env.production
# CORS配置 - 生产环境
ALLOWED_ORIGINS=https://airesume.com,https://www.airesume.com,https://api.airesume.com
ALLOWED_METHODS=GET,POST,PUT,DELETE,OPTIONS
ALLOWED_HEADERS=Content-Type,Authorization,X-Requested-With

# 前端配置 - 生产环境
VITE_API_BASE_URL=https://api.airesume.com/api
VITE_APP_NAME=AI Resume Platform
VITE_APP_URL=https://airesume.com

# 后端配置
BACKEND_CORS_ORIGINS=["https://airesume.com","https://www.airesume.com","https://api.airesume.com"]
```

#### 1.2 创建环境变量模板
```bash
# .env.production.template
# 复制并重命名用于实际部署
cp .env.production.template .env.production
```

---

### 阶段2: 后端配置更新 (1小时)

#### 2.1 更新配置文件
```python
# backend/app/core/config.py
class Settings(BaseSettings):
    # CORS配置 - 生产环境
    CORS_ORIGINS: List[str] = [
        "https://airesume.com",
        "https://www.airesume.com", 
        "https://api.airesume.com"
    ]
    
    # 开发环境域名 (仅DEBUG=True时启用)
    DEV_CORS_ORIGINS: List[str] = [
        "http://localhost:3000",
        "http://localhost:5173",
        "http://127.0.0.1:3000"
    ]
    
    def get_cors_origins(self) -> List[str]:
        """根据环境返回适当的CORS域名"""
        if self.DEBUG:
            return self.CORS_ORIGINS + self.DEV_CORS_ORIGINS
        return self.CORS_ORIGINS
```

#### 2.2 更新主应用配置
```python
# backend/app/main.py
# 使用环境感知的CORS配置
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.get_cors_origins(),
    allow_credentials=True,
    allow_methods=settings.ALLOWED_METHODS,
    allow_headers=settings.ALLOWED_HEADERS,
)
```

---

### 阶段3: 前端配置更新 (30分钟)

#### 3.1 更新前端环境变量
```javascript
// ai-resume-web/.env.production
VITE_API_BASE_URL=https://api.airesume.com/api
VITE_APP_URL=https://airesume.com
VITE_APP_NAME=AI Resume Platform

// 确保所有API调用使用HTTPS
const API_BASE = import.meta.env.VITE_API_BASE_URL;
```

#### 3.2 更新前端配置文件
```javascript
// ai-resume-web/src/config/api.js
export const API_CONFIG = {
  baseURL: import.meta.env.VITE_API_BASE_URL || 'https://api.airesume.com/api',
  timeout: 30000,
  headers: {
    'Content-Type': 'application/json',
  }
};
```

---

### 阶段4: Docker配置更新 (30分钟)

#### 4.1 更新docker-compose配置
```yaml
# docker-compose.prod.yml
services:
  backend:
    environment:
      # 生产环境CORS配置
      - ALLOWED_ORIGINS=https://airesume.com,https://www.airesume.com,https://api.airesume.com
      - VITE_API_BASE_URL=https://api.airesume.com/api
      - VITE_APP_URL=https://airesume.com
      - ENVIRONMENT=production
      - DEBUG=false
    env_file:
      - .env.production

  frontend:
    environment:
      - VITE_API_BASE_URL=https://api.airesume.com/api
      - VITE_APP_URL=https://airesume.com
```

---

### 阶段5: Traefik路由配置 (1小时)

#### 5.1 更新动态路由配置
```yaml
# AI-/ai-resume-platform/traefik/dynamic.yml
http:
  routers:
    # 主前端路由 (HTTPS)
    web:
      rule: "Host(`airesume.com`) || Host(`www.airesume.com`)"
      service: web
      entryPoints:
        - websecure
      tls: {}
      middlewares:
        - security-headers
        - cors-headers

    # API路由 (HTTPS)
    backend:
      rule: "Host(`api.airesume.com`) && PathPrefix(`/api`)"
      service: backend
      entryPoints:
        - websecure
      tls: {}
      middlewares:
        - backend-strip
        - cors-headers
        - security-headers

  middlewares:
    # CORS头部中间件
    cors-headers:
      headers:
        accessControlAllowMethods:
          - GET
          - POST
          - PUT
          - DELETE
          - OPTIONS
        accessControlAllowOrigins:
          - https://airesume.com
          - https://www.airesume.com
          - https://api.airesume.com
        accessControlMaxAge: 100
        addVaryHeader: true

    # 安全头中间件
    security-headers:
      headers:
        frameDeny: true
        browserXssFilter: true
        contentTypeNosniff: true
        forceSTSHeader: true
        stsIncludeSubdomains: true
        stsPreload: true
        stsSeconds: 31536000
```

---

## 🔧 实施步骤

### Step 1: 备份当前配置
```bash
# 备份配置文件
cp .env.production .env.production.backup
cp backend/app/core/config.py backend/app/core/config.py.backup
cp ai-resume-web/.env.production ai-resume-web/.env.production.backup
```

### Step 2: 更新环境变量
```bash
# 编辑生产环境配置
nano .env.production

# 更新以下变量:
# ALLOWED_ORIGINS=https://airesume.com,https://www.airesume.com,https://api.airesume.com
# VITE_API_BASE_URL=https://api.airesume.com/api
# VITE_APP_URL=https://airesume.com
```

### Step 3: 更新后端配置
```bash
# 编辑后端配置文件
nano backend/app/core/config.py

# 更新CORS_ORIGINS为生产域名
```

### Step 4: 更新前端配置
```bash
# 编辑前端环境变量
nano ai-resume-web/.env.production

# 更新API和APP URL为HTTPS域名
```

### Step 5: 更新Traefik配置
```bash
# 编辑动态配置
nano AI-/ai-resume-platform/traefik/dynamic.yml

# 添加生产域名路由和CORS中间件
```

### Step 6: 重建并重启服务
```bash
# 重建Docker容器
docker-compose -f docker-compose.prod.yml down
docker-compose -f docker-compose.prod.yml up -d --build

# 检查服务状态
docker ps
docker logs ai-resume-backend
docker logs ai-resume-frontend
```

### Step 7: 验证配置
```bash
# 测试CORS配置
curl -H "Origin: https://airesume.com" \
     -H "Access-Control-Request-Method: POST" \
     -H "Access-Control-Request-Headers: Content-Type" \
     -X OPTIONS \
     https://api.airesume.com/api/health

# 检查响应头
curl -I https://airesume.com
curl -I https://api.airesume.com/api/health

# 验证API调用
curl https://api.airesume.com/api/health
```

---

## 🔍 验证清单

### 基础验证
- [ ] 环境变量更新正确
- [ ] 后端CORS配置正确
- [ ] 前端配置正确
- [ ] Traefik路由配置正确
- [ ] 服务重启成功

### 功能验证
- [ ] 前端可访问主域名
- [ ] API可正常调用
- [ ] CORS预检请求通过
- [ ] 登录功能正常
- [ ] 文件上传功能正常

### 安全验证
- [ ] 只允许HTTPS域名
- [ ] 不允许localhost (生产环境)
- [ ] CORS头部正确设置
- [ ] 安全头完整配置
- [ ] 速率限制正常工作

### 兼容性验证
- [ ] Chrome浏览器正常
- [ ] Firefox浏览器正常
- [ ] Safari浏览器正常
- [ ] 移动浏览器正常
- [ ] API客户端可正常调用

---

## 🐛 故障排除

### 问题1: CORS错误
**症状**: 浏览器控制台显示CORS错误
**解决方案**:
```bash
# 检查CORS配置
docker logs ai-resume-backend | grep -i cors

# 验证环境变量
docker exec ai-resume-backend env | grep ALLOWED_ORIGINS

# 检查响应头
curl -I -H "Origin: https://airesume.com" https://api.airesume.com/api/health
```

### 问题2: 混合内容警告
**症状**: HTTPS页面包含HTTP资源
**解决方案**:
```javascript
// 确保所有资源使用HTTPS
const API_BASE = 'https://api.airesume.com/api';
const WS_URL = 'wss://api.airesume.com/ws';

// 检查图片、CSS、JS等静态资源
<link rel="stylesheet" href="https://cdn.example.com/style.css">
<script src="https://cdn.example.com/script.js"></script>
```

### 问题3: Cookie设置失败
**症状**: 认证Cookie无法设置
**解决方案**:
```python
# 确保SameSite属性正确
response.set_cookie(
    key="auth_token",
    value=token,
    httponly=True,
    secure=True,  # HTTPS必须
    samesite='lax',  # 或 'strict'
    domain='.airesume.com'  # 包含子域名
)
```

### 问题4: 预检请求失败
**症状**: OPTIONS请求返回404/405
**解决方案**:
```python
# 确保FastAPI正确处理OPTIONS请求
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.get_cors_origins(),
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "DELETE", "OPTIONS"],
    allow_headers=["Content-Type", "Authorization"],
    expose_headers=["Content-Length", "Content-Type"]
)
```

---

## 📊 测试方案

### 单元测试
```python
# tests/test_cors.py
import pytest
from fastapi.testclient import TestClient
from app.main import app

def test_cors_allowed_origins():
    client = TestClient(app)
    response = client.options(
        "/api/health",
        headers={
            "Origin": "https://airesume.com",
            "Access-Control-Request-Method": "GET"
        }
    )
    assert response.status_code == 200
    assert "access-control-allow-origin" in response.headers

def test_cors_disallowed_origins():
    client = TestClient(app)
    response = client.options(
        "/api/health",
        headers={
            "Origin": "https://evil.com",
            "Access-Control-Request-Method": "GET"
        }
    )
    assert "access-control-allow-origin" not in response.headers
```

### 集成测试
```bash
# 测试脚本
#!/bin/bash
# test_cors.sh

echo "Testing CORS configuration..."

# 测试允许的域名
curl -X OPTIONS https://api.airesume.com/api/health \
  -H "Origin: https://airesume.com" \
  -H "Access-Control-Request-Method: GET" \
  -v

# 测试不允许的域名
curl -X OPTIONS https://api.airesume.com/api/health \
  -H "Origin: https://evil.com" \
  -H "Access-Control-Request-Method: GET" \
  -v
```

---

## 📈 监控指标

### CORS监控
- 预检请求成功率
- CORS错误次数
- 允许的域名访问统计
- 被拒绝的域名访问统计

### 性能监控
- 预检请求响应时间
- CORS处理开销
- 浏览器兼容性问题

### 安全监控
- 异常Origin请求
- 可疑的CORS头部
- 跨域攻击尝试

---

## 🎯 预期效果

### 安全性提升
- ✅ 严格域名白名单
- ✅ 强制HTTPS
- ✅ 移除开发域名
- ✅ 限制HTTP方法

### 功能完善
- ✅ 生产域名支持
- ✅ 跨域子域名
- ✅ 安全Cookie设置
- ✅ 正确CORS头部

### 性能优化
- ✅ 减少预检请求
- ✅ 优化头部大小
- ✅ 浏览器缓存优化

---

## 📅 时间估算

| 步骤 | 预计时间 | 实际时间 | 状态 |
|------|----------|----------|------|
| 环境变量更新 | 30分钟 | - | 待开始 |
| 后端配置更新 | 1小时 | - | 待开始 |
| 前端配置更新 | 30分钟 | - | 待开始 |
| Docker配置更新 | 30分钟 | - | 待开始 |
| Traefik配置更新 | 1小时 | - | 待开始 |
| 验证测试 | 1小时 | - | 待开始 |
| **总计** | **4小时** | - | **待开始** |

---

## 📞 联系信息

**执行负责人**: DevOps Agent (29126157-6833-4f1e-94bd-6493bd95d3f2)
**技术审核**: Backend Team
**测试验证**: QA Team

---

**文档版本**: v1.0
**最后更新**: 2026-04-17 10:55
**下次评审**: 配置完成后
