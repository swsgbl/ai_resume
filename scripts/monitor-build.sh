#!/bin/bash
# Docker 构建监控脚本
# 定期检查构建进度，完成后自动验证

SERVER="root@113.45.64.145"
SSH_KEY="~/.ssh/id_ed25519"
LOG_FILE="/tmp/docker-compose-build.log"
TOTAL_PACKAGES=125

echo "========================================="
echo "Docker 构建监控脚本"
echo "开始时间: $(date '+%Y-%m-%d %H:%M:%S')"
echo "========================================="
echo

while true; do
    # 获取当前进度
    CURRENT_PACKAGE=$(ssh -i $SSH_KEY $SERVER "tail -1 $LOG_FILE 2>/dev/null | grep -oP 'Get:\\K\\d+' || echo 0")

    if [ "$CURRENT_PACKAGE" = "0" ]; then
        # 可能构建已完成或出错
        LOG_LINES=$(ssh -i $SSH_KEY $SERVER "wc -l $LOG_FILE 2>/dev/null | awk '{print \$1}' || echo 0")

        if [ "$LOG_LINES" -gt 200 ]; then
            echo "✅ 构建可能已完成（日志行数: $LOG_LINES）"
            break
        fi

        echo "⏳ 等待构建开始..."
        sleep 30
        continue
    fi

    # 计算进度百分比
    PROGRESS=$(echo "scale=1; $CURRENT_PACKAGE * 100 / $TOTAL_PACKAGES" | bc)
    echo "📦 进度: $CURRENT_PACKAGE/$TOTAL_PACKAGES ($PROGRESS%)"

    # 检查是否完成
    if [ "$CURRENT_PACKAGE" -ge "$TOTAL_PACKAGES" ]; then
        echo "✅ 包下载完成，等待镜像构建..."
        sleep 60
        break
    fi

    # 每分钟检查一次
    sleep 60
done

echo
echo "========================================="
echo "检查容器状态..."
echo "========================================="

# 等待容器启动
sleep 30

# 检查容器
CONTAINERS=$(ssh -i $SSH_KEY $SERVER "docker ps | grep ai-resume | wc -l")
echo "运行中的容器: $CONTAINERS"

if [ "$CONTAINERS" -ge 3 ]; then
    echo "✅ 所有容器已启动"
    echo
    echo "运行验证脚本..."
    /home/hongfu/ai-resume/scripts/verify-deployment.sh
else
    echo "⚠️  容器未完全启动，请检查日志"
    ssh -i $SSH_KEY $SERVER "tail -50 $LOG_FILE"
fi
