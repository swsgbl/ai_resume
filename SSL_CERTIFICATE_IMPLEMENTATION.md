# SSL证书配置实施方案
**创建时间**: 2026-04-17 10:50
**DevOps Agent**: 29126157-6833-4f1e-94bd-6493bd95d3f2
**优先级**: P1 (高优先级)

---

## 📋 当前状态评估

### ✅ 已有基础设施
- **Traefik反向代理**: 已运行，版本v2.x
- **HTTP服务**: 正常运行在端口80
- **HTTPS入口点**: websecure (:443) 已配置
- **动态配置**: 已启用热重载
- **服务器IP**: 113.45.64.145

### ⚠️ 当前问题
- **SSL证书**: 未配置
- **HTTPS路由**: 未启用
- **域名配置**: 使用localhost，需更新为生产域名
- **Let's Encrypt**: 未集成
- **安全头**: 部分配置，需完善

---

## 🎯 实施方案

### 阶段1: 准备工作 (1-2天)

#### 1.1 域名准备
- [ ] **选择并注册域名**
  - 推荐: airesume.com, airesu.me, smartresume.ai
  - 备选: resumeai.com, cvsmart.io
  
- [ ] **DNS配置**
  ```yaml
  A记录: airesume.com → 113.45.64.145
  A记录: www.airesume.com → 113.45.64.145
  A记录: api.airesume.com → 113.45.64.145
  ```

- [ ] **DNS验证**
  ```bash
  # 检查DNS解析
  dig airesume.com
  nslookup airesume.com
  ```

#### 1.2 防火墙配置
- [ ] **开放必要端口**
  ```bash
  # HTTP
  sudo ufw allow 80/tcp
  
  # HTTPS  
  sudo ufw allow 443/tcp
  
  # 验证规则
  sudo ufw status numbered
  ```

---

### 阶段2: SSL证书配置 (2-3天)

#### 2.1 Let's Encrypt自动证书 (推荐)

**优点**: 免费、自动续期、受信任
**缺点**: 需要域名、需要80端口可用

##### 配置步骤:

1. **更新Traefik静态配置**
```yaml
# traefik.yml
api:
  dashboard: true
  insecure: false  # 生产环境禁用不安全访问

entryPoints:
  web:
    address: ":80"
    http:
      redirections:
        entryPoint:
          to: websecure
          scheme: https
          permanent: true

  websecure:
    address: ":443"
    http:
      tls:
        certResolver: letsencrypt
        domains:
          - main: airesume.com
            sans:
              - www.airesume.com
              - api.airesume.com

certificatesResolvers:
  letsencrypt:
    acme:
      email: admin@airesume.com  # 替换为实际邮箱
      storage: /letsencrypt/acme.json
      httpChallenge:
        entryPoint: web
      # 使用生产环境服务器
      caServer: "https://acme-v02.api.letsencrypt.org/directory"

providers:
  docker:
    endpoint: "unix:///var/run/docker.sock"
    exposedByDefault: false
  file:
    filename: /etc/traefik/config/dynamic.yml
    watch: true

log:
  level: INFO

accessLog:
  filePath: "/var/log/traefik/access.log"
```

2. **创建证书存储卷**
```bash
docker volume create traefik-letsencrypt
```

3. **更新docker-compose配置**
```yaml
services:
  traefik:
    image: traefik:v2.10
    container_name: traefik
    restart: unless-stopped
    ports:
      - "80:80"
      - "443:443"
      - "8080:8080"  # Dashboard
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - ./AI-/ai-resume-platform/traefik/traefik.yml:/etc/traefik/traefik.yml:ro
      - ./AI-/ai-resume-platform/traefik/dynamic.yml:/etc/traefik/config/dynamic.yml:ro
      - traefik-letsencrypt:/letsencrypt
    networks:
      - ai-resume-network
```

