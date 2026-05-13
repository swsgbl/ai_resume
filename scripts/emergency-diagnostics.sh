#!/bin/bash
# 紧急故障诊断脚本 - 服务器恢复后立即执行
# 创建时间: 2026-05-14 01:20
# 用途: 系统恢复后的全面诊断和根因分析

set -e

echo "=========================================="
echo "  紧急故障诊断脚本 - 开始执行"
echo "  时间: $(date '+%Y-%m-%d %H:%M:%S')"
echo "=========================================="
echo

# 创建诊断日志文件
LOG_FILE="/tmp/emergency-diagnostics-$(date +%Y%m%d_%H%M%S).log"
exec > >(tee -a "$LOG_FILE") 2>&1

echo "诊断日志: $LOG_FILE"
echo

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 函数: 打印带颜色的状态
print_status() {
    local status=$1
    local message=$2
    case $status in
        "OK")
            echo -e "${GREEN}✓ $message${NC}"
            ;;
        "WARNING")
            echo -e "${YELLOW}⚠ $message${NC}"
            ;;
        "ERROR")
            echo -e "${RED}✗ $message${NC}"
            ;;
        *)
            echo "  $message"
            ;;
    esac
}

# 第1部分: 系统基本信息
echo "=========================================="
echo "1. 系统基本信息"
echo "=========================================="
echo
print_status "INFO" "主机名: $(hostname)"
print_status "INFO" "操作系统: $(cat /etc/os-release | grep PRETTY_NAME)"
print_status "INFO" "内核版本: $(uname -r)"
print_status "INFO" "运行时间: $(uptime -p 2>/dev/null || uptime)"
print_status "INFO" "当前时间: $(date)"
echo

# 第2部分: 系统资源状态
echo "=========================================="
echo "2. 系统资源状态"
echo "=========================================="
echo

# CPU使用率
CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}')
print_status "INFO" "CPU使用率: ${CPU_USAGE}%"
if (( $(echo "$CPU_USAGE > 80" | bc -l) )); then
    print_status "WARNING" "CPU使用率过高"
fi

# 内存使用
MEMORY_INFO=$(free | grep Mem)
MEMORY_TOTAL=$(echo $MEMORY_INFO | awk '{print $2}')
MEMORY_USED=$(echo $MEMORY_INFO | awk '{print $3}')
MEMORY_PERCENT=$(echo "scale=1; $MEMORY_USED * 100 / $MEMORY_TOTAL" | bc)
print_status "INFO" "内存使用: ${MEMORY_PERCENT}% ($((MEMORY_USED/1024))MB / $((MEMORY_TOTAL/1024))MB)"
if (( $(echo "$MEMORY_PERCENT > 85" | bc -l) )); then
    print_status "WARNING" "内存使用率过高"
fi

# 磁盘使用
echo
print_status "INFO" "磁盘使用情况:"
df -h | grep -E '(Filesystem|/dev/|/mnt/)' | while read line; do
    echo "  $line"
    USAGE=$(echo $line | awk '{print $5}' | sed 's/%//')
    if [ $USAGE -gt 90 ]; then
        print_status "ERROR" "磁盘使用率超过90%: $line"
    fi
done
echo

# 第3部分: 网络状态检查
echo "=========================================="
echo "3. 网络状态检查"
echo "=========================================="
echo

# 网络接口
print_status "INFO" "网络接口状态:"
ip addr show | grep -E '(^[0-9]+:|inet )' | while read line; do
    echo "  $line"
done
echo

# 端口监听
print_status "INFO" "重要端口监听状态:"
for PORT in 22 8001 8081 3000; do
    if netstat -tlnp 2>/dev/null | grep -q ":$PORT "; then
        print_status "OK" "端口 $PORT 正在监听"
        netstat -tlnp 2>/dev/null | grep ":$PORT " | head -1
    else
        print_status "ERROR" "端口 $PORT 未监听"
    fi
done
echo

# 第4部分: 服务状态检查
echo "=========================================="
echo "4. 服务状态检查"
echo "=========================================="
echo

# SSH服务
if systemctl is-active --quiet sshd 2>/dev/null || systemctl is-active --quiet ssh 2>/dev/null; then
    print_status "OK" "SSH服务运行正常"
    systemctl status sshd 2>/dev/null | head -3 || systemctl status ssh 2>/dev/null | head -3
else
    print_status "ERROR" "SSH服务未运行"
fi
echo

# 后端服务
if systemctl is-active --quiet ai-resume-backend.service; then
    print_status "OK" "后端服务(ai-resume-backend)运行正常"
    systemctl status ai-resume-backend.service --no-pager | head -5
