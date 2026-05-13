#!/bin/bash
# 应用层快速恢复脚本 - 网络层恢复后使用
# 创建时间: 2026-05-14 01:32
# 用途: 快速恢复SSH和应用服务

set -e

echo "=========================================="
echo "  应用层快速恢复脚本"
echo "  时间: $(date '+%Y-%m-%d %H:%M:%S')"
echo "=========================================="
echo

# 检查是否为root用户
if [ "$EUID" -ne 0 ]; then
    echo "错误: 请使用root用户执行此脚本"
    echo "使用: sudo bash $0"
    exit 1
fi

echo "步骤1: 检查系统状态"
echo "-----------------------------------"
uptime
free -h | head -2
df -h | head -2
echo

echo "步骤2: 重启SSH服务"
echo "-----------------------------------"
systemctl restart sshd
systemctl enable sshd
systemctl status sshd --no-pager | head -5
echo

echo "步骤3: 启动后端服务"
echo "-----------------------------------"
if systemctl list-unit-files | grep -q ai-resume-backend.service; then
    systemctl start ai-resume-backend.service
    systemctl enable ai-resume-backend.service
    systemctl status ai-resume-backend.service --no-pager | head -5
else
    echo "警告: ai-resume-backend.service未找到"
    echo "尝试手动启动..."
    cd /var/www/ai-resume/backend 2>/dev/null || cd /root/ai-resume/backend 2>/dev/null || true
    # nohup python3 -m uvicorn main:app --host 0.0.0.0 --port 8000 > /tmp/backend.log 2>&1 &
fi
echo

echo "步骤4: 启动前端服务"
echo "-----------------------------------"
if command -v nginx &> /dev/null; then
    systemctl start nginx
    systemctl enable nginx
    systemctl status nginx --no-pager | head -5
else
    echo "错误: nginx未安装"
fi
echo

echo "步骤5: 验证端口监听"
echo "-----------------------------------"
echo "SSH (22):"
netstat -tlnp | grep :22 || echo "  未监听"
echo
echo "后端 (8000/8001):"
netstat -tlnp | grep -E ':(8000|8001)' || echo "  未监听"
echo
echo "前端 (8081):"
netstat -tlnp | grep :8081 || echo "  未监听"
echo

echo "步骤6: 测试服务"
echo "-----------------------------------"
echo "测试后端健康检查:"
curl -s -m 5 http://localhost:8000/health && echo " ✅ 后端正常" || echo " ❌ 后端异常"
echo
echo "测试前端服务:"
curl -s -m 5 -I http://localhost:8081 | head -1 && echo " ✅ 前端正常" || echo " ❌ 前端异常"
echo

echo "=========================================="
echo "  快速恢复完成"
echo "=========================================="
echo
echo "如果服务未正常启动，请检查:"
echo "  1. 后端日志: journalctl -u ai-resume-backend.service -n 50"
echo "  2. 前端日志: tail -50 /var/log/nginx/error.log"
echo "  3. 系统日志: journalctl -xe"
echo
echo "下一步: 从本地测试连接"
echo "  SSH: ssh -i ~/.ssh/id_ed25519 root@113.45.64.145"
echo "  后端: curl http://113.45.64.145:8001/health"
echo "  前端: curl -I http://113.45.64.145:8081"
echo