4. **更新动态配置路由**
```yaml
# dynamic.yml
http:
  routers:
    # 主后端路由 (HTTPS)
    backend:
      rule: "Host(`api.airesume.com`) && PathPrefix(`/api`)"
      service: backend
      entryPoints:
        - websecure
      middlewares:
        - backend-strip
      tls: {}  # 启用TLS
      certResolver: letsencrypt

    # Web前端路由 (HTTPS)
    web:
      rule: "Host(`airesume.com`) || Host(`www.airesume.com`)"
      service: web
      entryPoints:
        - websecure
      tls: {}  # 启用TLS
      certResolver: letsencrypt
      
    # 健康检查路由
    health:
      rule: "Path(`/health`) || Path(`/api/v1/health`)"
      service: backend-health
      entryPoints:
        - websecure
      tls: {}  # 启用TLS
```

#### 2.2 自签名证书 (开发/测试环境)

**适用场景**: 开发测试、内网环境
**有效期**: 1年可自定义
**信任问题**: 浏览器会显示安全警告

##### 生成自签名证书:
```bash
# 创建证书目录
mkdir -p ./certs

# 生成私钥和证书
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout ./certs/tls.key \
  -out ./certs/tls.crt \
  -subj "/C=CN/ST=Beijing/L=Beijing/O=AIResume/CN=*.airesume.com"

# 设置权限
chmod 600 ./certs/tls.key
chmod 644 ./certs/tls.crt
```

##### Traefik配置:
```yaml
# traefik.yml (使用自签名证书)
entryPoints:
  websecure:
    address: ":443"
    http:
      tls:
        certificates:
          - certFile: /certs/tls.crt
            keyFile: /certs/tls.key
```

---

### 阶段3: 应用配置更新 (1天)

#### 3.1 环境变量更新
```bash
# .env.production
ALLOWED_ORIGINS=https://airesume.com,https://www.airesume.com,https://api.airesume.com
VITE_API_BASE_URL=https://api.airesume.com/api
VITE_APP_URL=https://airesume.com
```

#### 3.2 CORS配置更新
```python
# backend/config/security.py
ALLOWED_ORIGINS = [
    "https://airesume.com",
    "https://www.airesume.com", 
    "https://api.airesume.com"
]
```

#### 3.3 数据库连接更新
```python
# 如果使用HTTPS，确保数据库连接安全
DATABASE_URL = "postgresql+aiomysql://user:password@db:3306/ai_resume?sslmode=require"
```

---

### 阶段4: 安全加固 (1天)

#### 4.1 HSTS配置
```yaml
# dynamic.yml - 安全头中间件
http:
  middlewares:
    security-headers:
      headers:
        frameDeny: true
        browserXssFilter: true
        contentTypeNosniff: true
        forceSTSHeader: true
        stsIncludeSubdomains: true
        stsPreload: true
        stsSeconds: 31536000  # 1年
        customFrameOptionsValue: "SAMEORIGIN"
        referrerPolicy: "strict-origin-when-cross-origin"
        permissionsPolicy: "camera=(), microphone=(), geolocation=()"
```

#### 4.2 速率限制
```yaml
http:
  middlewares:
    ratelimit:
      rateLimit:
        average: 100
        burst: 50
        period: "1m"
```

#### 4.3 安全监控
- [ ] 配置失败请求监控
- [ ] 设置SSL证书过期提醒
- [ ] 启用访问日志分析

---

## 🔧 实施步骤

### Step 1: 域名准备 (预计1天)
```bash
# 1. 注册域名
# 2. 配置DNS
# 3. 等待DNS生效 (最多48小时)
dig airesume.com
```

### Step 2: 防火墙配置 (预计30分钟)
```bash
# 开放HTTPS端口
sudo ufw allow 443/tcp
sudo ufw reload
```

### Step 3: Traefik配置更新 (预计2小时)
```bash
# 1. 备份当前配置
cp AI-/ai-resume-platform/traefik/traefik.yml AI-/ai-resume-platform/traefik/traefik.yml.backup

# 2. 更新配置文件
# 3. 重启Traefik
docker-compose restart traefik

# 4. 检查日志
docker logs traefik -f
```

