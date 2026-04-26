# 步骤6: 触发部署并验证健康

## 部署前检查清单

### 1. 配置验证

- [ ] SSH密钥已添加到Dokploy
- [ ] 后端服务配置完成（ai-resume-backend）
- [ ] 前端服务配置完成（ai-resume-frontend）
- [ ] 环境变量已正确设置
- [ ] 域名配置完成（可选）

### 2. 依赖检查

```bash
# 检查服务器资源
ssh -i ~/.ssh/id_ed25519 root@113.45.64.145 << 'ENDSSH'
echo "=== 系统资源 ==="
free -h
df -h /
docker --version
docker-compose --version

echo "=== 端口占用 ==="
netstat -tlnp | grep -E ':(8001|8081|6379)'

echo "=== Docker网络 ==="
docker network ls | grep ai-resume
ENDSSH
```

### 3. 镜像准备

```bash
# 检查是否需要构建镜像
ssh -i ~/.ssh/id_ed25519 root@113.45.64.145 << 'ENDSSH'
cd /var/www/ai-resume
docker images | grep ai-resume
ENDSSH
```

## 触发部署

### 方法1: 通过Dokploy面板

1. 进入 **"AI智能体简历"** 项目
2. 点击 **"Deploy All Services"** 按钮
3. 确认部署操作
4. 观察部署日志

### 方法2: 通过SSH手动部署

```bash
ssh -i ~/.ssh/id_ed25519 root@113.45.64.145 << 'ENDSSH'
cd /var/www/ai-resume

# 停止现有容器
docker-compose down

# 拉取最新代码
git pull origin main

# 构建并启动
docker-compose up -d --build

# 查看日志
docker-compose logs -f --tail=50
ENDSSH
```

## 实时监控部署

### 监控脚本

创建 `monitor-deployment.sh`:

```bash
#!/bin/bash

echo "🚀 开始部署监控..."

# 部署
ssh -i ~/.ssh/id_ed25519 root@113.45.64.145 << 'ENDSSH'
cd /var/www/ai-resume

echo "📦 构建镜像..."
docker-compose build

echo "🔄 启动服务..."
docker-compose up -d

echo "⏳ 等待服务启动..."
sleep 10

echo "📊 服务状态:"
docker-compose ps

echo "📋 最近日志:"
docker-compose logs --tail=20
ENDSSH

echo "✅ 部署完成！"
```

### 部署时间估算

- 后端构建: 3-5分钟
- 前端构建: 2-3分钟
- 容器启动: 30秒-1分钟
- 健康检查: 1-2分钟

**总计**: 约7-11分钟

## 部署验证

### 阶段1: 容器状态验证

```bash
ssh -i ~/.ssh/id_ed25519 root@113.45.64.145 << 'ENDSSH'
echo "=== 容器状态 ==="
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep ai-resume

echo ""
echo "=== 网络连接 ==="
docker network inspect ai-resume-network --format '{{range .Containers}}{{.Name}} {{end}}'

echo ""
echo "=== 资源使用 ==="
docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}" | grep ai-resume
ENDSSH
```

### 阶段2: 健康检查验证

```bash
echo "=== 后端健康检查 ==="
curl -f http://113.45.64.145:8001/health
echo ""

echo "=== 前端访问检查 ==="
curl -I -s http://113.45.64.145:8081 | head -5
echo ""

echo "=== API代理检查 ==="
curl -f http://113.45.64.145:8081/api/health
echo ""

echo "=== Redis连接检查 ==="
ssh -i ~/.ssh/id_ed25519 root@113.45.64.145 "docker exec ai-resume-redis redis-cli ping"
```

### 阶段3: 功能验证

```bash
# 1. 测试API端点
echo "测试: 创建简历"
curl -X POST http://113.45.64.145:8001/api/resumes \
  -H "Content-Type: application/json" \
  -d '{"title": "Test Resume"}'

# 2. 测试AI生成
echo "测试: AI生成内容"
curl -X POST http://113.45.64.145:8001/api/ai/generate \
  -H "Content-Type: application/json" \
  -d '{"prompt": "Generate a resume summary"}'

# 3. 测试前端页面
echo "测试: 前端页面"
curl -s http://113.45.64.145:8081 | grep -o "<title>.*</title>"
```