else
    print_status "ERROR" "后端服务(ai-resume-backend)未运行"
    if systemctl list-unit-files | grep -q ai-resume-backend.service; then
        systemctl status ai-resume-backend.service --no-pager | head -5
    else
        print_status "WARNING" "后端服务未安装为systemd服务"
    fi
fi
echo

# 前端服务
if systemctl is-active --quiet nginx; then
    print_status "OK" "前端服务(nginx)运行正常"
    systemctl status nginx --no-pager | head -5
else
    print_status "ERROR" "前端服务(nginx)未运行"
    if systemctl list-unit-files | grep -q nginx.service; then
        systemctl status nginx --no-pager | head -5
    fi
fi
echo

# Docker服务
if systemctl is-active --quiet docker; then
    print_status "OK" "Docker服务运行正常"
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null || echo "  无法获取容器列表"
else
    print_status "WARNING" "Docker服务未运行"
    if systemctl list-unit-files | grep -q docker.service; then
        systemctl status docker --no-pager | head -5
    fi
fi
echo

# 第5部分: Docker容器状态
echo "=========================================="
echo "5. Docker容器状态"
echo "=========================================="
echo

if command -v docker &> /dev/null; then
    print_status "INFO" "所有容器状态:"
    docker ps -a --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null || echo "  无法获取容器状态"
    echo

    # 检查ai-resume相关容器
    AI_RESUME_CONTAINERS=$(docker ps -a --filter "name=ai-resume" --format "{{.Names}}" 2>/dev/null)
    if [ -n "$AI_RESUME_CONTAINERS" ]; then
        print_status "INFO" "AI Resume容器详情:"
        for container in $AI_RESUME_CONTAINERS; do
            echo "  容器: $container"
            docker inspect $container 2>/dev/null | grep -E '(Status|ExitCode|OOMKilled)' | head -5 || true
            echo
        done
    else
        print_status "WARNING" "未找到ai-resume相关容器"
    fi
else
    print_status "WARNING" "Docker命令不可用"
fi
echo

# 第6部分: 系统日志检查
echo "=========================================="
echo "6. 系统日志检查 (最近50行)"
echo "=========================================="
echo

if [ -f /var/log/messages ]; then
    print_status "INFO" "系统日志(/var/log/messages):"
    tail -50 /var/log/messages
elif [ -f /var/log/syslog ]; then
    print_status "INFO" "系统日志(/var/log/syslog):"
    tail -50 /var/log/syslog
else
    print_status "WARNING" "未找到系统日志文件"
fi
echo

# 第7部分: SSH日志检查
echo "=========================================="
echo "7. SSH登录日志 (最近20条)"
echo "=========================================="
echo

if [ -f /var/log/secure ]; then
    print_status "INFO" "SSH认证日志:"
    tail -20 /var/log/secure | grep -E '(Accepted|Failed|error)' || echo "  无相关日志"
elif [ -f /var/log/auth.log ]; then
    print_status "INFO" "SSH认证日志:"
    tail -20 /var/log/auth.log | grep -E '(Accepted|Failed|error)' || echo "  无相关日志"
else
    print_status "WARNING" "未找到SSH日志文件"
fi
echo

# 第8部分: Docker日志检查
echo "=========================================="
echo "8. Docker服务日志"
echo "=========================================="
echo

if systemctl list-unit-files | grep -q docker.service; then
    print_status "INFO" "Docker服务日志:"
    journalctl -u docker -n 30 --no-pager
else
    print_status "INFO" "Docker未安装为systemd服务"
fi
echo

# 第9部分: 应用日志检查
echo "=========================================="
echo "9. 应用日志检查"
echo "=========================================="
echo

AI_RESUME_LOGS="/var/www/ai-resume/logs"
if [ -d "$AI_RESUME_LOGS" ]; then
    print_status "INFO" "AI Resume应用日志:"
    find "$AI_RESUME_LOGS" -name "*.log" -type f -mtime -1 | while read log_file; do
        echo "  日志文件: $log_file"
        echo "  最后20行:"
        tail -20 "$log_file"
        echo
    done
else
    print_status "INFO" "未找到应用日志目录 ($AI_RESUME_LOGS)"
fi
echo

# 第10部分: 安全检查
echo "=========================================="
echo "10. 安全检查"
echo "=========================================="
echo

# 最近登录记录
print_status "INFO" "最近登录记录:"
last | head -10
echo

# 失败的登录尝试
print_status "INFO" "失败的登录尝试:"
if [ -f /var/log/btmp ]; then
    lastb | head -10 || echo "  无失败记录"
else
    echo "  无失败记录日志"
fi
echo

# 异常进程检查
print_status "INFO" "检查可疑进程:"
 Suspicious processes=$(ps aux | grep -E '(crypto|mine|xmr|monero)' | grep -v grep || true)