### Step 4: 证书申请 (预计1小时)
```bash
# Let's Encrypt会自动申请证书
# 检查证书状态
docker exec traefik ls -la /letsencrypt/acme.json
```

### Step 5: 路由配置更新 (预计1小时)
```bash
# 1. 更新动态配置
# 2. Traefik会自动热重载
# 3. 验证路由
curl -I https://airesume.com
```

### Step 6: 应用配置更新 (预计1小时)
```bash
# 1. 更新.env.production
# 2. 重启应用服务
docker-compose restart backend frontend
```

### Step 7: 测试验证 (预计2小时)
```bash
# HTTPS测试
curl -I https://airesume.com
curl -I https://api.airesume.com/api/health

# SSL证书检查
openssl s_client -connect airesume.com:443 -servername airesume.com

# 安全头检查
curl -I https://airesume.com | grep -E "(Strict-Transport-Security|X-Frame-Options)"
```

---

## 📊 验证清单

### 基础验证
- [ ] 域名DNS解析正确
- [ ] HTTP自动重定向到HTTPS
- [ ] SSL证书有效且受信任
- [ ] 所有服务可通过HTTPS访问
- [ ] API调用正常

### 安全验证
- [ ] HSTS头部正确配置
- [ ] 安全头完整设置
- [ ] CORS配置正确
- [ ] 速率限制生效
- [ ] 证书自动续期配置

### 性能验证
- [ ] HTTPS性能可接受
- [ ] 负载均衡正常
- [ ] 健康检查正常
- [ ] 日志记录正常

---

## 🐛 故障排除

### 问题1: 证书申请失败
**症状**: Traefik日志显示ACME错误
**解决方案**:
```bash
# 检查DNS解析
dig airesume.com

# 检查80端口是否可用
netstat -tlnp | grep :80

# 检查Let's Encrypt限制
https://letsencrypt.org/docs/rate-limits/
```

### 问题2: HTTPS重定向循环
**症状**: 浏览器显示重定向次数过多
**解决方案**:
```yaml
# 确保HTTP只重定向到HTTPS一次
entryPoints:
  web:
    address: ":80"
    http:
      redirections:
        entryPoint:
          to: websecure
          scheme: https
          permanent: true
          priority: 1
```

### 问题3: 混合内容警告
**症状**: 浏览器显示混合内容错误
**解决方案**:
```javascript
// 确保前端所有资源使用HTTPS
const API_BASE_URL = 'https://api.airesume.com';
const APP_URL = 'https://airesume.com';
```

---

## 📈 监控指标

### SSL证书监控
- 证书过期时间
- 自动续期状态
- 证书链完整性

### HTTPS性能监控
- 响应时间对比 (HTTP vs HTTPS)
- SSL握手时间
- 加密算法性能

### 安全监控
- HTTPS请求占比
- 无效SSL请求次数
- 安全头验证状态

---

## 🎯 预期效果

### 安全性提升
- ✅ 数据传输加密
- ✅ 防止中间人攻击
- ✅ 用户信任度提升
- ✅ SEO排名优化

### 功能完善
- ✅ 现代浏览器特性可用
- ✅ Service Worker支持
- ✅ PWA功能可用
- ✅ 支付接口可用

---

## 📅 时间估算

| 阶段 | 预计时间 | 缓冲时间 | 总计 |
|------|----------|----------|------|
| 域名准备 | 1-2天 | 2天 | 3-4天 |
| SSL配置 | 2-3天 | 1天 | 3-4天 |
| 应用更新 | 1天 | 0.5天 | 1.5天 |
| 测试验证 | 1天 | 0.5天 | 1.5天 |
| **总计** | **5-7天** | **4天** | **9-11天** |

---

## 📞 联系信息

**DevOps负责人**: DevOps Agent (29126157-6833-4f1e-94bd-6493bd95d3f2)
**技术支持**: CTO Team
**紧急联系**: 系统管理员

---

**文档版本**: v1.0
**最后更新**: 2026-04-17 10:50
**下次评审**: 实施完成后
