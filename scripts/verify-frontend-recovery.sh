#!/bin/bash
# 前端服务恢复验证脚本
# 用法: ./scripts/verify-frontend-recovery.sh

set -e

echo "======================================"
echo "前端服务恢复验证脚本"
echo "执行时间: $(date '+%Y-%m-%d %H:%M:%S')"
echo "======================================"
echo ""

# 颜色定义
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 计数器
PASS=0
FAIL=0
SKIP=0

# 测试函数
test_service() {
    local name=$1
    local url=$2
    local expected_code=${3:-200}

    echo -n "测试 $name... "

    # 使用curl进行测试，超时10秒
    response=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "$url" 2>/dev/null || echo "000")

    if [ "$response" = "$expected_code" ]; then
        echo -e "${GREEN}✓ PASS${NC} (HTTP $response)"
        ((PASS++))
        return 0
    else
        echo -e "${RED}✗ FAIL${NC} (HTTP $response, expected $expected_code)"
        ((FAIL++))
        return 1
    fi
}

test_detailed() {
    local name=$1
    local url=$2

    echo ""
    echo "--- 详细测试: $name ---"

    # 获取完整响应信息
    echo "URL: $url"

    # 测试HTTP状态
    http_code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "$url" 2>/dev/null || echo "000")
    echo "HTTP状态: $http_code"

    # 测试响应时间
    response_time=$(curl -s -o /dev/null -w "%{time_total}" --max-time 10 "$url" 2>/dev/null || echo "10.000")
    echo "响应时间: ${response_time}s"

    # 测试内容长度
    content_length=$(curl -s -o /dev/null -w "%{size_download}" --max-time 10 "$url" 2>/dev/null || echo "0")
    echo "内容大小: $content_length bytes"

    # 如果HTTP状态正常，标记为通过
    if [ "$http_code" = "200" ] || [ "$http_code" = "301" ] || [ "$http_code" = "302" ]; then
        echo -e "${GREEN}✓ 服务正常${NC}"
        ((PASS++))
    else
        echo -e "${RED}✗ 服务异常${NC}"
        ((FAIL++))
    fi
    echo ""
}

# 1. 基础网络连通性测试
echo "=== 1. 网络连通性测试 ==="
ping -c 2 ndtool.cn > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ 域名解析正常${NC}"
    ((PASS++))
else
    echo -e "${RED}✗ 域名解析失败${NC}"
    ((FAIL++))
fi

ping -c 2 113.45.64.145 > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ 服务器IP连通${NC}"
    ((PASS++))
else
    echo -e "${RED}✗ 服务器IP不通${NC}"
    ((FAIL++))
fi
echo ""

# 2. 前端服务测试
echo "=== 2. 前端服务测试 ==="
test_service "前端首页 (域名)" "https://ndtool.cn"
test_service "前端首页 (IP直连)" "http://113.45.64.145:8081"
test_detailed "前端详细检测" "https://ndtool.cn"
echo ""

# 3. SEO和元数据测试
echo "=== 3. SEO和元数据测试 ==="
echo -n "测试 robots.txt... "
robots=$(curl -s --max-time 10 "https://ndtool.cn/robots.txt" 2>/dev/null | head -1)
if [ -n "$robots" ]; then
    echo -e "${GREEN}✓ PASS${NC}"
    echo "  内容: $robots"
    ((PASS++))
else
    echo -e "${RED}✗ FAIL${NC}"
    ((FAIL++))
fi

echo -n "测试 sitemap.xml... "
sitemap=$(curl -s --max-time 10 "https://ndtool.cn/sitemap.xml" 2>/dev/null | head -1)
if [[ "$sitemap" == *"<?xml"* ]]; then
    echo -e "${GREEN}✓ PASS${NC}"
    echo "  内容: $sitemap"
    ((PASS++))
else
    echo -e "${RED}✗ FAIL${NC}"
    ((FAIL++))
