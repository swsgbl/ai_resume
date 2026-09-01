# 部署验证和测试指南

> **AI Resume Platform - 生产环境部署验证清单**
> 版本: 1.0.0
> 更新时间: 2026-04-02

---

## 📋 部署前检查

### 基础设施验证

#### 服务器资源
```bash
# 检查 CPU
nproc
# 建议: 2+ 核心

# 检查内存
free -h
# 建议: 4GB+ 可用内存

# 检查磁盘空间
df -h /
# 建议: 20GB+ 可用空间

# 检查网络
ping -c 3 8.8.8.8
```

#### Docker 环境
```bash
# 检查 Docker 版本
docker --version
# 要求: 20.10+

# 检查 Docker Compose
docker compose version
# 要求: 2.0+

# 测试 Docker 运行
docker run --rm hello-world
```

### 配置文件验证

#### 环境变量
```bash
# 检查必需的环境变量
grep -E "^(DEBUG|SECRET_KEY|JWT_SECRET|DATABASE_URL|REDIS_URL)" .env.production

# 验证密钥强度
python3 << 'EOF'
import re
from pathlib import Path

env = Path('.env.production').read_text()
secret_key = re.search(r'SECRET_KEY=(.+)', env).group(1)

if len(secret_key) < 32:
    print("❌ SECRET_KEY 太短")
elif not re.search(r'[A-Z]', secret_key):
    print("❌ SECRET_KEY 缺少大写字母")
elif not re.search(r'[a-z]', secret_key):
    print("❌ SECRET_KEY 缺少小写字母")
elif not re.search(r'[0-9]', secret_key):
    print("❌ SECRET_KEY 缺少数字")
else:
    print("✅ SECRET_KEY 强度足够")
EOF
```

#### Docker Compose 配置
```bash
# 验证配置文件语法
docker-compose -f docker-compose.prod.yml config

# 检查端口冲突
netstat -tulpn | grep -E ":(8000|3000|6379|3306)"

# 验证镜像构建
docker-compose -f docker-compose.prod.yml build --no-cache
```

---

## 🔍 功能测试清单

### 后端 API 测试

#### 健康检查
```bash
# 基础健康检查
curl -f http://localhost:8000/health
# 预期: {"status":"healthy","app":"AI简历智能生成平台","version":"1.0.0"}

# 健康状态验证
curl -s http://localhost:8000/health | jq -r '.status'
# 预期: healthy
```

#### API 端点测试
```bash
# 获取 API 版本
curl http://localhost:8000/api/v1/

# 测试 CORS 配置
curl -H "Origin: http://localhost:3000" \
     -H "Access-Control-Request-Method: POST" \
     -X OPTIONS http://localhost:8000/api/v1/

# 检查响应头
curl -I http://localhost:8000/api/v1/ | grep -E "(Content-Type|Access-Control)"
```

#### 认证测试
```bash
# 用户注册
curl -X POST http://localhost:8000/api/v1/auth/register \
     -H "Content-Type: application/json" \
     -d '{"email":"test@example.com","password":"SecurePass123"}'

# 用户登录
curl -X POST http://localhost:8000/api/v1/auth/login \
     -H "Content-Type: application/json" \
     -d '{"email":"test@example.com","password":"SecurePass123"}'

# Token 验证
TOKEN=$(curl -s -X POST http://localhost:8000/api/v1/auth/login \
     -H "Content-Type: application/json" \
     -d '{"email":"test@example.com","password":"SecurePass123"}' \
     | jq -r '.access_token')

curl -H "Authorization: Bearer $TOKEN" \
     http://localhost:8000/api/v1/users/me
```

### 前端测试

#### 页面访问测试
```bash
# 首页访问
curl -f http://localhost:3000/

# 检查静态资源
curl -I http://localhost:3000/assets/index.js

# 检查 API 代理
curl -I http://localhost:3000/api/health
```

#### 浏览器测试
```bash
# 使用 curl 模拟浏览器
curl -A "Mozilla/5.0" http://localhost:3000/

# 检查页面加载
curl -s http://localhost:3000/ | grep -o "<title>.*</title>"
```

### 数据库测试

#### 数据库连接
```bash
# SQLite 连接测试
docker exec ai-resume-backend python -c "
import sqlite3
conn = sqlite3.connect('/app/data/ai_resume.db')
cursor = conn.cursor()
cursor.execute('SELECT sqlite_version()')
print('SQLite 版本:', cursor.fetchone()[0])
conn.close()
"

# 数据表检查
docker exec ai-resume-backend python -c "
import sqlite3
conn = sqlite3.connect('/app/data/ai_resume.db')
cursor = conn.cursor()
cursor.execute(\"SELECT name FROM sqlite_master WHERE type='table'\")
tables = cursor.fetchall()
print('数据表:', [t[0] for t in tables])
conn.close()
"
```

