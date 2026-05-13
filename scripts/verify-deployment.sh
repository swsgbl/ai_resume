#!/bin/bash
# 部署验证脚本
# 用于在 Docker 构建完成后验证所有服务是否正常启动

set -e

SERVER="root@113.45.64.145"
SSH_KEY="~/.ssh/id_ed25519"

echo "========================================="
echo "AI Resume Platform 部署验证"
echo "时间: $(date '+%Y-%m-%d %H:%M:%S')"
echo "========================================="
echo

# 1. 检查容器状态
echo "1. 检查容器状态..."
ssh -i $SSH_KEY $SERVER "docker ps | grep ai-resume" || {
    echo "❌ 容器未启动"
    exit 1
}
echo "✅ 容器已启动"
echo

# 2. 检查后端服务
echo "2. 检查后端服务 (http://113.45.64.145:8001/health)..."
HEALTH_CHECK=$(ssh -i $SSH_KEY $SERVER "curl -s -o /dev/null -w '%{http_code}' http://localhost:8001/health" || echo "000")
if [ "$HEALTH_CHECK" = "200" ]; then
    echo "✅ 后端服务正常 (HTTP $HEALTH_CHECK)"
else
    echo "❌ 后端服务异常 (HTTP $HEALTH_CHECK)"
    ssh -i $SSH_KEY $SERVER "docker logs ai-resume-backend --tail 50"
    exit 1
fi
echo

# 3. 检查前端服务
echo "3. 检查前端服务 (http://113.45.64.145:8081)..."
FRONTEND_CHECK=$(ssh -i $SSH_KEY $SERVER "curl -s -o /dev/null -w '%{http_code}' http://localhost:8081/" || echo "000")
if [ "$FRONTEND_CHECK" = "200" ]; then
    echo "✅ 前端服务正常 (HTTP $FRONTEND_CHECK)"
else
    echo "❌ 前端服务异常 (HTTP $FRONTEND_CHECK)"
    ssh -i $SSH_KEY $SERVER "docker logs ai-resume-frontend --tail 50"
    exit 1
fi
echo

# 4. 检查 Redis 服务
echo "4. 检查 Redis 服务..."
REDIS_CHECK=$(ssh -i $SSH_KEY $SERVER "docker exec ai-resume-redis redis-cli ping" || echo "FAILED")
if [ "$REDIS_CHECK" = "PONG" ]; then
    echo "✅ Redis 服务正常"
else
    echo "❌ Redis 服务异常"
    ssh -i $SSH_KEY $SERVER "docker logs ai-resume-redis --tail 50"
    exit 1
fi
echo

# 5. 测试 API 端点
echo "5. 测试主要 API 端点..."
API_TEST=$(ssh -i $SSH_KEY $SERVER "curl -s http://localhost:8001/api/v1/" || echo "ERROR")
if echo "$API_TEST" | grep -q "error\|Error\|ERROR"; then
    echo "⚠️  API 响应包含错误信息"
    echo "$API_TEST"
else
    echo "✅ API 端点正常"
fi
echo

echo "========================================="
echo "✅ 所有服务验证通过！"
echo "========================================="
echo
echo "服务访问地址:"
echo "  后端 API: http://113.45.64.145:8001"
echo "  前端:     http://113.45.64.145:8081"
echo "  域名:     https://happy.ndtool.cn"
echo