## 部署后健康检查

### 完整健康检查脚本

```bash
#!/bin/bash

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

PASS=0
FAIL=0

check() {
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓${NC} $1"
        ((PASS++))
    else
        echo -e "${RED}✗${NC} $1"
        ((FAIL++))
    fi
}

echo "🔍 AI Resume Platform - 健康检查"
echo "=================================="

# 1. 容器状态
echo -e "\n📦 容器状态检查..."
ssh -i ~/.ssh/id_ed25519 root@113.45.64.145 "docker ps | grep ai-resume-backend" > /dev/null 2>&1
check "后端容器运行中"

ssh -i ~/.ssh/id_ed25519 root@113.45.64.145 "docker ps | grep ai-resume-frontend" > /dev/null 2>&1
check "前端容器运行中"

ssh -i ~/.ssh/id_ed25519 root@113.45.64.145 "docker ps | grep ai-resume-redis" > /dev/null 2>&1
check "Redis容器运行中"

# 2. 端口监听
echo -e "\n🌐 端口监听检查..."
curl -f -s http://113.45.64.145:8001/health > /dev/null 2>&1
check "后端端口8001可访问"

curl -f -s http://113.45.64.145:8081 > /dev/null 2>&1
check "前端端口8081可访问"

# 3. 健康端点
echo -e "\n💓 健康端点检查..."
curl -f -s http://113.45.64.145:8001/health | grep -q "healthy" > /dev/null 2>&1
check "后端健康检查通过"

curl -f -s http://113.45.64.145:8081/api/health | grep -q "healthy" > /dev/null 2>&1
check "API代理健康检查通过"

# 4. 数据库连接
echo -e "\n💾 数据库检查..."
ssh -i ~/.ssh/id_ed25519 root@113.45.64.145 "docker exec ai-resume-backend ls -la /app/ai_resume.db" > /dev/null 2>&1
check "数据库文件存在"

# 5. Redis连接
echo -e "\n🚀 Redis检查..."
ssh -i ~/.ssh/id_ed25519 root@113.45.64.145 "docker exec ai-resume-redis redis-cli ping" | grep -q "PONG" > /dev/null 2>&1
check "Redis连接正常"

# 6. AI服务
echo -e "\n🤖 AI服务检查..."
curl -f -s http://113.45.64.145:8001/api/ai/models | grep -q "deepseek" > /dev/null 2>&1
check "AI服务配置正确"

# 7. 资源使用
echo -e "\n📊 资源使用检查..."
MEMORY=$(ssh -i ~/.ssh/id_ed25519 root@113.45.64.145 "docker stats ai-resume-backend --no-stream --format '{{.MemUsage}}'" | awk '{print $1}')
if [ ! -z "$MEMORY" ]; then
    echo -e "${GREEN}✓${NC} 后端内存使用: $MEMORY"
    ((PASS++))
else
    echo -e "${RED}✗${NC} 无法获取内存使用"
    ((FAIL++))
fi

# 总结
echo -e "\n=================================="
echo -e "检查完成: ${GREEN}${PASS} 通过${NC}, ${RED}${FAIL} 失败${NC}"

if [ $FAIL -eq 0 ]; then
    echo -e "${GREEN}🎉 所有检查通过！部署成功！${NC}"
    exit 0
else
    echo -e "${RED}⚠️  部分检查失败，请查看日志${NC}"
    exit 1
fi
```

## 日志查看

### 查看实时日志

```bash
# 后端日志
ssh -i ~/.ssh/id_ed25519 root@113.45.64.145 "docker logs -f ai-resume-backend"

# 前端日志
ssh -i ~/.ssh/id_ed25519 root@113.45.64.145 "docker logs -f ai-resume-frontend"

# Redis日志
ssh -i ~/.ssh/id_ed25519 root@113.45.64.145 "docker logs -f ai-resume-redis"
```

### 查看最近日志