if [ -n "$Suspicious_processes" ]; then
    print_status "ERROR" "发现可疑进程:"
    echo "$Suspicious_processes"
else
    print_status "OK" "未发现可疑进程"
fi
echo

# 网络连接检查
print_status "INFO" "当前网络连接:"
ss -tulpn | grep LISTEN | head -20
echo

# 第11部分: 系统重启和崩溃检查
echo "=========================================="
echo "11. 系统重启和崩溃检查"
echo "=========================================="
echo

print_status "INFO" "最近重启记录:"
last reboot | head -10
echo

print_status "INFO" "内核消息检查:"
dmesg | tail -50
echo

print_status "INFO" "OOM Killer检查:"
if dmesg | grep -qi "out of memory"; then
    print_status "WARNING" "发现OOM Killer事件:"
    dmesg | grep -i "out of memory" | tail -10
else
    print_status "OK" "未发现OOM Killer事件"
fi
echo

# 第12部分: 防火墙和安全组
echo "=========================================="
echo "12. 防火墙配置"
echo "=========================================="
echo

if command -v firewall-cmd &> /dev/null; then
    print_status "INFO" "firewalld状态:"
    systemctl status firewalld --no-pager | head -5
    echo
    print_status "INFO" "防火墙规则:"
    firewall-cmd --list-all 2>/dev/null || echo "  无法获取规则"
elif command -v ufw &> /dev/null; then
    print_status "INFO" "UFW状态:"
    ufw status verbose
else
    print_status "INFO" "未检测到防火墙服务"
fi
echo

# 第13部分: 性能和历史数据
echo "=========================================="
echo "13. 性能数据"
echo "=========================================="
echo

if command -v sar &> /dev/null; then
    print_status "INFO" "CPU使用历史:"
    sar -u | tail -20 || echo "  无sar数据"
    echo

    print_status "INFO" "内存使用历史:"
    sar -r | tail -20 || echo "  无sar数据"
    echo

    print_status "INFO" "磁盘IO历史:"
    sar -d | tail -20 || echo "  无sar数据"
else
    print_status "INFO" "sysstat未安装，无法获取历史数据"
fi
echo

# 诊断总结
echo "=========================================="
echo "诊断总结"
echo "=========================================="
echo

# 统计问题
ERROR_COUNT=$(grep -c "ERROR" "$LOG_FILE" || true)
WARNING_COUNT=$(grep -c "WARNING" "$LOG_FILE" || true)

echo "发现的问题:"
echo "  错误: $ERROR_COUNT"
echo "  警告: $WARNING_COUNT"
echo

# 关键问题列表
if [ $ERROR_COUNT -gt 0 ]; then
    echo "关键错误问题:"
    grep "ERROR" "$LOG_FILE" | head -10
    echo
fi

if [ $WARNING_COUNT -gt 0 ]; then
    echo "警告问题:"
    grep "WARNING" "$LOG_FILE" | head -10
    echo
fi

# 推荐的立即行动
echo "推荐的立即行动:"
echo

# 检查SSH服务
if ! systemctl is-active --quiet sshd 2>/dev/null && ! systemctl is-active --quiet ssh 2>/dev/null; then
    echo "  1. 🔴 立即重启SSH服务: systemctl restart sshd"
fi

# 检查后端服务
if ! systemctl is-active --quiet ai-resume-backend.service; then
    echo "  2. 🔴 启动后端服务: systemctl start ai-resume-backend.service"
fi

# 检查前端服务
if ! systemctl is-active --quiet nginx; then
    echo "  3. 🔴 启动前端服务: systemctl start nginx"
fi

# 检查磁盘空间
DISK_USAGE=$(df -h / | awk 'NR==2 {print $5}' | sed 's/%//')
if [ $DISK_USAGE -gt 90 ]; then
    echo "  4. 🔴 磁盘空间不足，需要清理: df -h && docker system prune -f"
fi

# 检查内存
MEMORY_PERCENT=$(free | grep Mem | awk '{printf("%.1f"), $3/$2*100}')
if (( $(echo "$MEMORY_PERCENT > 90" | bc -l) )); then
    echo "  5. 🔴 内存使用率过高: ${MEMORY_PERCENT}%"
fi

echo
echo "=========================================="
echo "  诊断完成 - $(date '+%Y-%m-%d %H:%M:%S')"
echo "=========================================="
echo
echo "日志已保存到: $LOG_FILE"
echo
echo "下一步行动:"
echo "  1. 查看完整日志: cat $LOG_FILE"
echo "  2. 重启失败的服务"
echo "  3. 清理磁盘空间(如需要)"
echo "  4. 验证服务恢复: curl http://localhost:8001/health"
echo "  5. 更新故障报告: docs/DEVOPS-EMERGENCY-REPORT-20260514.md"
echo