### Redis 测试

#### 连接测试
```bash
# Redis ping 测试
docker exec ai-resume-redis redis-cli ping
# 预期: PONG

# 读写测试
docker exec ai-resume-redis redis-cli SET test_key "test_value"
docker exec ai-resume-redis redis-cli GET test_key
# 预期: test_value

# 连接信息
docker exec ai-resume-redis redis-cli INFO server | grep redis_version
```

---

## 📊 性能测试

### 负载测试

#### API 响应时间
```bash
# 安装 wrk
sudo apt-get install wrk

# 测试健康检查端点
wrk -t4 -c100 -d30s http://localhost:8000/health

# 预期结果:
# - 延迟 < 100ms (P50)
# - 延迟 < 500ms (P95)
# - 无错误响应
```

#### 并发测试
```bash
# 使用 Apache Bench
ab -n 1000 -c 10 http://localhost:8000/health

# 预期结果:
# - Requests per second > 100
# - Failed requests = 0
# - Time per request < 100ms (mean)
```

### 资源监控

#### 容器资源使用
```bash
# 实时监控
docker stats

# 检查资源限制
docker inspect ai-resume-backend | jq '.[0].HostConfig.Memory'
docker inspect ai-resume-backend | jq '.[0].HostConfig.NanoCpus'
```

#### 内存泄漏检查
```bash
# 监控内存使用趋势
for i in {1..10}; do
    docker stats ai-resume-backend --no-stream --format "table {{.MemUsage}}"
    sleep 60
done
```

---

## 🔐 安全测试

### SSL/TLS 测试

#### SSL 配置检查
```bash
# 如果配置了 HTTPS
openssl s_client -connect localhost:443 -servername localhost

# 检查证书过期时间
echo | openssl s_client -connect localhost:443 2>/dev/null | \
    openssl x509 -noout -dates
```

### 访问控制测试

#### CORS 验证
```bash
# 测试允许的源
curl -H "Origin: http://localhost:3000" \
     -H "Access-Control-Request-Method: POST" \
     -X OPTIONS http://localhost:8000/api/v1/ \
     -v

# 测试未授权的源
curl -H "Origin: http://evil.com" \
     -H "Access-Control-Request-Method: POST" \
     -X OPTIONS http://localhost:8000/api/v1/ \
     -v
```

#### 认证测试
```bash
# 无 Token 访问受保护端点
curl http://localhost:8000/api/v1/users/me
# 预期: 401 Unauthorized

# 无效 Token 访问
curl -H "Authorization: Bearer invalid_token" \
     http://localhost:8000/api/v1/users/me
# 预期: 401 Unauthorized
```

### 注入攻击测试

#### SQL 注入测试
```bash
# 测试登录端点
curl -X POST http://localhost:8000/api/v1/auth/login \
     -H "Content-Type: application/json" \
     -d '{"email":"admin@---\" OR \"1\"=\"1","password":"pass"}'
# 预期: 400 Bad Request 或验证失败
```

---

## 📈 监控验证

### Prometheus 验证

#### 指标检查
```bash
# 检查 Prometheus 状态
curl http://localhost:9090/-/healthy

# 查询 API 指标
curl 'http://localhost:9090/api/v1/query?query=up' | jq .

# 检查目标服务
curl 'http://localhost:9090/api/v1/targets' | jq '.data.activeTargets[] | {job: .labels.job, health: .health}'
```

#### 告警规则检查
```bash
# 查询告警规则
curl 'http://localhost:9090/api/v1/rules' | jq '.data.groups[].rules[] | {name: .name, state: .state}'

# 检查活跃告警
curl 'http://localhost:9090/api/v1/alerts' | jq '.data.alerts[] | {alert: .labels.alertname, state: .state}'
```

### Grafana 验证

#### 仪表板检查
```bash
# 访问 Grafana
curl -I http://localhost:3001/

# 检查数据源
curl 'http://localhost:3001/api/datasources' \
     -u admin:admin | jq '.[] | {name: .name, type: .type}'

# 检查仪表板列表
curl 'http://localhost:3001/api/search' \
     -u admin:admin | jq '.[] | {title: .title, uri: .uri}'
```

---

## 🔄 集成测试

### 端到端测试流程