```bash
# 后端最近50行
ssh -i ~/.ssh/id_ed25519 root@113.45.64.145 "docker logs --tail=50 ai-resume-backend"

# 前端最近50行
ssh -i ~/.ssh/id_ed25519 root@113.45.64.145 "docker logs --tail=50 ai-resume-frontend"
```

## 故障排查

### 问题1: 容器无法启动

```bash
# 查看详细错误
ssh -i ~/.ssh/id_ed25519 root@113.45.64.145 << 'ENDSSH'
cd /var/www/ai-resume
docker-compose logs --tail=100
docker-compose ps -a
ENDSSH
```

**常见原因**:
- 端口被占用
- 环境变量错误
- 镜像构建失败
- 依赖服务未启动

### 问题2: 健康检查失败

```bash
# 进入容器检查
ssh -i ~/.ssh/id_ed25519 root@113.45.64.145 << 'ENDSSH'
docker exec -it ai-resume-backend bash
# 在容器内:
curl http://localhost:8000/health
python -c "import sqlite3; conn = sqlite3.connect('/app/ai_resume.db'); print(conn.execute('SELECT COUNT(*) FROM users').fetchone())"
exit
ENDSSH
```

### 问题3: 前端404

```bash
# 检查前端文件
ssh -i ~/.ssh/id_ed25519 root@113.45.64.145 << 'ENDSSH'
docker exec ai-resume-frontend ls -la /usr/share/nginx/html
docker exec ai-resume-frontend cat /etc/nginx/conf.d/default.conf
ENDSSH
```

### 问题4: API调用失败

```bash
# 检查网络连接
ssh -i ~/.ssh/id_ed25519 root@113.45.64.145 << 'ENDSSH'
docker network inspect ai-resume-network
docker exec ai-resume-frontend ping -c 2 ai-resume-backend
ENDSSH
```

## 回滚计划

如果部署失败，执行回滚:

```bash
ssh -i ~/.ssh/id_ed25519 root@113.45.64.145 << 'ENDSSH'
cd /var/www/ai-resume

# 回滚到上一个版本
git log --oneline -5
git reset --hard HEAD~1

# 重新部署
docker-compose up -d --force-recreate

# 验证
docker-compose ps
ENDSSH
```

## 性能验证

### 负载测试

```bash
# 使用ab (Apache Bench)
ab -n 100 -c 10 http://113.45.64.145:8001/health

# 使用wrk
wrk -t4 -c100 -d30s http://113.45.64.145:8001/health
```

### 响应时间测试

```bash
# 测试各端点响应时间
for endpoint in /health /api/ai/models /api/resumes; do
  echo "Testing: $endpoint"
  time curl -s http://113.45.64.145:8001$endpoint > /dev/null
done
```

## 完成标志

✅ 所有容器状态为 "Up"
✅ 健康检查全部通过
✅ HTTP端点正常响应
✅ 数据库连接正常
✅ Redis连接正常
✅ AI服务可用
✅ 前端页面可访问
✅ API代理工作正常
✅ 无错误日志
✅ 资源使用正常

## 部署成功总结

```bash
# 生成部署报告
cat > /tmp/deployment_report.md << 'EOF'
# AI Resume Platform - 部署报告

**部署时间**: $(date)
**部署人员**: DevOps Engineer
**环境**: Production (113.45.64.145)

## 部署服务

- ✅ ai-resume-backend (后端API)
- ✅ ai-resume-frontend (前端界面)
- ✅ ai-resume-redis (缓存服务)

## 访问地址

- 前端: http://113.45.64.145:8081
- 后端: http://113.45.64.145:8001
- 健康检查: http://113.45.64.145:8001/health

## 容器状态

$(ssh -i ~/.ssh/id_ed25519 root@113.45.64.145 "docker ps | grep ai-resume")

## 验证结果

- ✅ 所有服务正常运行
- ✅ 健康检查通过
- ✅ 功能验证成功

## 下一步

1. 配置域名SSL证书
2. 设置监控告警
3. 配置CI/CD自动部署
4. 设置备份策略