fi
echo ""

# 4. 关键页面测试
echo "=== 4. 关键页面测试 ==="
test_service "关于页面" "https://ndtool.cn/about"
test_service "帮助页面" "https://ndtool.cn/help"
test_service "隐私政策" "https://ndtool.cn/privacy"
test_service "用户协议" "https://ndtool.cn/terms"
echo ""

# 5. 静态资源测试
echo "=== 5. 静态资源测试 ==="
echo -n "测试 favicon... "
favicon=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "https://ndtool.cn/vite.svg" 2>/dev/null || echo "000")
if [ "$favicon" = "200" ]; then
    echo -e "${GREEN}✓ PASS${NC}"
    ((PASS++))
else
    echo -e "${YELLOW}⚠ SKIP${NC} (HTTP $favicon)"
    ((SKIP++))
fi

echo -n "测试主要JS bundle... "
js_bundle=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "https://ndtool.cn/assets/index-CEmu4L7a.js" 2>/dev/null || echo "000")
if [ "$js_bundle" = "200" ]; then
    echo -e "${GREEN}✓ PASS${NC}"
    ((PASS++))
else
    echo -e "${YELLOW}⚠ SKIP${NC} (HTTP $js_bundle, 可能是版本不同)"
    ((SKIP++))
fi
echo ""

# 6. 性能测试
echo "=== 6. 性能测试 ==="
echo "测试首页加载性能..."
time_result=$(curl -s -o /dev/null -w "DNS解析: %{time_namelookup}s\n连接时间: %{time_connect}s\n首字节时间: %{time_starttransfer}s\n总时间: %{time_total}s\n" --max-time 10 "https://ndtool.cn" 2>/dev/null || echo "所有测试: 超时")
echo "$time_result"
echo ""

# 7. 安全头检查
echo "=== 7. 安全头检查 ==="
echo "检查安全相关的HTTP头..."
security_headers=$(curl -s -I --max-time 10 "https://ndtool.cn" 2>/dev/null | grep -i "x-frame-options\|x-content-type-options\|strict-transport-security" || echo "未找到安全头")
if [ -n "$security_headers" ]; then
    echo -e "${GREEN}发现安全头:${NC}"
    echo "$security_headers"
    ((PASS++))
else
    echo -e "${YELLOW}⚠ 未发现安全头${NC}"
    ((SKIP++))
fi
echo ""

# 8. 控制台错误检查（如果有浏览器访问）
echo "=== 8. 建议的浏览器测试 ==="
echo "建议手动验证以下项目："
echo "  1. 在浏览器中打开 https://ndtool.cn"
echo "  2. 打开开发者工具 (F12)"
echo "  3. 检查 Console 是否有JavaScript错误"
echo "  4. 检查 Network 面板是否有请求失败"
echo "  5. 验证页面显示正常"
echo "  6. 测试移动端响应式布局"
echo ""

# 最终结果汇总
echo "======================================"
echo "测试结果汇总"
echo "======================================"
echo -e "${GREEN}通过: $PASS${NC}"
echo -e "${RED}失败: $FAIL${NC}"
echo -e "${YELLOW}跳过: $SKIP${NC}"
echo ""

if [ $FAIL -eq 0 ]; then
    echo -e "${GREEN}✓ 所有核心测试通过！前端服务已恢复。${NC}"
    echo ""
    echo "建议的后续行动："
    echo "  1. 通知营销团队可以开始发布活动"
    echo "  2. 启动用户监控和性能追踪"
    echo "  3. 验证所有功能正常工作"
    exit 0
else
    echo -e "${RED}✗ 发现 $FAIL 个测试失败。前端服务可能未完全恢复。${NC}"
    echo ""
    echo "建议的后续行动："
    echo "  1. 检查服务器状态和服务日志"
    echo "  2. 验证Nginx配置和重启服务"
    echo "  3. 查看防火墙和网络配置"
    exit 1
fi