#### 用户注册到简历生成
```bash
# 1. 用户注册
REGISTER_RESPONSE=$(curl -s -X POST http://localhost:8000/api/v1/auth/register \
     -H "Content-Type: application/json" \
     -d '{"email":"e2e@test.com","password":"SecurePass123"}')

echo "注册响应: $REGISTER_RESPONSE"

# 2. 用户登录
TOKEN=$(curl -s -X POST http://localhost:8000/api/v1/auth/login \
     -H "Content-Type: application/json" \
     -d '{"email":"e2e@test.com","password":"SecurePass123"}' \
     | jq -r '.access_token')

echo "Token: $TOKEN"

# 3. 获取用户信息
USER_INFO=$(curl -s -H "Authorization: Bearer $TOKEN" \
     http://localhost:8000/api/v1/users/me)

echo "用户信息: $USER_INFO"

# 4. 创建简历 (如果有相关 API)
# RESUME=$(curl -s -X POST http://localhost:8000/api/v1/resumes \
#      -H "Authorization: Bearer $TOKEN" \
#      -H "Content-Type: application/json" \
#      -d '{"title":"测试简历"}')
#
# echo "简历创建: $RESUME"

echo "✅ 端到端测试完成"
```

### 故障恢复测试

#### 服务重启测试
```bash
# 保存当前状态
BEFORE_HASH=$(docker exec ai-resume-backend md5sum /app/data/ai_resume.db)

# 重启服务
docker-compose -f docker-compose.prod.yml restart backend

# 等待服务恢复
sleep 10

# 验证服务恢复
curl -f http://localhost:8000/health

# 验证数据完整性
AFTER_HASH=$(docker exec ai-resume-backend md5sum /app/data/ai_resume.db)

if [ "$BEFORE_HASH" = "$AFTER_HASH" ]; then
    echo "✅ 数据完整性检查通过"
else
    echo "❌ 数据完整性检查失败"
fi
```

---

## ✅ 部署验证清单

### 基础检查
- [ ] 所有容器状态健康
- [ ] 端口访问正常
- [ ] 磁盘空间充足 (>10GB)
- [ ] 内存使用正常 (<80%)

### 功能检查
- [ ] 后端 API 健康检查通过
- [ ] 前端页面加载正常
- [ ] 用户认证功能正常
- [ ] 数据库连接正常
- [ ] Redis 缓存正常

### 性能检查
- [ ] API 响应时间 < 500ms (P95)
- [ ] 并发请求处理正常
- [ ] 无内存泄漏
- [ ] CPU 使用率正常 (<80%)

### 安全检查
- [ ] HTTPS 配置正确
- [ ] CORS 配置正确
- [ ] 认证授权正常
- [ ] 敏感信息保护

### 监控检查
- [ ] Prometheus 指标收集正常
- [ ] Grafana 仪表板显示正常
- [ ] 告警规则生效
- [ ] 日志收集正常

### 备份检查
- [ ] 自动备份配置正确
- [ ] 备份测试成功
- [ ] 恢复流程验证

---

## 🚨 问题处理

### 常见部署问题

#### 问题 1: 容器无法启动
```bash
# 检查日志
docker logs ai-resume-backend

# 常见原因:
# - 端口冲突
# - 配置文件错误
# - 资源限制

# 解决方案:
docker-compose -f docker-compose.prod.yml down
docker-compose -f docker-compose.prod.yml up -d
```

#### 问题 2: API 连接失败
```bash
# 检查网络
docker network inspect ai-resume-network

# 检查容器间连接
docker exec ai-resume-backend ping ai-resume-redis

# 检查防火墙
sudo iptables -L -n | grep 8000
```

#### 问题 3: 数据库错误
```bash
# 检查数据库文件权限
docker exec ai-resume-backend ls -la /app/data/

# 修复权限
docker exec ai-resume-backend chown -R app:app /app/data/

# 检查数据库完整性
docker exec ai-resume-backend python -c "
import sqlite3
conn = sqlite3.connect('/app/data/ai_resume.db')
conn.execute('PRAGMA integrity_check')
print(conn.fetchone()[0])
conn.close()
"
```

---

## 📞 支持联系

### 部署问题支持
- **技术文档**: 参考 `OPERATIONS_MANUAL.md`
- **部署指南**: 参考 `DOKPLOY_DEPLOYMENT_GUIDE.md`
- **DevOps 工程师**: Agent 29126157-6833-4f1e-94bd-6493bd95d3f2

### 紧急联系
- **系统紧急故障**: 参考运维手册中的应急响应流程
- **安全事件**: 立即通知安全团队

---

**文档版本**: 1.0.0
**最后更新**: 2026-04-02
**维护者**: DevOps 工程师
